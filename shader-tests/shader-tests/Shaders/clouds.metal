//
//  clouds.metal
//  learning-scenekit
//
//  Created by Jim Martin on 6/14/18.
//  Copyright © 2018 Jim Martin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>

struct MyNodeBuffer {
    float4x4 modelTransform;
    float4x4 inverseModelTransform;
    float4x4 modelViewTransform;
    float4x4 inverseModelViewTransform;
    float4x4 normalTransform;
    float4x4 modelViewProjectionTransform;
    float4x4 inverseModelViewProjectionTransform;
    float2x3 boundingBox;
    float time;
    float random01;
};

typedef struct {
    float3 position [[ attribute(SCNVertexSemanticPosition) ]];
    float2 texCoords [[ attribute(SCNVertexSemanticTexcoord0) ]];
} MyVertexInput;

struct VertexBB
{
    float4 position [[position]];
    float4 fragmentModelCoordinates;
    float4 worldPosition;
    float4 cameraCoordinates;
    float4 cameraPosition;
    float2 texCoords;
    float time;
    float random01;
};

//vertex function
vertex VertexBB cloudVertex(MyVertexInput in [[ stage_in ]],
                             constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                             constant MyNodeBuffer& scn_node [[buffer(1)]])
{
    VertexBB vert;
    vert.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    vert.texCoords = in.texCoords;
    
    //define raymarching transforms in world space
    vert.fragmentModelCoordinates = float4(in.position, 1.0);
    vert.cameraCoordinates = scn_node.modelViewTransform * float4(in.position, 1.0);
    vert.worldPosition = float4(0,0,0, 1.0);
    vert.cameraPosition = scn_node.inverseModelViewTransform * float4(0,0,0, 1.0);
    
    //define animation parameters
    vert.time = scn_frame.time;
    vert.random01 = scn_frame.random01;
    return vert;
}

//global functions

struct Ray {
    float3 origin;
    float3 direction;
    Ray(float3 o, float3 d) {
        origin = o;
        direction = d;
    }
};

//find a ray's intersection point with a given plane
float3 IntersectionOnPlane( float3 offsetOrthogonalToPlane, float3 rayDirection, thread bool &oob)
{
    float dotToSurface = dot(normalize(offsetOrthogonalToPlane), rayDirection);
    if( dotToSurface <= 0.0)
    {
        oob = true;
        return float3(0);
    }
    oob = false;
    return rayDirection * length(offsetOrthogonalToPlane) / dotToSurface;
};

