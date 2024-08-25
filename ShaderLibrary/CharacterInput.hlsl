#ifndef CHARACTER_INPUT_INCLUDED
#define CHARACTER_INPUT_INCLUDED

TEXTURE2D(_DebugTex);
TEXTURE2D(_DiffuseTex);
TEXTURE2D(_NormalTex);
TEXTURE2D(_RampTex);
TEXTURE2D(_ShadowTex);
TEXTURE2D(_ShadowMask);
TEXTURE2D(_AOMask);
TEXTURE2D(_MatcapTex);
TEXTURE2D(_SpecularMask);
TEXTURE2D(_EmissionMask);
TEXTURE2D(_RimLightMask);
TEXTURE2D(_OutlineMask);
SAMPLER(sampler_DebugTex);
SAMPLER(sampler_DiffuseTex);
SAMPLER(sampler_NormalTex);
SAMPLER(sampler_RampTex);
SAMPLER(sampler_ShadowTex);
SAMPLER(sampler_ShadowMask);
SAMPLER(sampler_AOMask);
SAMPLER(sampler_MatcapTex);
SAMPLER(sampler_SpecularMask);
SAMPLER(sampler_EmissionMask);
SAMPLER(sampler_RimLightMask);
SAMPLER(sampler_OutlineMask);

CBUFFER_START(UnityPerMaterial)

// Debug
float4 _DebugTex_ST;

// Diffuse
float4 _DiffuseTex_ST;
float4 _DiffuseColor;

// Normal
float4 _NormalTex_ST;
float _NormalIntensity;

// Ramp
float4 _RampTex_ST;

// Shadow
float _ShadowTex_ST;
float4 _ShadowMask_ST;
float4 _ShadowColor;
float _ShadowRange;
float _ShadowSmooth;

// AO
float _AOMask_ST;
float _AOIntensity;

// Specular
float _MatcapTex_ST;
float _SpecularMask_ST;
float _nonMetalSmooth;
float _nonMetalIntensity;
float _MetalIntensity;
float _SpecularIntensity;

// Emission
float _EmissionMask_ST;
float4 _EmissionColor;
float _EmissionIntensity;

// RimLight
float _RimLightMask_ST;
float _RimLightOffset;
float _RimLightThreshold;
float _RimLightIntensity;
float4 _RimLightColor;
float _RimLightWidth;
float _RimLightSmooth;

// Outline
float _OutlineMask_ST;
float4 _OutlineColor;
float _OutlineWidth;

CBUFFER_END

#endif