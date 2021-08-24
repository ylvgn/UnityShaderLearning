Shader "Unlit/Week004_ShaderMap"
{
    Properties
    {
        shadowBias("shadowBias", Range(0.1, 1)) = 0.1
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vs_main
            #pragma fragment ps_main
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 pos : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 normal : NORMAL;
                float4 shadowPos : TEXCOORD0;
                float3 wpos : TEXCOORD1;
            };

            float shadowBias;
            float4x4 MY_SHADOW_VP;
            sampler2D MY_SHADOW_MAP;
            float3 MY_LIGHT_DIR;

            v2f vs_main (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.pos);
                float4 wpos = mul(unity_ObjectToWorld, v.pos);
                o.normal = mul((float3x3)unity_ObjectToWorld, v.normal);
                o.shadowPos = mul(MY_SHADOW_VP, wpos);
                o.shadowPos.xyz /= o.shadowPos.w;
                o.wpos = wpos;
                return o;
            }

            float4 shadow_map(v2f i) {
                float4 shadowPos = i.shadowPos;
                float3 uv = shadowPos.xyz * 0.5 + 0.5; // [0, 1]
                float d = uv.z;
                d -= shadowBias;
                float depth = tex2D(MY_SHADOW_MAP, uv.xy).r;
                return lerp(0, d, step(d, depth));
            }

            float4 ps_main(v2f i) : SV_Target
            {
                float4 o = shadow_map(i);
                o.a = 1;
                return o;
            }
            ENDCG
        }
    }
}
