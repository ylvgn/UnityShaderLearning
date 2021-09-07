Shader "Unlit/Week006_FakeLiquid_v1"
{
    Properties
    {
        _BaseColor ("BaseColor", Color) = (1,1,1,1)
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
            #include "../../../MyCommon/My_Common.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 positionWS   : TEXCOORD8;
            };

            float4 _BaseColor;

            Varyings vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                return o;
            }

            float4 frag(Varyings i) : SV_Target
            {
                float4 centerPos = unity_ObjectToWorld._m03_m13_m23_m33;
                if (centerPos.y < i.positionWS.y)
                    discard;

                return _BaseColor;
            }
            ENDHLSL
        }
    }
}

