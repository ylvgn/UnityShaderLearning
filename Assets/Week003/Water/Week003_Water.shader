Shader "Unlit/Week003_Water"
{
    Properties
    {
        [HDR]_Color ("Color", Color) = (1,1,1,1)
        _Intersect("Intersect", Range(0.1, 1)) = 0
    }
    SubShader
    {
        Tags {
            "Queue" = "Transparent"
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }

        ZWrite Off
        //Cull Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "../Week003_My_Common.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 normalWS     : TEXCOORD1;
            };

            float4 _Color;
            float _Intersect;

            Varyings vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.normalWS = TransformObjectToWorldDir(i.normalOS);
                return o;
            }

            float4 frag(Varyings i) : SV_Target
            {
                float3 normalWS = normalize(i.normalWS);
                float2 screenUV = i.positionHCS.xy / _ScaledScreenParams.xy;

                #if UNITY_REVERSED_Z
                    // D3D
                    real depth = SampleSceneDepth(screenUV);
                #else
                    // OpenGL
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(screenUV));
                #endif

                float3 positionVS0 = ComputeViewSpacePosition(screenUV, depth, UNITY_MATRIX_I_P);
                float3 positionVS1 = ComputeViewSpacePosition(screenUV, i.positionHCS.z, UNITY_MATRIX_I_P);
                float d = positionVS0.z - positionVS1.z;

                float alpha = smoothstep(_Intersect, 0, saturate(d * 0.5));
                float4 o = _Color;
                o.a *= 1 - alpha;
                return o;
            }
            ENDHLSL
        }
    }
}
