Shader "Custom/Character"
{
    Properties
    {
        [Header(Render)]
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("Cull Mode", Float) = 0.0
        _StencilRef ("StencilRef", Range(0, 255)) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp ("StencilComp", Float) = 0
        _DebugTex ("Debug Tex", 2D) = "white" {}
        [Header(Diffuse)]
        _DiffuseTex ("Diffuse Texture", 2D) = "white" {}
        _DiffuseColor ("Diffuse Color", Color) = (1, 1, 1, 1)
        _AlphaMask ("Alpha Mask", 2D) = "white" {}
        [Header(Normal)]
        _NormalTex ("Normal Texture", 2D) = "bump" {}
        _NormalIntensity ("Normal Intensity", Range(0,1)) = 0.5
        [Header(Shadow)]
        _RampTex ("Ramp Texture", 2D) = "white" {}
        _ShadowTex ("Shadow Texture", 2D) = "white" {}
        _ShadowMask ("Shadow Mask", 2D) = "white" {}
        _ShadowColor ("Shadow Color", Color) = (0, 0, 0, 0)
        _ShadowRange ("Shadow Range", Range(0, 1)) = 0.5
        _ShadowSmooth ("Shadow Smooth", Range(0, 1)) = 0.5
        [Header(Specular)]
        _MatcapTex ("Matcap Texture", 2D) = "white" {}
        _SpecularMask ("Specular Mask", 2D) = "black" {}
        _nonMetalSmooth ("Non Metal Smooth", Range(0.001, 1)) = 0.5
        _nonMetalIntensity ("Non Metal Intensity", Range(0, 1)) = 0.5
        _MetalIntensity ("Metal Intensity", Range(0, 1)) = 0.5
        _SpecularIntensity ("Specular Intensity", Range(0, 1)) = 0.5
        [Header(Ambient Occlusion)]
        _AOMask ("AO Texture", 2D) = "white" {}
        _AOIntensity ("AO Intensity", Range(0, 3)) = 0.5
        [Header(Emission)]
        _EmissionMask ("Emission Mask", 2D) = "black" {}
        _EmissionColor ("Emission Color", Color) = (1, 1, 1, 1)
        _EmissionIntensity ("Emission Intensity", Range(0, 10)) = 1
        [Header(RimLight)]
        _RimLightOffset ("RimLight Offset", Range(0, 0.005)) = 0.5
        _RimLightThreshold ("RimLight Threshold", Range(0.01, 0.1)) = 0.5
        _RimLightIntensity ("RimLight Intensity", Range(0, 10)) = 0.5
        _RimLightMask ("RimLight Mask", 2D) = "white" {}
        _RimLightColor ("RimLight Color", Color) = (1, 1, 1, 1)
        [Header(Outline)]
        _OutlineMask ("Outline Mask", 2D) = "white" {}
        _OutlineColor ("Outline Color", Color) = (1, 1, 1, 1)
        _OutlineWidth ("Outline Width", Range(0, 10)) = 1
        _OutlineZOffset ("Outline ZOffset", Range(-0.1, 0.1)) = 0
        [Header(Option)]
        _UseRampTex ("Use Ramp Texture", float) = 0.0
        _UseMatcap ("Use Matcap Texture", float) = 0.0
        _UseILM ("Use ILM LightMap", float) = 0.0
        _UseSSOutline ("Use SS Outline", float) = 0.0
    }

    SubShader
    {        
        Tags {"RenderPipeline" = "UniversalPipeline"}

        Pass
        {
            Name "Forward"
            Cull [_CullMode]
            Stencil
            {
                Ref [_StencilRef]
                Comp [_StencilComp]
                Pass replace
            }
            Tags {"LightMode" = "UniversalForward"}

            HLSLPROGRAM
            #include "../ShaderLibrary/CharacterPass.hlsl"
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ _FORWARD_PLUS
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            ENDHLSL
        }

        Pass
        {
            Name "Outline"
            Cull Front
            Tags {"LightMode" = "SRPDefaultUnlit"}
            
            HLSLPROGRAM
            #include "../ShaderLibrary/CharacterOutlinePass.hlsl"
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags {"LightMode" = "ShadowCaster"}

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags {"LightMode" = "DepthOnly"}

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Unlit"
}