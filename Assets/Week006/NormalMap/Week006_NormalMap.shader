Shader "Unlit/Week006_NormalMap"
{
    Properties
    {
        _MainTex   ("MainTex",              2D) = "white" {}
        _NormalMap ("NormalMap",            2D) = "white" {}
        _BaseColor ("BaseColor",         Color) = (1, 1, 1, 1)
        _Ambient   ("Ambient",           Color) = (0.1, 0.1, 0.1, 0.1)
        _Diffuse   ("Diffuse",      Range(0, 1)) = 0.45
        _Specular  ("Specular", Range(0.1, 0.5)) = 0.1
        _Shininess ("Shininess",   Range(0, 50)) = 36

// debug toggle ---
        [KeywordEnum(ON, OFF)] MY_NORMAL_MAP("NORMAL_MAP", Int) = 0
    }

    SubShader
    {
        Tags {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature MY_NORMAL_MAP_ON // debug
            #include "../../MyCommon/My_Common.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalOS     : NORMAL;
                float3 tangentOS    : TANGENT;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalWS     : NORMAL;
                float3 tangentWS    : TANGENT;
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

            float4 _BaseColor;
            float4 _Ambient;
            float  _Diffuse;
            float  _Specular;
            float  _Shininess;

            static const int k_MaxLightCount = 8;
            int g_LightCount;
            float4 g_LightColor[k_MaxLightCount];
            float4 g_LightPos[k_MaxLightCount];
            float4 g_LightDir[k_MaxLightCount];
            float4 g_LightParams[k_MaxLightCount];

            MY_TEXTURE2D(_MainTex);
            MY_TEXTURE2D(_NormalMap);

            Varyings vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.positionWS  = TransformObjectToWorld(i.positionOS.xyz);
                o.normalWS    = TransformObjectToWorldNormal(i.normalOS, false);
                o.tangentWS   = mul((float3x3)GetObjectToWorldMatrix(), i.tangentOS);
                o.uv          = i.uv;
                return o;
            }

            // https://github.com/SimpleTalkCpp/workshop-2021-07-unity-shader/blob/main/Assets/Week004/Week004_Phong/Week004_Phong.shader
            float4 phong_lighting(Varyings i, SurfaceInfo s) {
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS);
                int lightCount = min(k_MaxLightCount, g_LightCount);
                float4 o       = s.baseColor * float4(s.ambient, 1);

                for (int j = 0; j < lightCount; j ++) {
                    float3 lightColor     = g_LightColor[j].rgb;
                    float  lightIntensity = g_LightColor[j].a;

                    float3 lightPos       = g_LightPos[j].xyz;
                    float3 lightDir       = g_LightDir[j].xyz;
                    float  isDirectional  = g_LightDir[j].w;
                    float3 lightPosDir    = i.positionWS - lightPos;

                    float3 L = lerp(lightPosDir, lightDir, isDirectional);
                    float  lightSqDis = dot(L, L) * (1 - isDirectional);

                    L = normalize(L);

                    float  isSpotlight         = g_LightParams[j].x;
                    float  lightSpotAngle      = g_LightParams[j].y;
                    float  lightInnerSpotAngle = g_LightParams[j].z;
                    float  lightRange          = g_LightParams[j].w;
                           
                    float  diffuse             = s.diffuse * max(dot(-L, s.normal), 0.0f);

                    float3 reflectDir          = reflect(L, s.normal);
                    float  specular            = s.specular * pow(max(dot(viewDir, reflectDir), 0.0f), s.shininess);

                    float  attenuation         = 1 - saturate(lightSqDis / (lightRange * lightRange));
                    float  intensity           = lightIntensity * attenuation;

                    if (isSpotlight > 0) {
                        intensity *= smoothstep(lightSpotAngle, lightInnerSpotAngle, dot(lightDir, L));
                    }

                    o.rgb += (diffuse + specular) * intensity * s.baseColor.rgb * lightColor;
                }
                return o;
            }

            // https://learnopengl.com/Advanced-Lighting/Normal-Mapping
            float3 normal_mapping(Varyings i)
            {
                float4 packedNormal = MY_SAMPLE_TEXTURE2D(_NormalMap, i.uv);
                float3 normalTS     = UnpackNormal(packedNormal);
                float3 T            = normalize(i.tangentWS);
                float3 N            = normalize(i.normalWS);
                float3 B            = normalize(cross(N, T));
                float3x3 TBN        = float3x3(T, B, N);

                return mul(TBN, normalTS); // tangent space -> world space
            }

            float4 frag(Varyings i) : SV_Target
            {
#if MY_NORMAL_MAP_ON
                //return MY_SAMPLE_TEXTURE2D(_NormalMap, i.uv);
                float3 normal = normal_mapping(i);
#else
                float3 normal = i.normalWS;
#endif

                float4 mainTex = MY_SAMPLE_TEXTURE2D(_MainTex, i.uv);
                SurfaceInfo s;
                s.baseColor    = _BaseColor * mainTex;
                s.ambient      = _Ambient.rgb;
                s.diffuse      = _Diffuse;
                s.specular     = _Specular;
                s.shininess    = _Shininess;
                s.normal       = normalize(normal);

                return phong_lighting(i, s);
            }
            ENDHLSL
        }
    }
}