//Raymarching function per-pixel
float4 RaymarchClouds(Ray ray, float4 worldPosition, float time, texture2d<float, access::sample> noiseTexture, texture2d<float, access::sample> interferenceTexture, texture2d<float, access::sample> densityMap)
{
    float3 initialDirection = ray.direction;
    float3 initialPosition = ray.origin;
    float3 samplePosition = initialPosition;
    float distanceTravelled = float(0.0);
    
    //raymarching parameters
    float3 offset = initialDirection * 0.004; //base distance travelled during each step
    float maxdepth = 0.2; //max distance from camera a ray can reach
    float skipStep = 3.0;
    float stepNearSurface = 1.25;
    float tileScale = 1;
    
    //animation parameters
    float2 windDirection = normalize(float2(.5,.5));
    float3 baseColor = float3(.85,.8, .7);
    float opacityModifier = .2;

    //cloud bounds
    float cloudSizeVertical = 1;
    float cloudCenterBounds = worldPosition.y;
    float cloudUpperBounds = cloudCenterBounds + cloudSizeVertical/2;
    float cloudLowerBounds = cloudCenterBounds - cloudSizeVertical/2;
    
    //final pixel color from raymarching
    float4 outputColor = float4(0.0);
    
    //place initial sample on cloud bounds
    bool oob = false;
    if(samplePosition.y > cloudUpperBounds)
    {
        float3 offsetOrthoToBounds = float3(samplePosition.x, cloudUpperBounds, samplePosition.z) - samplePosition;
        float3 offsetToBounds = IntersectionOnPlane(offsetOrthoToBounds, initialDirection, oob);
        samplePosition += offsetToBounds;
    }
    if(samplePosition.y < cloudLowerBounds)
    {
        float3 offsetOrthoToBounds = float3(samplePosition.x, cloudLowerBounds, samplePosition.z) - samplePosition;
        float3 offsetToBounds = IntersectionOnPlane(offsetOrthoToBounds, initialDirection, oob);
        samplePosition += offsetToBounds;
    }
    if(oob)
    {
        return float4(0);
//        return float4(0,0,1,1);
    }
    
    //measure initial position from the sampleposition snapped to cloud boundaries
    initialPosition = samplePosition;
    
    // initialize offset before loop, in case we want to apply a default
    float3 newOffset = offset;
    
    for(int i = int(0); i < 30; i++)
    {
        
        if(samplePosition.y > cloudUpperBounds + 0.01)
        {
//            outputColor = float4(1, 0, 0, 1);
            break;
        }
        if(samplePosition.y < cloudLowerBounds - 0.01)
        {
//            outputColor = float4(0, 1, 0, 1);
            break;
        }
        
        //check distance travelled
        distanceTravelled = distance(samplePosition, initialPosition);
        if(distanceTravelled > maxdepth)
        {
//            outputColor = float4(1,1,0,1);
            break;
        }
        
        //get distance from cloud center
        float dist = (samplePosition.y - cloudCenterBounds) / cloudSizeVertical;
        //flatten cloud bottoms
        dist = mix(dist, dist/.2, saturate(-dist));
        float absDist = abs(dist);
        
        //sample texture in world-space
        float2 worldUV = (samplePosition.xz - worldPosition.xz) / tileScale;
        
        //cheap modulo here seems to be faster than feeding large uv positions to the sampler
        worldUV = worldUV - floor(worldUV);
        
        
        //animate the uv over time
        float2 baseAnimation = time * 0.01 * windDirection;
        float2 animUV = worldUV - baseAnimation;
        constexpr sampler animSampler(coord::normalized, filter::linear, address::repeat);
        float4 animSample = noiseTexture.sample(animSampler, animUV );
        
        //create a copy to interfere with the original sample, causing clouds to distort over time
        float2 interferenceAnimation = baseAnimation;
        interferenceAnimation.x *= -2;
        float2 interferenceUV = worldUV + float2(.5,.5) - (interferenceAnimation);
        constexpr sampler interferenceSampler(coord::normalized, filter::linear, address::repeat);
        float4 interferenceSample = interferenceTexture.sample(interferenceSampler, interferenceUV);
        
        //TODO modify the sample by some density value sampled from a separate texture
        float density = .2;
        
        //create final texture sample by mixing base, interference samples and density
        float4 textureSample = saturate(animSample - interferenceSample + density);
        
        
        //blend with previous samples if the sample alpha is high enough
        if( textureSample.a > absDist)
        {
            //process texture sample
//            textureSample = saturate(textureSample * (1.0 - floor(absDist)));
            float opacityGain = textureSample.a * opacityModifier;
            outputColor.a += opacityGain;
            
            float3 baseSampleColor = mix(1.0, dist * 0.5 + 0.5, baseColor) * opacityGain;
            outputColor.rgb += baseSampleColor;
            
        }
        
        newOffset = offset * (1.5 * skipStep) * stepNearSurface *( 1.0-textureSample.a );
        
        //change the sample position based on offset and distance travelled
        samplePosition += newOffset;
        
        //stop adding to color once alpha is fully opaque
        if(outputColor.a >= .7)
            break;
       
    };
    
    return outputColor;
};

// fragment shader
fragment half4 cloudFragment(VertexBB in [[stage_in]],
                            constant MyNodeBuffer& scn_node [[buffer(1)]],
                            texture2d<float, access::sample> debugTexture [[texture(0)]],
                            texture2d<float, access::sample> noiseTexture [[texture(1)]],
                            texture2d<float, access::sample> interferenceTexture [[texture(2)]],
                            texture2d<float, access:: sample> densityMap [[texture(3)]])
{
    
    //construct ray
    float3 rayDirection = normalize(float3( in.fragmentModelCoordinates.xyz - in.cameraPosition.xyz));
    float3 rayOrigin = in.fragmentModelCoordinates.xyz;
    
    //ray originates at the surface of the cloud volume, or the camera origin, whichever is closer to the center of the node
    //in-progress
//    if (distance(in.fragmentModelCoordinates.xyz, in.worldPosition.xyz) > distance(in.cameraPosition.xyz, in.worldPosition.xyz))
//    {
//        rayOrigin = in.cameraPosition.xyz;
//    }
    
    Ray ray = Ray(rayOrigin, rayDirection);
    
    //raymarch
    float4 output = RaymarchClouds(ray, in.worldPosition, in.time, noiseTexture, interferenceTexture, densityMap);
    return half4(output);
    
};
