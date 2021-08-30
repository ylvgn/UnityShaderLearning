Shader "Unlit/Week003_WorldScanner_v1"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
        }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float _Radius;
            float _EdgeWidth;
            float _EdgeSoftness;
            float4 _ScanerCenter;
            const static float EPS = 1E-4;

            Varyings vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                return o;
            }

            float4 frag(Varyings i) : SV_Target
            {
                float4 o;
                float2 UV = i.positionHCS.xy / _ScaledScreenParams.xy;
                o.xyz = SampleSceneColor(UV);
                o.a = 1;
                #if UNITY_REVERSED_Z
                    // D3D
                    real depth = SampleSceneDepth(UV);
                #else
                    // OpenGL
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
                #endif
                

                // clip space -> world space.
                float3 worldPos = ComputeWorldSpacePosition(UV, depth, UNITY_MATRIX_I_VP);

                // circle
                float2 xz = (worldPos.xz - _ScanerCenter.xz);
                float len_inner = length(xz);

                float hard = _EdgeWidth * 0.5f;
                float soft = hard + _EdgeSoftness + EPS;
                float _Dissolve = saturate((_Radius - len_inner + hard) / _EdgeWidth);
                float dissolve = lerp(-soft, 1 + soft, _Dissolve);

                if (_EdgeWidth || _EdgeSoftness)
                {
                    float e = abs(0.5 - dissolve);
                    float w = smoothstep(hard, soft, e);
                    //return float4(w, 0, 0, depth);
                    o = lerp(_Color, o, saturate(w));
                }

                return o;
            }
            ENDHLSL
        }
    }
}
