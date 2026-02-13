#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

/// Vertex data passed to Metal shaders.
typedef struct {
    simd_float2 position;
    simd_float4 color;
    simd_float2 texCoord;
} Vertex;

/// Per-frame uniforms.
typedef struct {
    simd_float4x4 projectionMatrix;
    simd_float2 viewportSize;
    float time;
} Uniforms;

/// Vertex buffer index constants.
typedef enum {
    VertexInputIndexVertices = 0,
    VertexInputIndexUniforms = 1
} VertexInputIndex;

#endif
