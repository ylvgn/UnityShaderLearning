Shader "Unlit/Week004_ShadowMapCast"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 pos : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float depth : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.pos);
                float d = o.pos.z / o.pos.w;

                if (UNITY_NEAR_CLIP_VALUE == -1) {
                    d = d * 0.5 + 0.5;
                }

                #if UNITY_REVERSED_Z
                    d = 1 - d;
                #endif
                o.depth = d;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float depth = i.depth;
                return float4(depth, 0, 0, 1);
            }
            ENDCG
        }
    }
}
