Shader "Unlit/Week006_FakeLiquid_v2"
{
    Properties
    {
        _Color1("Color1",        Color) = (1,1,1,1)
        _Color2("Color2",        Color) = (1,1,1,1)
        _Height("Height", Range(-5, 5)) = 0
    }

    SubShader
    {
        Tags {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }

        Cull Off

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

            float4 _Color1;
            float4 _Color2;
            float  _Height;

            Varyings vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                return o;
            }

            float4 frag(Varyings i, float facing : VFACE) : SV_Target
            {
                float4 centerPos = unity_ObjectToWorld._m03_m13_m23_m33;
                float3 worldPos = i.positionWS;

                worldPos.y -= _Height;

                if (centerPos.y < worldPos.y) {
                    discard;
                }

                return lerp(_Color2, _Color1, facing);
            }
            ENDHLSL
        }
    }
}