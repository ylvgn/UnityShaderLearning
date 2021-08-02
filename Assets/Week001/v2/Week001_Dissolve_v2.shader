Shader "Unlit/Week001_Dissolve_v2"
{
    Properties
    {
        _Texture1("Texture1", 2D) = "white" {}
        _Texture2("Texture2", 2D) = "white" {}
        _Mask("Mask", 2D) = "white" {}
        _Dissolve("Dissolve", range(0, 1)) = 0
        _EdgeSoftness("EdgeSoftness", range(0, 1)) = 0
        _EdgeColor("EdgeColor", Color) = (1, 0, 0, 1)
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _Texture1;
            sampler2D _Texture2;
            sampler2D _Mask;
            float _Dissolve;
            float4 _EdgeColor;
            float _EdgeSoftness;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float4 c1 = tex2D(_Texture1, uv);
                float4 c2 = tex2D(_Texture2, uv);
                float w = tex2D(_Mask, uv);


                float len = 1 + _EdgeSoftness;
                float edgeSoftnessOver2 = _EdgeSoftness * 0.5f;
                float cur = _Dissolve * len;                             // [0                , 1 + _EdgeSoftness ]
                float center = cur - edgeSoftnessOver2;                  // [-_EdgeSoftness/2 , 1 +_EdgeSoftness/2]
                float minEdgeWidth = center - edgeSoftnessOver2;         // [-_EdgeSoftness   , 1                 ]
                float maxEdgeWidth = center + edgeSoftnessOver2;         // [0                , 1 +_EdgeSoftness  ]

                // smoothstep(min, max, x) : https://docs.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-smoothstep
                // x <= min      -> 0
                // x >= max      -> 1
                // min < x < max -> 0 ~ 1
                float t1 = smoothstep(minEdgeWidth, maxEdgeWidth, w);
                float4 o1 = lerp(_EdgeColor, c1, t1);
                float4 o2 = lerp(c2, _EdgeColor, t1);
                return lerp(o2, o1, t1);
            }
            ENDCG
        }
    }
}
