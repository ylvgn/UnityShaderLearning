Shader "Unlit/Week004_PhongLighting_PointLight"
{
    Properties
    {
        _Ambient ("Ambient", Color) = (1, 1, 1, 1)
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _ShineIntensity ("ShineIntensity", range(1, 50)) = 15
        [KeywordEnum(ON, OFF)] _ADDITIONAL_LIGHT ("ADDITIONAL_LIGHT", Int) = 1
    }

    SubShader
    {
        Tags {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalRenderPipeline"
        }

        ZTest Always
        ZWrite Off

        HLSLINCLUDE
        #include "../../../MyCommon/My_Common.hlsl"
        CBUFFER_START(UnityPerMaterial)
            float4 _Ambient;
            float4 _Diffuse;
            float _ShineIntensity;
        CBUFFER_END

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
        ENDHLSL

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _ADDITIONAL_LIGHT_ON
             
            Varyings vert(Attributes i) {
                Varyings o;
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.positionHCS = TransformWorldToHClip(o.positionWS);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS, true);
                o.uv = i.uv;
                return o;
            }

            float4 phong_lighting(float3 positionWS, float3 normalWS, float3 viewDir, float3 lightDir, float4 lightColor) {
                float3 L = normalize(lightDir);
                float3 N = normalize(normalWS);
                float3 R = reflect(-L, N);
                float3 V = normalize(viewDir);
                float4 ambient = _Ambient;
                float4 diffuse = _Diffuse * max(0, dot(N, L));
                float4 specular = lightColor * pow(max(0, dot(R, V)), _ShineIntensity);
                return ambient + diffuse + specular;
            }

            float4 frag(Varyings i) : SV_Target{
                float4 o;
                float3 positionWS = i.positionWS;
                float3 viewDir = normalize(_WorldSpaceCameraPos - positionWS);
                float3 normalWS = i.normalWS;
#if _ADDITIONAL_LIGHT_ON
                // "Lighting.hlsl" -> VertexLighting
                int n = GetAdditionalLightsCount();
                for (int j = 0; j < n; j++)
                {
                    Light light = GetAdditionalLight(j, positionWS);
                    float4 lightColor;
                    lightColor.xyz = light.color * light.distanceAttenuation;
                    lightColor.a = 1;
                    o += phong_lighting(positionWS, normalWS, viewDir, light.direction, lightColor);
                }
#else
                Light light = GetMainLight(); // only directional light ??
                float4 lightColor;
                lightColor.xyz = light.color * light.distanceAttenuation;
                lightColor.a = 1;
                o = phong_lighting(positionWS, normalWS, viewDir, light.direction, lightColor);
#endif
                return o;
            }
            ENDHLSL
        }
    }
}
