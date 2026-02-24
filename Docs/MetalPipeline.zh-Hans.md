[English](MetalPipeline.md) | [简体中文](MetalPipeline.zh-Hans.md)

# Metal Rendering Pipeline

本文档介绍了项目中动作导向型游戏（如 Snake、Breakout）所使用的 Metal GPU 渲染架构。基于网格的游戏（如 Minesweeper、Memory Match）则使用 SpriteKit。

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

渲染流水线遵循清晰的分层结构：

```
Game Logic (Reducer)  // 游戏逻辑
       |
       v
  RenderCommand[]       (抽象绘制指令)
       |
       v
  RenderPipeline         (协议：Metal 或 SpriteKit)
       |
       v
  MetalContext           (Metal GPU 提交)
       |
       v
  GPU Frame             (GPU 帧)
```

游戏逻辑永远不会直接接触 Metal API。相反，Reducer 会生成 `RenderCommand` 值（定义在 `CoreEngine` 中），然后由 `MetalRenderer` 将这些指令转换为 Metal 绘制调用。

### RenderCommand Types

摘自 `CoreEngine/RenderCommand.swift`：

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

`MetalContext` 是 Metal 渲染系统的核心。它被实现为一个 Swift actor，以确保对 GPU 资源的线程安全访问。

### Architecture

```swift
actor MetalContext {
    // 核心 Metal 对象
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let library: MTLLibrary

    // 管线状态（每个着色器程序一个）
    private var flatColorPipeline: MTLRenderPipelineState
    private var texturePipeline: MTLRenderPipelineState
    private var circlePipeline: MTLRenderPipelineState

    // 三重缓冲的 Uniform 缓冲区
    private var uniformBuffers: [MTLBuffer]
    private var currentBufferIndex: Int = 0

    // 可绘制对象和深度状态
    private var depthStencilState: MTLDepthStencilState

    // 用于坐标映射的视口大小
    private var viewportSize: SIMD2<Float> = .zero
}
```

### Why an Actor?

- Metal 命令缓冲区（Command Buffer）必须按受控顺序创建和提交。
- GPU 资源（缓冲区、纹理）在 GPU 读取时不被写入。
- Swift actor 提供安全的序列化访问，无需手动加锁。
- Actor 模型与项目的异步架构（`StateStore`、`GameLoop`）无缝集成。

### Lifecycle

1. **初始化**：创建 `MTLDevice`、`MTLCommandQueue`，编译着色器，构建管线状态（Pipeline State）。
2. **每帧处理**：接收 `[RenderCommand]`，转换为 Metal 调用，提交命令缓冲区。
3. **调整大小**：更新视口，重新创建与大小相关的资源（深度缓冲区、投影矩阵）。
4. **销毁**：通过 ARC 自动完成 —— Metal 对象是引用计数的。

---

## Shader Architecture

该项目使用直接的着色器结构，为每个渲染图元提供顶点（Vertex）和片元（Fragment）函数对。

### Shader Files

```
MetalRenderer/Sources/MetalRenderer/Shaders/
├── ShaderTypes.h          # 共享类型定义 (Swift + Metal)
├── FlatColor.metal        # 纯色填充 (矩形, 线段)
├── Circle.metal           # 基于 SDF 的圆形渲染
├── Texture.metal          # 精灵/纹理渲染
└── Common.metal           # 共享工具函数
```

### Vertex Shaders

顶点着色器使用存储在 Uniform 缓冲区中的投影矩阵，将顶点从模型/世界空间转换到裁剪空间（Clip Space）。

```metal
vertex VertexOut flatColorVertex(
    uint vertexID [[vertex_id]],
    constant Vertex* vertices [[buffer(0)]],
    constant Uniforms& uniforms [[buffer(1)]]
) {
    VertexOut out;
    float2 position = vertices[vertexID].position;

    // 从像素坐标转换为裁剪空间
    float2 clipPosition = (position / uniforms.viewportSize) * 2.0 - 1.0;
    clipPosition.y = -clipPosition.y;  // 在 Metal 坐标系中翻转 Y 轴

    out.position = float4(clipPosition, 0.0, 1.0);
    out.color = vertices[vertexID].color;
    return out;
}
```

