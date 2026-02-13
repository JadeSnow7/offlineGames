# Metal Rendering Pipeline

This document covers the Metal GPU rendering architecture used by action-oriented games (Snake, Breakout) in the project. Grid-based games (Minesweeper, Memory Match) use SpriteKit instead.

---

## Table of Contents

1. [Overview](#overview)
2. [MetalContext Actor Design](#metalcontext-actor-design)
3. [Shader Architecture](#shader-architecture)
4. [ShaderTypes.h: Shared Between Metal and Swift](#shadertypesh-shared-between-metal-and-swift)
5. [Vertex and Uniform Data Flow](#vertex-and-uniform-data-flow)
6. [Render Command to Metal Translation](#render-command-to-metal-translation)
7. [How to Add New Shader Passes](#how-to-add-new-shader-passes)
8. [Performance Tips](#performance-tips)
9. [Debugging Metal Shaders](#debugging-metal-shaders)

---

## Overview

The rendering pipeline follows a clear separation:

```
Game Logic (Reducer)
       |
       v
  RenderCommand[]       (abstract drawing instructions)
       |
       v
  RenderPipeline         (protocol: Metal or SpriteKit)
       |
       v
  MetalContext           (Metal GPU submission)
       |
       v
  GPU Frame
```

Game logic never touches Metal APIs directly. Instead, reducers produce `RenderCommand` values (defined in `CoreEngine`), and the `MetalRenderer` translates these into Metal draw calls.

### RenderCommand Types

From `CoreEngine/RenderCommand.swift`:

```swift
public enum RenderCommand: Sendable {
    case clear(r: Float, g: Float, b: Float, a: Float)
    case fillRect(x: Float, y: Float, width: Float, height: Float,
                  r: Float, g: Float, b: Float, a: Float)
    case fillCircle(centerX: Float, centerY: Float, radius: Float,
                    r: Float, g: Float, b: Float, a: Float)
    case drawLine(x1: Float, y1: Float, x2: Float, y2: Float,
                  r: Float, g: Float, b: Float, a: Float, lineWidth: Float)
    case drawSprite(name: String, x: Float, y: Float, width: Float, height: Float)
    case drawText(text: String, x: Float, y: Float, size: Float,
                  r: Float, g: Float, b: Float, a: Float)
}
```

### RenderPipeline Protocol

```swift
public protocol RenderPipeline: Sendable {
    func render(commands: [RenderCommand]) async
    func resize(width: Float, height: Float) async
}
```

---

## MetalContext Actor Design

The `MetalContext` is the heart of the Metal rendering system. It is implemented as a Swift actor to ensure thread-safe access to GPU resources.

### Architecture

```swift
actor MetalContext {
    // Core Metal objects
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let library: MTLLibrary

    // Pipeline states (one per shader program)
    private var flatColorPipeline: MTLRenderPipelineState
    private var texturePipeline: MTLRenderPipelineState
    private var circlePipeline: MTLRenderPipelineState

    // Triple-buffered uniform buffers
    private var uniformBuffers: [MTLBuffer]
    private var currentBufferIndex: Int = 0

    // Drawable and depth state
    private var depthStencilState: MTLDepthStencilState

    // Viewport size for coordinate mapping
    private var viewportSize: SIMD2<Float> = .zero
}
```

### Why an Actor?

- Metal command buffers must be created and committed in a controlled sequence.
- GPU resources (buffers, textures) must not be written to while the GPU reads them.
- Swift actors provide safe, serialized access without manual locking.
- The actor model integrates cleanly with the project's async architecture (`StateStore`, `GameLoop`).

### Lifecycle

1. **Initialization**: Create `MTLDevice`, `MTLCommandQueue`, compile shaders, build pipeline states.
2. **Per Frame**: Receive `[RenderCommand]`, translate to Metal calls, submit command buffer.
3. **Resize**: Update viewport, recreate size-dependent resources (depth buffer, projection matrix).
4. **Teardown**: Automatic via ARC -- Metal objects are reference-counted.

---

## Shader Architecture

The project uses a straightforward shader structure with vertex and fragment function pairs for each rendering primitive.

### Shader Files

```
MetalRenderer/Sources/MetalRenderer/Shaders/
├── ShaderTypes.h          # Shared type definitions (Swift + Metal)
├── FlatColor.metal        # Solid color fill (rects, lines)
├── Circle.metal           # SDF-based circle rendering
├── Texture.metal          # Sprite/texture rendering
└── Common.metal           # Shared utility functions
```

### Vertex Shaders

Vertex shaders transform vertices from model/world space to clip space using a projection matrix stored in the uniform buffer.

```metal
vertex VertexOut flatColorVertex(
    uint vertexID [[vertex_id]],
    constant Vertex* vertices [[buffer(0)]],
    constant Uniforms& uniforms [[buffer(1)]]
) {
    VertexOut out;
    float2 position = vertices[vertexID].position;

    // Transform from pixel coordinates to clip space
    float2 clipPosition = (position / uniforms.viewportSize) * 2.0 - 1.0;
    clipPosition.y = -clipPosition.y;  // Flip Y for Metal's coordinate system

    out.position = float4(clipPosition, 0.0, 1.0);
    out.color = vertices[vertexID].color;
    return out;
}
```

### Fragment Shaders

Fragment shaders output the final pixel color. Most are simple pass-throughs; the circle shader uses a signed distance function.

```metal
fragment float4 flatColorFragment(VertexOut in [[stage_in]]) {
    return in.color;
}

fragment float4 circleFragment(CircleVertexOut in [[stage_in]]) {
    float dist = length(in.uv - float2(0.5));
    float alpha = 1.0 - smoothstep(0.48, 0.50, dist);
    return float4(in.color.rgb, in.color.a * alpha);
}
```

---

## ShaderTypes.h: Shared Between Metal and Swift

`ShaderTypes.h` defines structures that are used by both Metal shaders and Swift code. This ensures type-safe data passing without serialization.

```cpp
#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

// Buffer indices for binding vertex data and uniforms
enum BufferIndex {
    BufferIndexVertices = 0,
    BufferIndexUniforms = 1
};

// Per-vertex data
struct Vertex {
    simd_float2 position;
    simd_float4 color;
    simd_float2 texCoord;
};

// Per-frame uniform data
struct Uniforms {
    simd_float2 viewportSize;
    float time;
    float padding;  // Align to 16 bytes
};

// Circle-specific vertex data
struct CircleVertex {
    simd_float2 position;
    simd_float4 color;
    simd_float2 uv;        // 0-1 UV for SDF evaluation
    float radius;
    float padding;
};

#endif
```

### Importing in Swift

Because this is a C header included in the Metal target, Swift code in the same module can access these types directly:

```swift
var vertex = Vertex()
vertex.position = SIMD2<Float>(100, 200)
vertex.color = SIMD4<Float>(1, 0, 0, 1)  // Red
vertex.texCoord = SIMD2<Float>(0, 0)
```

### Importing in Metal Shaders

```metal
#include "ShaderTypes.h"

vertex VertexOut myShader(uint vid [[vertex_id]],
                          constant Vertex* verts [[buffer(BufferIndexVertices)]],
                          constant Uniforms& uniforms [[buffer(BufferIndexUniforms)]]) {
    // ...
}
```

---

## Vertex and Uniform Data Flow

### Per-Frame Flow

```
1. GameLoop tick
        |
2. Reducer produces [RenderCommand]
        |
3. MetalContext.render(commands:) called
        |
4. Translate RenderCommands into vertex arrays
        |
5. Upload vertices to GPU buffer
        |
6. Update uniform buffer (viewport, time)
        |
7. For each primitive type:
   a. Set render pipeline state
   b. Bind vertex buffer
   c. Bind uniform buffer
   d. Draw primitives
        |
8. Commit command buffer
        |
9. Present drawable
```

### Vertex Buffer Population

Each `RenderCommand` is translated into vertices:

```swift
func buildVertices(for command: RenderCommand) -> [Vertex] {
    switch command {
    case .fillRect(let x, let y, let w, let h, let r, let g, let b, let a):
        let color = SIMD4<Float>(r, g, b, a)
        return [
            Vertex(position: SIMD2(x, y),         color: color, texCoord: .zero),
            Vertex(position: SIMD2(x + w, y),     color: color, texCoord: .zero),
            Vertex(position: SIMD2(x, y + h),     color: color, texCoord: .zero),
            Vertex(position: SIMD2(x + w, y),     color: color, texCoord: .zero),
            Vertex(position: SIMD2(x + w, y + h), color: color, texCoord: .zero),
            Vertex(position: SIMD2(x, y + h),     color: color, texCoord: .zero),
        ]

    // ... other cases
    }
}
```

### Uniform Buffer Updates

Uniforms are updated once per frame:

```swift
var uniforms = Uniforms()
uniforms.viewportSize = viewportSize
uniforms.time = Float(CACurrentMediaTime())
// Copy to the current triple-buffer slot
memcpy(uniformBuffers[currentBufferIndex].contents(), &uniforms,
       MemoryLayout<Uniforms>.size)
```

---

## Render Command to Metal Translation

The `MetalContext` groups render commands by type for efficient pipeline state switching:

```swift
func render(commands: [RenderCommand]) async {
    guard let drawable = metalLayer.nextDrawable(),
          let commandBuffer = commandQueue.makeCommandBuffer() else { return }

    let renderPassDescriptor = MTLRenderPassDescriptor()
    // Configure based on .clear command if present

    guard let encoder = commandBuffer.makeRenderCommandEncoder(
        descriptor: renderPassDescriptor
    ) else { return }

    // Group commands to minimize pipeline state switches
    let rectCommands = commands.filter { /* is fillRect */ }
    let circleCommands = commands.filter { /* is fillCircle */ }
    let lineCommands = commands.filter { /* is drawLine */ }
    let spriteCommands = commands.filter { /* is drawSprite */ }

    // Draw all rects with flat color pipeline
    if !rectCommands.isEmpty {
        encoder.setRenderPipelineState(flatColorPipeline)
        let vertices = rectCommands.flatMap { buildVertices(for: $0) }
        encoder.setVertexBytes(vertices, length: MemoryLayout<Vertex>.stride * vertices.count,
                              index: BufferIndex.BufferIndexVertices.rawValue)
        encoder.setVertexBuffer(uniformBuffers[currentBufferIndex], offset: 0,
                              index: BufferIndex.BufferIndexUniforms.rawValue)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0,
                              vertexCount: vertices.count)
    }

    // Draw all circles with circle pipeline
    if !circleCommands.isEmpty {
        encoder.setRenderPipelineState(circlePipeline)
        // ... similar pattern
    }

    encoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()

    // Advance triple buffer index
    currentBufferIndex = (currentBufferIndex + 1) % 3
}
```

---

## How to Add New Shader Passes

### Step 1: Define types in ShaderTypes.h

Add any new vertex or uniform structures:

```cpp
struct GlowVertex {
    simd_float2 position;
    simd_float4 color;
    float glowRadius;
    float glowIntensity;
    simd_float2 padding;
};
```

### Step 2: Write the Metal shader

Create a new `.metal` file:

```metal
// Glow.metal
#include "ShaderTypes.h"

struct GlowVertexOut {
    float4 position [[position]];
    float4 color;
    float2 uv;
    float glowRadius;
    float glowIntensity;
};

vertex GlowVertexOut glowVertex(
    uint vid [[vertex_id]],
    constant GlowVertex* vertices [[buffer(0)]],
    constant Uniforms& uniforms [[buffer(1)]]
) {
    GlowVertexOut out;
    // Transform position...
    out.color = vertices[vid].color;
    out.glowRadius = vertices[vid].glowRadius;
    out.glowIntensity = vertices[vid].glowIntensity;
    return out;
}

fragment float4 glowFragment(GlowVertexOut in [[stage_in]]) {
    float dist = length(in.uv - float2(0.5));
    float glow = exp(-dist * dist / (in.glowRadius * in.glowRadius));
    return float4(in.color.rgb * glow * in.glowIntensity, in.color.a * glow);
}
```

### Step 3: Create the pipeline state in MetalContext

```swift
private func makeGlowPipeline() throws -> MTLRenderPipelineState {
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.vertexFunction = library.makeFunction(name: "glowVertex")
    descriptor.fragmentFunction = library.makeFunction(name: "glowFragment")
    descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

    // Enable blending for glow effect
    descriptor.colorAttachments[0].isBlendingEnabled = true
    descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
    descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
    descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
    descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

    return try device.makeRenderPipelineState(descriptor: descriptor)
}
```

### Step 4: Add a new RenderCommand case (if needed)

If the new shader needs a new primitive type, add a case to `RenderCommand` in `CoreEngine`:

```swift
case drawGlow(centerX: Float, centerY: Float, radius: Float,
              r: Float, g: Float, b: Float, a: Float,
              glowRadius: Float, intensity: Float)
```

### Step 5: Handle in the render loop

Add the new command type to the `render(commands:)` method in `MetalContext`.

---

## Performance Tips

### Triple Buffering

The pipeline uses three uniform buffers to avoid GPU/CPU contention:

```swift
// Frame N: GPU reads buffer 0
// Frame N+1: CPU writes buffer 1, GPU reads buffer 0
// Frame N+2: CPU writes buffer 2, GPU reads buffer 1

private let maxFramesInFlight = 3
private var uniformBuffers: [MTLBuffer]  // Array of 3 buffers
private var currentBufferIndex = 0
private let frameSemaphore = DispatchSemaphore(value: 3)
```

This ensures the CPU can prepare the next frame while the GPU is still rendering the current one.

### Batch Draw Calls

Group primitives of the same type to minimize pipeline state switches:

```
Bad:  setRect -> draw -> setCircle -> draw -> setRect -> draw  (3 state switches)
Good: setRect -> draw(allRects) -> setCircle -> draw(allCircles)  (1 state switch)
```

The `MetalContext` automatically groups commands by type.

### Use setVertexBytes for Small Data

For vertex data under 4KB, use `setVertexBytes` instead of creating a buffer:

```swift
// Good for small data (< 4KB)
encoder.setVertexBytes(vertices, length: size, index: 0)

// Better for large data (> 4KB) -- reuse the buffer across frames
encoder.setVertexBuffer(largeVertexBuffer, offset: 0, index: 0)
```

### Minimize Texture Switches

If using sprites, sort draw calls by texture to minimize texture binding changes.

### Avoid Per-Frame Allocations

Pre-allocate vertex arrays and reuse them each frame. Avoid creating new `[Vertex]` arrays from scratch:

```swift
// Pre-allocated, reused each frame
private var vertexScratchBuffer: [Vertex] = []

func buildFrame(commands: [RenderCommand]) {
    vertexScratchBuffer.removeAll(keepingCapacity: true)
    for command in commands {
        vertexScratchBuffer.append(contentsOf: buildVertices(for: command))
    }
}
```

### Profile with Metal System Trace

Use Instruments > Metal System Trace to identify:
- GPU idle time (CPU bottleneck)
- CPU idle time (GPU bottleneck)
- Excessive state switches
- Buffer allocation stalls

---

## Debugging Metal Shaders

### GPU Frame Capture

1. In Xcode, click the camera icon in the debug bar during a running session.
2. Inspect individual draw calls, vertex data, and shader outputs.
3. Step through shaders line-by-line with the Shader Debugger.

### Metal Validation Layer

Enable the Metal validation layer in the Xcode scheme:
- Edit Scheme > Run > Diagnostics > GPU > Metal Validation

This catches:
- Invalid buffer bindings
- Mismatched pipeline state configurations
- Out-of-bounds buffer access

### Metal API Validation

For deeper analysis, enable Metal API Validation:
- Edit Scheme > Run > Options > GPU Frame Capture: Metal

### Shader Compilation Errors

Metal shader compilation errors appear at build time. Common issues:
- Missing `#include "ShaderTypes.h"` -- types not found
- Mismatched function signatures between vertex and fragment shaders
- Incorrect `[[buffer(N)]]` attribute indices

### Printf Debugging in Shaders

Metal does not support `printf` in shaders. Instead:
- Write debug values to the output color: `return float4(debugValue, 0, 0, 1);`
- Use Metal Frame Capture to inspect intermediate values
- Write to a debug buffer and read it back on the CPU
