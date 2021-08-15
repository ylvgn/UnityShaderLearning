Shader "Unlit/Week002_VertexDissolve_v2"
{
    Properties
    {
        //_MyTime("MyTime", float) = 0
        _MainTex ("Texture", 2D) = "white" {}
        _Spread ("Spread", float) = 0
        _Scale ("Scale", float) = 0
        _Offset ("Offset", float) = 0
        _Duration ("Duration", float) = 1
        _Delay ("Delay", float) = 0
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
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 uv2 : TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Spread;
            float _Scale;
            float _Offset;
            float _MyTime;
            float _Delay;
            float _Duration;

            v2f vert (appdata v)
            {
                v2f o;
                float3 center = v.uv2.xyz;
                float groupId = v.uv2.w;

                float intensity = saturate((groupId + _MyTime - _Delay - 1) / _Duration);
                float scale = _Scale * intensity;
                v.vertex.xyz = lerp(v.vertex.xyz, center, scale);

                float4 worldPos = mul(UNITY_MATRIX_M, v.vertex);
                float4 objWorldPos = unity_ObjectToWorld._m03_m13_m23_m33;

                float2 xz = intensity * (worldPos.xz - objWorldPos.xz) * _Spread;
                float2 y = intensity * _Offset;
                worldPos.xz += xz;
                worldPos.y += y * y;

                o.vertex = mul(UNITY_MATRIX_VP, worldPos);
                //o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