### Fragment Shaders

片元着色器输出最终的像素颜色。大多数是简单的透传；圆形着色器使用了有向距离函数（SDF）。

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

`ShaderTypes.h` 定义了 Metal 着色器和 Swift 代码共同使用的结构体。这确保了数据传递的类型安全，且无需序列化。

```cpp
#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

// 绑定顶点数据和 Uniform 的缓冲区索引
enum BufferIndex {
    BufferIndexVertices = 0,
    BufferIndexUniforms = 1
};

// 逐顶点数据
struct Vertex {
    simd_float2 position;
    simd_float4 color;
    simd_float2 texCoord;
};

// 逐帧 Uniform 数据
struct Uniforms {
    simd_float2 viewportSize;
    float time;
    float padding;  // 对齐到 16 字节
};

// 圆形专用顶点数据
struct CircleVertex {
    simd_float2 position;
    simd_float4 color;
    simd_float2 uv;        // 用于 SDF 计算的 0-1 UV
    float radius;
    float padding;
};

#endif
```

### Importing in Swift

由于这是一个包含在 Metal target 中的 C 头文件，同一模块中的 Swift 代码可以直接访问这些类型：

```swift
var vertex = Vertex()
vertex.position = SIMD2<Float>(100, 200)
vertex.color = SIMD4<Float>(1, 0, 0, 1)  // 红色
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
1. GameLoop tick (游戏循环计时)
        |
2. Reducer 产生 [RenderCommand]
        |
3. 调用 MetalContext.render(commands:)
        |
4. 将 RenderCommands 转换为顶点数组
        |
5. 上传顶点到 GPU 缓冲区
        |
6. 更新 Uniform 缓冲区 (视口, 时间)
        |
7. 遍历每个图元类型:
   a. 设置渲染管线状态
   b. 绑定顶点缓冲区
   c. 绑定 Uniform 缓冲区
   d. 绘制图元
        |
8. 提交命令缓冲区
        |
9. 显示可绘制对象 (Present drawable)
```

### Vertex Buffer Population

每个 `RenderCommand` 都会被转换为顶点：

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

    // ... 其他情况
    }
}
```

### Uniform Buffer Updates

Uniform 每帧更新一次：

```swift
var uniforms = Uniforms()
uniforms.viewportSize = viewportSize
uniforms.time = Float(CACurrentMediaTime())
// 拷贝到当前三重缓冲槽位
memcpy(uniformBuffers[currentBufferIndex].contents(), &uniforms,
       MemoryLayout<Uniforms>.size)
```

---

## Render Command to Metal Translation

`MetalContext` 按类型对渲染命令进行分组，以实现高效的管线状态切换：

```swift
func render(commands: [RenderCommand]) async {
    guard let drawable = metalLayer.nextDrawable(),
          let commandBuffer = commandQueue.makeCommandBuffer() else { return }

    let renderPassDescriptor = MTLRenderPassDescriptor()
    // 如果存在 .clear 命令，则根据其配置

    guard let encoder = commandBuffer.makeRenderCommandEncoder(
        descriptor: renderPassDescriptor
    ) else { return }

    // 分组命令以减少管线状态切换
    let rectCommands = commands.filter { /* 为 fillRect */ }
    let circleCommands = commands.filter { /* 为 fillCircle */ }
    let lineCommands = commands.filter { /* 为 drawLine */ }
    let spriteCommands = commands.filter { /* 为 drawSprite */ }

    // 使用纯色管线绘制所有矩形
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

    // 使用圆形管线绘制所有圆形
    if !circleCommands.isEmpty {
        encoder.setRenderPipelineState(circlePipeline)
        // ... 类似模式
    }

    encoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()

    // 推进三重缓冲索引
    currentBufferIndex = (currentBufferIndex + 1) % 3
}
```

---

## How to Add New Shader Passes

### Step 1: Define types in ShaderTypes.h

添加任何新的顶点或 Uniform 结构体：

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

创建一个新的 `.metal` 文件：

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
    // 转换坐标...
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

    // 为发光效果启用混合
    descriptor.colorAttachments[0].isBlendingEnabled = true
    descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
    descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
    descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
    descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

    return try device.makeRenderPipelineState(descriptor: descriptor)
}
```

