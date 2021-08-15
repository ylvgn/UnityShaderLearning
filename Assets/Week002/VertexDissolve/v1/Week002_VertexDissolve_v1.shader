Shader "Unlit/Week002_VertexDissolve_v1"
{
    Properties
    {
        _Texture("Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _Texture;
            float _DissolveSpeed;

            v2f vert (appdata v)
            {
                v2f o;
                float2 uv = v.uv;
                float4 vertex = v.vertex;
                float4 color = v.color;
                float3 center = color.xyz;
                float noise = color.a;
                float weight = saturate(_Time.y * _DissolveSpeed);

                float upward = saturate(weight - noise) * pow(_DissolveSpeed, noise);
                vertex.xyz = lerp(vertex.xyz, center, weight);
                vertex.y += upward;
                float4 wpos = mul(UNITY_MATRIX_M, vertex);

                o.vertex = mul(UNITY_MATRIX_VP, wpos);
                o.uv = uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return tex2D(_Texture, i.uv);
            }
            ENDCG
        }
    }
}
