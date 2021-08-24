Shader "Unlit/Week004_PhongLighting_SpotLight"
{
    Properties
    {
        _Ambient ("Ambient", Color) = (1, 1, 1, 1)
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
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
            
            static const int MAX_LIGHT_COUNT = 8;
            static const float EPS = 0.00001;
            CBUFFER_START(UnityPerMaterial)
                // from c#
                int MY_LIGHT_COUNT;
                float4 MY_LIGHT_POSITIONS[MAX_LIGHT_COUNT];
                float4 MY_LIGHT_DIRECTIONS[MAX_LIGHT_COUNT];
                float4 MY_LIGHT_COLORS[MAX_LIGHT_COUNT];
                float4 MY_LIGHT_PARAMS[MAX_LIGHT_COUNT];

                float4 _Ambient;
                float4 _Diffuse;
                float _ShineIntensity;
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
                float3 N = normalize(i.normalWS);
                float3 V = normalize(_WorldSpaceCameraPos - i.positionWS);
                float3 R = normalize(reflect(-L, N));
                float4 ambient = _Ambient;
                float4 diffuse = _Diffuse * max(0, dot(N, L));
                float4 specular = lightColor * pow(max(0, dot(R, V)), _ShineIntensity);
                return ambient + diffuse + specular;
            }

            float4 frag(Varyings i) : SV_Target{
                float4 o;
                float lightCount = min(MAX_LIGHT_COUNT, MY_LIGHT_COUNT);

                for (int j = 0; j < lightCount; j ++)
                {
                    float3 lightPos = MY_LIGHT_POSITIONS[j].xyz;
                    float3 lightDir = MY_LIGHT_DIRECTIONS[j].xyz;
                    float4 lightColor = MY_LIGHT_COLORS[j];
                    float4 lightParam = MY_LIGHT_PARAMS[j];

                    float isSpotLight = lightParam.x;
                    float spotAngle = lightParam.y;
                    float innerSpotAngle = lightParam.z;
                    float lightRange = lightParam.w;

                    float isDirectional = MY_LIGHT_POSITIONS[j].w;
                    float3 L = lerp(lightPos - i.positionWS, lightDir, isDirectional);

                    // https://gamedev.stackexchange.com/questions/56897/glsl-light-attenuation-color-and-intensity-formula
                    float dd = max(dot(L, L), EPS);
                    float rr = max(dot(lightRange, lightRange), EPS);
                    float attenuation = saturate(1.0 - (dd / rr));
                    attenuation *= attenuation;

                    o += attenuation * phong_lighting(i, L, lightColor);
                }
                return o;
            }
            ENDHLSL
        }
    }
}
