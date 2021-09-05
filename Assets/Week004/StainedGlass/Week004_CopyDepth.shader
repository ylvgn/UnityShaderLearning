Shader "Unlit/Week004_CopyDepth"
{
    SubShader
    {
        Tags {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalRenderPipeline"
        }
        ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "../../MyCommon/My_Common.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
            };

            Varyings vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = i.positionOS;
                return o;
            }

            float4 frag(Varyings i) : SV_Target{
                float2 screenUV = i.positionHCS.xy / _ScaledScreenParams.xy;
#if UNITY_REVERSED_Z
                // D3D
                float depth = SampleSceneDepth(screenUV);
#else
                // OpenGL
                float depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(screenUV));
#endif
                return float4(depth, 0, 0, 1);
            }
            ENDHLSL
        }
    }
}
