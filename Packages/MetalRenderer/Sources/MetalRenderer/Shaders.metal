#include <metal_stdlib>
using namespace metal;

#include "ShaderTypes.h"

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float2 texCoord;
};

vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                              constant Vertex *vertices [[buffer(VertexInputIndexVertices)]],
                              constant Uniforms &uniforms [[buffer(VertexInputIndexUniforms)]]) {
    VertexOut out;
    out.position = uniforms.projectionMatrix * float4(vertices[vertexID].position, 0.0, 1.0);
    out.color = vertices[vertexID].color;
    out.texCoord = vertices[vertexID].texCoord;
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]]) {
    return in.color;
}
