Shader "Unlit/Week003_WorldScanner_v3"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Enum(Week003_WorldScanner_v3)] _UvMode("UvMode:0|1|2", Int) = 0

        _Color ("Color", Color) = (1, 1, 1, 1)
        _Radius ("Radius", range(0, 100)) = 50
        _EdgeWidth ("EdgeWidth", range(0, 10)) = 1
        _EdgeSoftness ("EdgeSoftness", range(0, 1)) = 0
        _ScanerCenter ("ScannerCenter", Vector) = (0, 0, 0, 0)
    }
    SubShader
    {
        Tags {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }

        ZTest Always
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

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
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
            };

            MY_TEXTURE2D(_MainTex);

            float4 _Color;
            float _Radius;
            float _EdgeWidth;
            float _EdgeSoftness;
            float4 _ScanerCenter;
            float _UvMode;
            const static float EPS = 1E-4;

            Varyings vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = i.positionOS;
                //o.positionHCS = TransformObjectToHClip(i.positionOS.xyz); because fullScreenTriangle is already [-1, 1]
                return o;
            }

            float4 frag(Varyings i) : SV_Target
            {
                float2 screenUV = i.positionHCS.xy / _ScaledScreenParams.xy;
                #if UNITY_REVERSED_Z
                    // D3D
                    real depth = SampleSceneDepth(screenUV);
                #else
                    // OpenGL
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(screenUV));
                #endif
                //return float4(depth * 100, 0, 0, 1);

                // clip space -> world space.
                float3 worldPos = ComputeWorldSpacePosition(screenUV, depth, UNITY_MATRIX_I_VP);
                
                // circle
                float2 xz = worldPos.xz - _ScanerCenter.xz;
                float distance = length(xz);

                float4 o = _Color;

                if (_UvMode == 0)
                {
                    float hard = _EdgeWidth * 0.5f;
                    float soft = hard + _EdgeSoftness + EPS;
                    float _Dissolve = saturate((_Radius + hard - distance) / _EdgeWidth);

                    float dissolve = lerp(-soft, 1 + soft, _Dissolve);
                    if (_EdgeWidth || _EdgeSoftness)
                    {
                        float e = abs(0.5 - dissolve);
                        float w = smoothstep(hard, soft, e);
                        o = lerp(o, float4(1, 1, 1, 0), saturate(w)); // use alpha=0 -> no need to use render target opaque color
                    }

                    float4 tex = MY_SAMPLE_TEXTURE2D(_MainTex, screenUV);
                    o *= tex;
                }
                else if (_UvMode == 1) {
                    float u = (distance - _Radius) / _EdgeWidth; // invLerp
                    float4 tex = MY_SAMPLE_TEXTURE2D(_MainTex, float2(u, 0));
                    float w = 1 - abs(u * 2 - 1);
                    //return float4(w, 0, 0, 1);
                    float alpha = smoothstep(0, _EdgeSoftness, saturate(w));
                    o *= tex;
                    o.a = alpha;
                } else {
                    float u = (distance - _Radius) / _EdgeWidth;
                    float v = atan2(xz.y, xz.x) / (2 * PI);
                    float2 uv = float2(u, v);
                    float4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv  * float2(1, 16) + _MainTex_ST.zw); // Tiling
                    //float4 tex = MY_SAMPLE_TEXTURE2D(_MainTex, float2(u, v));
                    float w = 1 - abs(u * 2 - 1);
                    float alpha = smoothstep(0, _EdgeSoftness, saturate(w));
                    o *= tex;
                    o.a = alpha;
                }

                return o;
            }
            ENDHLSL
        }
    }
}
