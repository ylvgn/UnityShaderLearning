Shader "Unlit/Week004_PhongLighting_DirectionalLight"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Ambient ("Ambient", Color) = (1, 1, 1, 1)
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _ShineIntensity ("ShineIntensity", range(1, 50)) = 1
    }

    SubShader
    {
        Tags {
            "RenderType"="Opaque"
            "RenderPipeline" = "UniversalRenderPipeline"
        }
        ZTest Always
        ZWrite Off

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "../../../MyCommon/My_Common.hlsl"

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
                float3 positionWS   : FLOAT3;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 MY_LIGHT_COLORS[8];
                float4 MY_LIGHT_DIRECTIONS[8];
                float4 _Ambient;
                float4 _Diffuse;
                float _ShineIntensity;
                int MY_LIGHT_COUNT;
            CBUFFER_END

            MY_TEXTURE2D(_MainTex);

            Varyings vert(Attributes i) {
                Varyings o;
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.positionHCS = TransformWorldToHClip(o.positionWS);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS, true);
                o.uv = i.uv;
                return o;
            }

            float4 phong_lighting(Varyings i, float3 lightDir, float4 lightColor) {
                float3 L = normalize(lightDir);
                float3 N = SafeNormalize(i.normalWS); // "Common.hlsl"
                float3 V = SafeNormalize(_WorldSpaceCameraPos - i.positionWS);
                float3 R = SafeNormalize(dot(L, N) * 2 * N - L); // reflect(-L, N);
                float4 ambient = _Ambient;
                float4 diffuse = _Diffuse * max(0, dot(N, L));
                float4 specular = lightColor * pow(max(0, dot(R, V)), _ShineIntensity);
                return ambient + diffuse + specular;
            }

            float4 frag(Varyings i) : SV_Target{
                float4 o;
                for (int j = 0; j < MY_LIGHT_COUNT; j++)
                {
                    // RealtimeLights.hlsl" -> GetMainLight()
                    float3 lightDir = MY_LIGHT_DIRECTIONS[j].xyz;
                    o += phong_lighting(i, lightDir, MY_LIGHT_COLORS[j]);
                }
                return o;
            }
            ENDHLSL
        }
    }
}
