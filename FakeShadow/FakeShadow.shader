Shader "Custom/FakeShadow"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _Offset ("Offset", Vector) = (0, 0, -1)
        [Header(Stencil)]
        _StencilRef ("_StencilRef", Range(0, 255)) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp ("_StencilComp", float) = 0
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalRenderPipeline" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        CBUFFER_START(UnityPerMaterial)
        float4 _Color;
        float3 _Offset;
        CBUFFER_END
        ENDHLSL

        Pass
        {
            Name "HairShadow"
            Tags { "LightMode" = "UniversalForward" }

            Stencil
            {
                Ref [_StencilRef]
                Comp [_StencilComp]
                Pass keep
            }

            ZTest LEqual
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                float4 positionOS: POSITION;
                float4 color: COLOR;
            };

            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float4 color: COLOR;
            };


            Varyings vert(Attributes input)
            {
                Varyings output;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS);
                output.positionCS = positionInputs.positionCS;

                float3 offset = _Offset.xyz;
                offset.y = offset.y * _ProjectionParams.x;
                output.positionCS.xy += offset * offset.z;
                output.color = input.color;

                return output;
            }

            half4 frag(Varyings input): SV_Target
            {
                return _Color;
            }
            ENDHLSL
        }
    }
}