### Step 4: Add a new RenderCommand case (if needed)

如果新着色器需要新的图元类型，请在 `CoreEngine` 的 `RenderCommand` 中添加一个 case：

```swift
case drawGlow(centerX: Float, centerY: Float, radius: Float,
              r: Float, g: Float, b: Float, a: Float,
              glowRadius: Float, intensity: Float)
```

### Step 5: Handle in the render loop

在 `MetalContext` 的 `render(commands:)` 方法中处理新的命令类型。

---

## Performance Tips

### Triple Buffering

管线使用三个 Uniform 缓冲区来避免 GPU/CPU 竞争：

```swift
// 帧 N: GPU 读取缓冲区 0
// 帧 N+1: CPU 写入缓冲区 1, GPU 读取缓冲区 0
// 帧 N+2: CPU 写入缓冲区 2, GPU 读取缓冲区 1

private let maxFramesInFlight = 3
private var uniformBuffers: [MTLBuffer]  // 3个缓冲区的数组
private var currentBufferIndex = 0
private let frameSemaphore = DispatchSemaphore(value: 3)
```

这确保了当 GPU 仍在渲染当前帧时，CPU 已经可以准备下一帧。

### Batch Draw Calls

将相同类型的图元分组，以尽量减少管线状态切换：

```
较差:  setRect -> draw -> setCircle -> draw -> setRect -> draw  (3 次状态切换)
良好:  setRect -> draw(allRects) -> setCircle -> draw(allCircles)  (1 次状态切换)
```

`MetalContext` 会自动按类型对命令进行分组。

### Use setVertexBytes for Small Data

对于 4KB 以下的顶点数据，使用 `setVertexBytes` 而不是创建缓冲区：

```swift
// 适用于小数据 (< 4KB)
encoder.setVertexBytes(vertices, length: size, index: 0)

// 适用于大数据 (> 4KB) —— 在多帧间复用该缓冲区
encoder.setVertexBuffer(largeVertexBuffer, offset: 0, index: 0)
```

### Minimize Texture Switches

如果使用精灵，请按纹理对绘制调用进行排序，以减少纹理绑定更改。

### Avoid Per-Frame Allocations

预分配顶点数组并在每帧复用它们。避免从头开始创建新的 `[Vertex]` 数组：

```swift
// 预分配，每帧复用
private var vertexScratchBuffer: [Vertex] = []

func buildFrame(commands: [RenderCommand]) {
    vertexScratchBuffer.removeAll(keepingCapacity: true)
    for command in commands {
        vertexScratchBuffer.append(contentsOf: buildVertices(for: command))
    }
}
```

### Profile with Metal System Trace

使用 Instruments > Metal System Trace 来识别：
- GPU 空闲时间（CPU 瓶颈）
- CPU 空闲时间（GPU 瓶颈）
- 过多的状态切换
- 缓冲区分配停顿

---

## Debugging Metal Shaders

### GPU Frame Capture

1. 在 Xcode 运行期间，点击调试栏中的相机图标。
2. 检查单个绘制调用、顶点数据和着色器输出。
3. 使用 Shader Debugger 逐行调试着色器。

### Metal Validation Layer

在 Xcode scheme 中启用 Metal 验证层：
- Edit Scheme > Run > Diagnostics > GPU > Metal Validation

这可以捕获：
- 无效的缓冲区绑定
- 不匹配的管线状态配置
- 越界的缓冲区访问

### Metal API Validation

如需进行更深入的分析，请启用 Metal API Validation：
- Edit Scheme > Run > Options > GPU Frame Capture: Metal

### Shader Compilation Errors

Metal 着色器编译错误会在构建时出现。常见问题包括：
- 缺少 `#include "ShaderTypes.h"` —— 找不到类型
- 顶点和片元着色器之间的函数签名不匹配
- 错误的 `[[buffer(N)]]` 特性索引

### Printf Debugging in Shaders

Metal 不支持在着色器中使用 `printf`。替代方案：
- 将调试值写入输出颜色：`return float4(debugValue, 0, 0, 1);`
- 使用 Metal Frame Capture 检查中间值
- 写入调试缓冲区并在 CPU 上读回
