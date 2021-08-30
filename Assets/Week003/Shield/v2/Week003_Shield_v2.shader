Shader "Unlit/Week003_Shield_v2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [HDR]_Color ("Color", Color) = (1,1,1,1)
        [HDR]_EdgeColor("EdgeColor", Color) = (1,1,1,1)
        _Fresnel("Fresnel", Range(0.25, 4)) = 1
        _EdgePower("EdgePower", Range(0, 5)) = 1
        _Power("Power", Range(0.1, 2)) = 1
    }
    SubShader
    {
        Tags {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }

        ZWrite Off
        Cull Off
        Blend SrcAlpha One

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "../../Week003_My_Common.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 viewDirWS    : TEXCOORD2;
            };

            MY_TEXTURE2D(_MainTex);
            float4 _Color;
            float4 _EdgeColor;
            float _Fresnel;
            float _EdgePower;
            float _Power;

            Varyings vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                float3 positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.normalWS = TransformObjectToWorldDir(i.normalOS);
                o.viewDirWS = GetCameraPositionWS() - positionWS; // ShaderVariablesFunctions.hlsl -> _WorldSpaceCameraPos
                o.uv = i.uv;
                return o;
            }

            float4 frag(Varyings i) : SV_Target
            {
                float3 viewDirWS = normalize(i.viewDirWS);
                float3 normalWS = normalize(i.normalWS);
                float2 screenUV = i.positionHCS.xy / _ScaledScreenParams.xy;

                #if UNITY_REVERSED_Z
                    // D3D
                    real depth = SampleSceneDepth(screenUV);
                #else
                    // OpenGL
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(screenUV));
                #endif

                // fresnel: https://www.ronja-tutorials.com/post/012-fresnel/
                float fresnel = abs(dot(normalWS, viewDirWS));
                fresnel = saturate(1 - fresnel);
                fresnel = pow(fresnel + 0.1, _Fresnel);
                //float fresnel = dot(abs(normalWS), float3(0, 1, 0)) * _Fresnel; // just Y-axis

                float3 positionVS0 = ComputeViewSpacePosition(screenUV, depth, UNITY_MATRIX_I_P);
                float3 positionVS1 = ComputeViewSpacePosition(screenUV, i.positionHCS.z, UNITY_MATRIX_I_P);
                float intersect = (1 - (positionVS0.z - positionVS1.z)) * _EdgePower;

                float intensity = max(fresnel, intersect);
                intensity = saturate(pow(intensity, _Power));

                float4 maskTex = MY_SAMPLE_TEXTURE2D(_MainTex, i.uv);
                return lerp(_EdgeColor, _Color * intensity, 1 - maskTex.r);
            }
            ENDHLSL
        }
    }
}
