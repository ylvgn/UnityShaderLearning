Shader "Unlit/Week004_LambertLighting_PointLightSample"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Ambient ("Ambient", Color) = (1, 1, 1, 1)
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _ShineIntensity("ShineIntensity", range(3, 50)) = 10
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalRenderPipeline" }
        ZTest Always
        ZWrite Off

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "../../../../../MyCommon/My_Common.hlsl"

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
                float3 normalWS     : NORMAL;
                float3 positionWS   : TEXCOORD1;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 MY_LIGHT_POSITION;
                float4 MY_LIGHT_COLOR;
                float4 _Ambient;
                float4 _Diffuse;
                float _ShineIntensity;
            CBUFFER_END

            MY_TEXTURE2D(_MainTex);

            Varyings vert(Attributes i) {
                Varyings o;
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);     // mul(UNITY_MATRIX_M, positionOS)
                o.positionHCS = TransformWorldToHClip(o.positionWS);         // mul(UNITY_MATRIX_VP, positionWS)
                o.normalWS = TransformObjectToWorldNormal(i.normalOS, true);
                    //o.normalWS = mul(i.normalOS, (float3x3)UNITY_MATRIX_I_M);  // inverse transpose
                o.uv = i.uv;
                return o;
            }

            float4 lamber_lighting(Varyings i) {
                float3 wpos = i.positionWS;
                float3 N = normalize(i.normalWS);
                float3 L = normalize(MY_LIGHT_POSITION.xyz - wpos);
                float4 tex = (dot(N, L) * 0.5 + 0.5) * MY_SAMPLE_TEXTURE2D(_MainTex, i.uv);
                    // float3 N = SafeNormalize(i.normalWS); // "Common.hlsl"
                float3 V = normalize(_WorldSpaceCameraPos - i.positionWS);
                float3 H = normalize(L + V);
                float4 ambient = _Ambient;
                float4 diffuse = tex * _Diffuse * max(0, dot(N, L));
                float4 specular = MY_LIGHT_COLOR * pow(max(0, dot(H, N)), _ShineIntensity);
                return ambient + diffuse + specular;
            }

            float4 frag(Varyings i) : SV_Target {
                return lamber_lighting(i);
            }
            ENDHLSL
        }
    }
}
