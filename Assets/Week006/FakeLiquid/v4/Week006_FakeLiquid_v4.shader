Shader "Unlit/Week006_FakeLiquid_v4"
{
    Properties
    {
        _MainTex           ("MainTex",             2D) = "white" {}
        _ColorTop          ("ColorTop",         Color) = (1,1,1,1)
        _ColorDown         ("ColorDown",        Color) = (1,1,1,1)
        [HDR]_FresnelColor ("FresnelColor",     Color) = (1,1,1,1)
        _FillAmount        ("FillAmount", Range(-1,1)) = 0
        _Fresnel           ("Fresnel",  Range(0.1, 5)) = 1.5
        _FoamHeight        ("FoamHeight", Range(0, 1)) = 0
// debug
        [KeywordEnum(ON, OFF)] _MY_DEBUG_SHAKE("MY_DEBUG_SHAKE", Int) = 0
    }

    SubShader
    {
        Tags {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }

        Cull Off
        //AlphaToMask On // transparency

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _MY_DEBUG_SHAKE_ON
            #include "../../../MyCommon/My_Common.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 positionWS   : TEXCOORD8;
                float  fresnel      : TEXCOORD7;
                float  cos_theta    : TEXCOORD6;
            };

            float4 _ColorTop;
            float4 _ColorDown;
            float4 _FresnelColor;
            float4 _MyPlane;
            float  _FoamHeight;
            float  _Fresnel;
            float  _FillAmount;
            MY_TEXTURE2D(_MainTex);

            float4 _Plane;

            Varyings vert(Attributes i)
            {
                Varyings o;
                float3 positionWS = TransformObjectToWorld(i.positionOS.xyz);

                float3 normalWS = TransformObjectToWorldDir(i.normalOS, true);
                float3 viewDirWS = normalize(_WorldSpaceCameraPos - positionWS);
                
                float4 centerWS = UNITY_MATRIX_M._m03_m13_m23_m33;
                float cos_theta = dot(float3(0,1,0), normalize(positionWS - centerWS.xyz));

                o.fresnel = dot(viewDirWS, normalWS);
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.positionWS = positionWS;
                o.cos_theta = cos_theta;
                return o;
            }

            float4 frag(Varyings i, float facing : VFACE) : SV_Target
            {
                //return float4(facing, 0, 0, 1);
                float3 worldPos = i.positionWS;

#if _MY_DEBUG_SHAKE_ON
                if (dot(worldPos, _Plane) > 0)
                    discard;
#else
                float4 centerWS = UNITY_MATRIX_M._m03_m13_m23_m33;
                float diff = worldPos.y + _FillAmount - centerWS.y;
                
                if (diff > 0)
                    discard;
#endif

                float cos_theta = i.cos_theta;
                float fresnel = saturate(pow(i.fresnel, _Fresnel));
                float4 colorDown = lerp(_ColorDown, _FresnelColor, 1 - fresnel);

                float4 colorTop = _ColorTop;

                float4 o = lerp(colorTop, colorDown, facing);

                float t = saturate(_FoamHeight - abs(cos_theta)); // [0, 1]
                return lerp(o, colorTop, t ? facing * t: t);
            }
            ENDHLSL
        }
    }
}

