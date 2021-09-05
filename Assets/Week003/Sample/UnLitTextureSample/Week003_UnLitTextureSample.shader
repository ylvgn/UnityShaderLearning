Shader "Unlit/Week003_UnLitTextureSample"
{
    Properties
    {
        [MainColor] _BaseColor("BaseColor", Color) = (1,1,1,1)
        [MainTexture] _MainTex("Texture", 2D) = "white" {}
    }

    // Universal Render Pipeline subshader.
    SubShader
    {
        Tags {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalRenderPipeline"
        }
        ZTest Always

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "../../Week003_My_Common.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };

            MY_TEXTURE2D(_MainTex);
            /*
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            */
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
            CBUFFER_END

            Varyings vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz); // "SpaceTransforms.hlsl"
                o.uv = i.uv;
                //o.uv = TRANSFORM_TEX(i.uv, _MainTex); // Equivalent to o.uv = i.uv * _MainTex_ST.xy + _MainTex.ST.zw;
                return o;
            }

            float4 frag(Varyings i) : SV_Target {
                float4 o = MY_SAMPLE_TEXTURE2D(_MainTex, i.uv);
                return o * _BaseColor;
                //return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _BaseColor;
            }
            ENDHLSL
        }
    }
}
