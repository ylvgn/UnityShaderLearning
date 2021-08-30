Shader "Unlit/Week003_Shield_v1"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _Intersect("Intersect", Range(0, 1)) = 0.1
    }

    SubShader
    {
        Tags {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }

        ZWrite Off
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
            };

            float4 _Color;
            float _Intersect;

            Varyings vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                return o;
            }

            float4 frag(Varyings i) : SV_Target
            {
                // NDC
                float2 screenUV = i.positionHCS.xy / _ScaledScreenParams.xy;

                #if UNITY_REVERSED_Z
                    // D3D
                    float depth = SampleSceneDepth(screenUV);
                #else
                    // OpenGL
                    float depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(screenUV));
                #endif

                // screenZ
                float4 positionCS0 = ComputeClipSpacePosition(screenUV, depth);// DNC -> clip space
                float4 positionVS0 = mul(UNITY_MATRIX_I_P, positionCS0);  // clip space -> view space
                positionVS0.z = -positionVS0.z; // The view space uses a right-handed coordinate system.
                positionVS0.xyz /= positionVS0.w;

                // vertexZ
                float4 positionCS1 = ComputeClipSpacePosition(screenUV, i.positionHCS.z);// DNC -> clip space
                float4 positionVS1 = mul(UNITY_MATRIX_I_P, positionCS1); // clip space -> view space
                positionVS1.z = -positionVS1.z;
                positionVS1.xyz /= positionVS1.w;

                float d = saturate(smoothstep(_Intersect, 0, positionVS0.z - positionVS1.z));
                float4 o = _Color;
                o.a *= d;
                return o;
            }
            ENDHLSL
        }
    }
}