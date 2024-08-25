#ifndef CHARACTER_OUTLINEPASS_INCLUDED
#define CHARACTER_OUTLINEPASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

#include "./CharacterInput.hlsl"

struct Attributes 
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float4 vertexColor : COLOR;
    float2 uv : TEXCOORD0;
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float3 vertexColor : COLOR;
    float2 uv : TEXCOORD0;
};

Varyings vert(Attributes input) 
{
    Varyings output;

    VertexPositionInputs positionInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    output.positionCS = positionInput.positionCS;
    output.vertexColor = input.vertexColor;
    output.uv = input.uv;

    float4 scaledScreenParams = GetScaledScreenParams();
    float scaleX = abs(scaledScreenParams.x / scaledScreenParams.y);
    float clampW = clamp(1 / output.positionCS.w, 0.5, 1); 

    float3 normalCS = TransformWorldToHClipDir(normalInput.tangentWS);
    output.positionCS.xy = output.positionCS.xy + normalCS.xy * _OutlineWidth * clampW / scaleX * input.vertexColor.r;

    return output;
}

float4 frag(Varyings input) : SV_TARGET 
{
    half outlineMask = SAMPLE_TEXTURE2D(_OutlineMask, sampler_OutlineMask, input.uv).r;
    if (outlineMask < 0.5) discard;
    return _OutlineColor;
}

#endif