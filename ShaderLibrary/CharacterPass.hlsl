#ifndef CHARACTER_PASS_INCLUDED
#define CHARACTER_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

#include "./CharacterInput.hlsl"
#include "./CharacterMacro.hlsl"

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
    float3 positionWS : TEXCOORD0;
    float3 positionVS : TEXCOORD1;
    float4 positionNDC : TEXCOORD2;
    float3 normalWS : TEXCOORD3;
    float3 tangentWS : TEXCOORD4;
    float3 bitangentWS : TEXCOORD5;
    float4 vertexClor : COLOR;
    float2 uv : TEXCOORD6;
};

Varyings vert(Attributes input)
{
    Varyings output;

    VertexPositionInputs positionInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    output.positionCS = positionInput.positionCS;
    output.positionWS = positionInput.positionWS;
    output.positionVS = positionInput.positionVS;
    output.positionNDC = positionInput.positionNDC;
    output.normalWS = normalInput.normalWS;
    output.tangentWS = normalInput.tangentWS;
    output.bitangentWS = normalInput.bitangentWS;
    output.vertexClor = input.vertexColor;
    output.uv = input.uv;

    // Bake
    // float2 remappedUV = input.uv.xy * 2 - 1;
    // float4 outputPos = float4(remappedUV.x, remappedUV.y, 0, 1);
    // output.positionCS = outputPos;
    // output.positionWS = mul(unity_ObjectToWorld, outputPos);

    return output;
}

float4 frag(Varyings input) : SV_TARGET
{
    // Debug
    half debug = SAMPLE_TEXTURE2D(_DebugTex, sampler_DebugTex, input.uv).r;

    // Diffuse
    half4 diffuse = SAMPLE_TEXTURE2D(_DiffuseTex, sampler_DiffuseTex, input.uv) * _DiffuseColor;

    // Normal
    float3 bump = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, input.uv), _NormalIntensity);
    float3x3 tangent = float3x3(input.tangentWS, input.bitangentWS, input.normalWS);
    float3 normalWS = TransformTangentToWorld(bump, tangent, true);

    // View
    float3 viewWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
    
    // AO
    half aoMask = SAMPLE_TEXTURE2D(_AOMask, sampler_AOMask, input.uv).r;
    float ao = saturate(pow(aoMask, _AOIntensity));

    // Shadow
    half4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
    half shadowMask = SAMPLE_TEXTURE2D(_ShadowMask, sampler_ShadowMask, input.uv).r;

    // Main Light
    Light mainLight = GetMainLight(shadowCoord);
    float mainLightHalfLambert = (0.5 * dot(normalWS, normalize(mainLight.direction)) + 0.5);
    float mainLightShadow = smoothstep(_ShadowRange * shadowMask - _ShadowSmooth, _ShadowRange * shadowMask + _ShadowSmooth, mainLightHalfLambert);
    half3 mainLightAttenuation = mainLightShadow * mainLight.shadowAttenuation * ao;

    // Additional Light
    half3 additionalLightColor = half3(0, 0, 0);
    float additionalLightAttenuation = 0.0;
    InputData inputData = (InputData) 0;
    inputData.positionWS = input.positionWS;
    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS.xy);
    #ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    LIGHT_LOOP_BEGIN(pixelLightCount)
    Light additionalLight = GetAdditionalLight(lightIndex, input.positionWS, shadowMask);
    additionalLightColor += additionalLight.color * additionalLight.distanceAttenuation;
    additionalLightAttenuation += additionalLight.shadowAttenuation * additionalLight.distanceAttenuation * ao;
    LIGHT_LOOP_END
    #endif

    // Mix Light
    float mixAttenuation = saturate((length(mainLight.color) * mainLightAttenuation) + (length(additionalLightColor.rgb) * additionalLightAttenuation) + (1 - shadowMask));
    half3 mixAttenuationColor = (1 - mixAttenuation) * _ShadowColor;
    half3 mixLight = mainLight.color + clamp(additionalLightColor, 0.0, 0.5);
    half3 mixLightLength = length(mixLight.rgb);
    half3 mixLightColor = mixLight * saturate(mixAttenuation + mixAttenuationColor);

    // Ramp
    half3 ramp = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(mainLightShadow, 0.5));

    // SDF
    half sdf = SAMPLE_TEXTURE2D(_ShadowTex, sampler_ShadowTex, input.uv).r;
    float2 rightVector = normalize(float3(1.0, 0.0, 0.0).xz);
    float2 frontVector = normalize(float3(0.0, 0.0, 1.0).xz);
    float2 lightVector = normalize(mainLight.direction.xz);
    float threshold = dot(frontVector, lightVector) * 0.5 + 0.5;
    float sdf_direction = dot(rightVector, lightVector) > 0.0 ? sdf : 1 - sdf;
    float sdf_range = smoothstep(threshold + _ShadowSmooth, threshold - _ShadowSmooth, sdf_direction) * shadowMask;

    // BlinnPhong
    float3 halfVector = normalize(mainLight.direction + viewWS);
    float blinnPhong = saturate(dot(normalWS, halfVector));

    // Specular
    float3 normalVS = TransformWorldToViewNormal(normalWS, true);
    half matCap = SAMPLE_TEXTURE2D(_MatcapTex, sampler_MatcapTex, 0.5 * normalVS.xy + 0.5);
    half specularMask = SAMPLE_TEXTURE2D(_SpecularMask, sampler_SpecularMask, input.uv).r;
    float metalRange = step(0.9, specularMask);
    float nonMetalRange = (step(0.1, specularMask) - step(0.9, specularMask));
    float metal = blinnPhong * matCap * metalRange * _MetalIntensity;
    float nonMetal = pow(blinnPhong, _nonMetalSmooth) * nonMetalRange * _nonMetalIntensity;
    float specular = lerp(nonMetal, metal, metalRange) * _SpecularIntensity;

    // Emission
    half emissionMask = SAMPLE_TEXTURE2D(_EmissionMask, sampler_EmissionMask, input.uv).r;
    float emission = emissionMask * _EmissionIntensity;

    // RimLight
    half rimLightMask = SAMPLE_TEXTURE2D(_RimLightMask, sampler_RimLightMask, input.uv).r;
    float2 screenUV = input.positionNDC.xy / input.positionNDC.w;
    float depth = SampleSceneDepth(screenUV);
    float linearEyeDepth = LinearEyeDepth(depth, _ZBufferParams);
    float3 offsetVS = float3(input.positionVS.xy + normalVS.xy * _RimLightOffset, input.positionVS.z);
    float4 offsetCS = TransformWViewToHClip(offsetVS);
    float4 offsetVP = TransformHClipToViewPortPos(offsetCS);
    float offsetDepth = SampleSceneDepth(offsetVP);
    float offsetLinearEyeDepth = LinearEyeDepth(offsetDepth, _ZBufferParams);
    float rimLightRange = step(_RimLightThreshold, offsetLinearEyeDepth - linearEyeDepth);
    float fresnel = 1 - saturate(dot(normalWS, viewWS));
    float rimLight = lerp(0.0, rimLightRange, fresnel) * rimLightMask * _RimLightIntensity * mainLightShadow;

    // Final
    half3 diffuseColor = lerp(diffuse * _ShadowColor, diffuse, mainLightShadow);
    half3 specularColor = specular;
    half3 emissionColor = emission * _EmissionColor;
    half3 rimLightColor = diffuseColor.rgb * rimLight * _RimLightColor;
    half3 lightColor = mixLightColor;
    half3 finalColor = diffuseColor * lightColor + specularColor + emissionColor + rimLightColor;
    return half4(finalColor, diffuse.a);
}

#endif