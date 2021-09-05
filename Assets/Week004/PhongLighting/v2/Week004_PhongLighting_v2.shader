Shader "Unlit/Week004_PhongLighting_v2"
{
    Properties
    {
        _MainTex   ("MainTex",      2D)         = "white" {}
        _BaseColor ("BaseColor", Color)         = (1, 1, 1, 1)
        _Ambient   ("Ambient",   Color)         = (0.1, 0.1, 0.1, 1)
        _Diffuse   ("Diffuse",   range(0, 1))   = 0.7
        _Specular  ("Specular",  range(0, 1))   = 0.3
        _Shininess ("Shininess", range(0, 256)) = 32

        [KeywordEnum(ON, OFF)] _MY_DEBUG("MyDebug", Int) = 0
    }

    SubShader
    {
        HLSLINCLUDE
            #include "../../../MyCommon/My_Common.hlsl"
        ENDHLSL

        Tags {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalRenderPipeline"
        }

        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _MY_DEBUG_ON

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
                float3 positionWS   : TEXCOORD8;
            };

            struct SurfaceInfo
            {
                float4 baseColor;
                float3 ambient;
                float  diffuse;
                float  specular;
                float  shininess;
                float3 normal;
            };

            static const int k_MaxLightCount = 8;
            CBUFFER_START(UnityPerMaterial)
                int g_LightCount;
                float4 g_LightPos[k_MaxLightCount];
                float4 g_LightDir[k_MaxLightCount];
                float4 g_LightColor[k_MaxLightCount];
                float4 g_LightParams[k_MaxLightCount];

                float4 _BaseColor;
                float4 _Ambient;
                float _Diffuse;
                float _Specular;
                float _Shininess;
            CBUFFER_END

            MY_TEXTURE2D(_MainTex)

            Varyings vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.positionWS  = TransformObjectToWorld(i.positionOS.xyz);
                o.normalWS    = TransformObjectToWorldDir(i.normalOS);
                o.uv = i.uv;
                return o;
            }

            // https://github.com/SimpleTalkCpp/workshop-2021-07-unity-shader/blob/main/Assets/Week004/Week004_Phong/Week004_Phong.shader
            float4 computeLighting(Varyings i, SurfaceInfo s) {
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS);

                int lightCount = min(k_MaxLightCount, g_LightCount);
                float4 o = s.baseColor * float4(s.ambient, 1);

                for (int j = 0; j < lightCount; j++) {
                    float3 lightColor = g_LightColor[j].rgb;
                    float  lightIntensity = g_LightColor[j].a;

                    float3 lightPos = g_LightPos[j].xyz;

                    float3 lightDir = g_LightDir[j].xyz;
                    float  isDirectional = g_LightDir[j].w;

                    float3 lightPosDir = i.positionWS - lightPos;

                    float3 L = lerp(lightPosDir, lightDir, isDirectional);
                    float  lightSqDis = dot(L, L) * (1 - isDirectional);

                    L = normalize(L);

                    float  isSpotlight = g_LightParams[j].x;
                    float  lightSpotAngle = g_LightParams[j].y;
                    float  lightInnerSpotAngle = g_LightParams[j].z;
                    float  lightRange = g_LightParams[j].w;

                    float diffuse = s.diffuse * max(dot(-L, s.normal), 0.0f);

                    float3 reflectDir = reflect(L, s.normal);
                    float specular = s.specular * pow(max(dot(viewDir, reflectDir), 0.0f), s.shininess);

                    float attenuation = 1 - saturate(lightSqDis / (lightRange * lightRange));
                    float intensity = lightIntensity * attenuation;

                    if (isSpotlight > 0) {
                        intensity *= smoothstep(lightSpotAngle, lightInnerSpotAngle, dot(lightDir, L));
                    }

                    o.rgb += (diffuse + specular) * intensity * s.baseColor.rgb * lightColor;
                }

                return o;
            }

            float4 phong_lighting(Varyings i, SurfaceInfo s)
            {
                float4 tex = MY_SAMPLE_TEXTURE2D(_MainTex, i.uv);
                float4 o = tex * s.baseColor * float4(s.ambient, 1); // Ambient is not per light, it's from global environment 
                float3 N = s.normal;
                float3 V = normalize(_WorldSpaceCameraPos - i.positionWS);

                int n = min(k_MaxLightCount, g_LightCount);
                for (int j = 0; j < n; j++) {
                    float3 lightColor     = g_LightColor[j].rgb;
                    float  lightIntensity = g_LightColor[j].w;

                    float3 lightPos       = g_LightPos[j].xyz;

                    float3 lightDir       = g_LightDir[j].xyz;
                    float  isDirectional  = g_LightDir[j].w; // 1 -> true

                    float3 lightPosDir    = i.positionWS - lightPos;

                    float3 L              = lerp(lightPosDir, lightDir, isDirectional);
                    float  LightSqDis     = dot(L, L) * (1 - isDirectional);

                    L = normalize(L);

                    float isSpotLight         = g_LightParams[j].x; // 1 -> true
                    float lightSpotAngle      = g_LightParams[j].y;
                    float lightInnerSpotAngle = g_LightParams[j].z;
                    float lightRange          = g_LightParams[j].w;

                    float diffuse             = s.diffuse * max(0.0, dot(N, -L));

                    float3 R                  = reflect(L, N);
                    float  specular           = s.specular * pow(max(dot(R, V), 0.0), s.shininess);

                    float attenuation         = 1 - saturate(LightSqDis / (lightRange * lightRange)); // not same as unity
                    float intensity           = lightIntensity * attenuation;

                    if (isSpotLight > 0) {
                        intensity *= smoothstep(lightSpotAngle, lightInnerSpotAngle, dot(L, lightDir));
                    }

                    o.rgb += (diffuse + specular) * intensity * lightColor.rgb * s.baseColor.rgb;
                }
                return o;
            }

            float4 frag(Varyings i) : SV_Target
            {
                SurfaceInfo s;
                s.baseColor = _BaseColor;
                s.ambient   = _Ambient.xyz;
                s.diffuse   = _Diffuse;
                s.specular  = _Specular;
                s.shininess = _Shininess;
                s.normal    = normalize(i.normalWS);
#if _MY_DEBUG_ON
                //return float4(1, 0, 0, 1);
                return computeLighting(i, s);
#else
                //return float4(0, 1, 0, 1);
                return phong_lighting(i, s);
#endif
            }
            ENDHLSL
        }
    }
}
