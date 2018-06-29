//
//  volume-slice.metal
//  shader-tests
//
//  Created by Jim Martin on 6/29/18.
//  Copyright © 2018 Jim Martin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>


struct NodeBuffer {
    float4x4 modelTransform;
    float4x4 inverseModelTransform;
    float4x4 modelViewTransform;
    float4x4 inverseModelViewTransform;
    float4x4 normalTransform;
    float4x4 modelViewProjectionTransform;
    float4x4 inverseModelViewProjectionTransform;
    float2x3 boundingBox;
};

typedef struct {
    float3 position [[ attribute(SCNVertexSemanticPosition) ]];
    float2 texCoords [[ attribute(SCNVertexSemanticTexcoord0) ]];
} VertexInput;

struct Vertex
{
    float4 position [[position]];
    float4 fragmentModelCoordinates;
    float4 modelOrigin;
    float4 fragemntViewCoordinates;
    float4 cameraModelCoordinates;
    float2 texCoords;
};

//vertex function
vertex Vertex sliceVertex(VertexInput in [[ stage_in ]],
                            constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                            constant NodeBuffer& scn_node [[buffer(1)]])
{
    //basic vertex
    Vertex vert;
    vert.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    vert.texCoords = in.texCoords;
    
    //define transforms in model(node) space
    vert.fragmentModelCoordinates = float4(in.position, 1.0);                                   //the position of the fragment in model space
    vert.fragemntViewCoordinates = scn_node.modelViewTransform * float4(in.position, 1.0);      //the position of the fragment in view(camera) space
    vert.modelOrigin = float4(0,0,0, 1.0);                                                      //the center of the model (zero in model space)
    vert.cameraModelCoordinates = scn_node.inverseModelViewTransform * float4(0,0,0, 1.0);      //the position of the camera in model space
    
    return vert;
}


fragment half4 sliceFragment(Vertex in [[stage_in]],
                          texture2d<float, access::sample> diffuseTexture [[texture(0)]])
{
    constexpr sampler sampler2d(coord::normalized, filter::linear, address::repeat);
    float4 color = diffuseTexture.sample(sampler2d, in.texCoords);
    return half4(color);
}
