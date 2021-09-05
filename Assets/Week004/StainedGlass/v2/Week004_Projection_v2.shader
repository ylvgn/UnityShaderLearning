Shader "Unlit/Week004_Projection_v2"
{
    Properties
    {
        [HDR] _Color("Color", Color) = (1,1,1,1)
        _DepthBias("Depth Bias", Range(0.00001, 0.0001)) = 0.0001
        _Intensity("Intensity", Range(0, 10)) = 1
        _StartDist("StartDist", Range(0, 20)) = 10
        _FadedWidth("FadedWidth", Range(0, 5)) = 1
    }

    SubShader
    {
        Tags {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalRenderPipeline"
        }

        ZTest Always
        ZWrite Off
        Blend SrcAlpha One

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "../../../MyCommon/My_Common.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
            };

            MY_TEXTURE2D(_MyProjColorTex);

            TEXTURE2D(_MyProjDepthTex);
            SAMPLER(sampler_MyProjDepthTex);

            CBUFFER_START(UnityPerMaterial)
                float4x4 _MyProjVP;
                float4 _MyProjPos;
                float4 _Color;
                float _DepthBias;

                float _Intensity;
                float _StartDist;
                float _FadedWidth;
            CBUFFER_END

            Varyings vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = i.positionOS;
                //o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                return o;
            }

            float4 frag(Varyings i) : SV_Target {
                float2 screenUV = i.positionHCS.xy / _ScaledScreenParams.xy;
                #if UNITY_REVERSED_Z
                    // D3D
                    float depth = SampleSceneDepth(screenUV);
                #else
                    // OpenGL
                    float depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(screenUV));
                #endif

                float3 worldPos = ComputeWorldSpacePosition(screenUV, depth, UNITY_MATRIX_I_VP);
                float4 projPos = mul(_MyProjVP, float4(worldPos, 1));
                projPos.xyz /= projPos.w;

                if (abs(projPos.x) > 1 || abs(projPos.y) > 1)
                    return float4(0, 0, 0, 0);

                float2 projUV = -projPos.xy * 0.5 + 0.5;
                float4 projColorTex = MY_SAMPLE_TEXTURE2D(_MyProjColorTex, projUV);
                float projDepthTex = SAMPLE_TEXTURE2D_X(_MyProjDepthTex, sampler_MyProjDepthTex, projUV).r;

                //return float4(-projPos.z * 10, 0, 0, 1);
                //return float4(projDepthTex * 10, 0, 0, 1);
                //return projColorTex;
                
                float diff = projDepthTex + projPos.z;
                //return float4(diff * 10, 0, 0, 1);

                if (diff > _DepthBias)
                    return float4(1, 0, 0, 0);

                // fade
                float projDis = length(_MyProjPos.xyz - worldPos);
                float fade = 1 - saturate(smoothstep(_StartDist, _StartDist + _FadedWidth, projDis));
                projColorTex.a *= fade * fade;
                _Color.rgb *= _Intensity;

                return _Color * projColorTex;
            }
            ENDHLSL
        }
    }
}
