Shader "Unlit/Week1_Dissolve_v3"
{
    Properties
    {
        _Texture1("Texture1", 2D) = "white" {}
        _Texture2("Texture2", 2D) = "white" {}
        _Mask("Mask", 2D) = "white" {}
        _Dissolve("Dissolve", range(0, 1)) = 0
        _EdgeWidth("EdgeWidth", range(0, 1)) = 0
        _EdgeColor("EdgeColor", Color) = (1, 0, 0, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off

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
            float _EdgeWidth;

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

                /*
                    > dissolve  <=> D
                    > EdgeWidth <=> W

                    flow dir: c2 -> edgeColor -> c1 ------->
                    ==============================================================================================================
                    原理：

                                                 [EdgeWidth]            [EdgeWidth]
                                                 |         |            |         |
                                                 |         |            |         |
                                                 |         |____________|         |
                                                 ↑         0            1         ↑
                                                 ↑         ↑            ↑         ↑
                                                D-W        D          D'-W        D'
                    ==============================================================================================================
                    初始:
                                                 [EdgeWidth]            [EdgeWidth]
                                                 |         |            |         |
                                        c2       |edgeColor|    c1      |         |
                                                 |         |____________|         |
                                                 ↑         0            1         ↑
                                                 ↑         ↑            ↑         ↑
                                                D-W        D          D'-W        D'
                    ==============================================================================================================
                    最终:
                                                 [EdgeWidth]            [EdgeWidth]
                                                 |         |            |         |
                                                 |         |    c2      |edgeColor|c1
                                                 |         |____________|         |
                                                 ↑         0            1         ↑
                                                 ↑         ↑            ↑         ↑
                                                D-W        D          D'-W        D'
                */
                float len = 1 + _EdgeWidth;
                float dissolve = _Dissolve * len;          // [0, 1 + _EdgeWidth]

                float t1 = step(w, dissolve);              // w <= D? _EdgeColor : c1 -> 当w == D的时候，意味着这里要溶解，也就需要出现edgeColor
                float4 o = lerp(c1, _EdgeColor, t1);

                float t2 = step(w, dissolve - _EdgeWidth); // w <= D - W? c2 : o(c1 or _EdgeColor), 由于w范围是[0, 1], 所以要 dissolve - _EdgeWidth
                return lerp(o, c2, t2);
            }
            ENDCG
        }
    }
}
