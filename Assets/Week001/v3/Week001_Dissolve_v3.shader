Shader "Unlit/Week001_Dissolve_v3"
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
                    Start:
                                                 [    W    ]            [    W    ]
                                                 |         |            |         |
                                        c2       |edgeColor|     c1     |         |
                                                 |         |____________|         |
                                               D-W         D            D'       D'-W
                                                           0            1
                    ==============================================================================================================
                    End:
                                                 [    W    ]            [    W    ]
                                                 |         |            |         |
                                                 |         |     c2     |edgeColor|       c1
                                                 |         |____________|         |
                                               D-W         D            D'       D'-W
                                                           0            1
                */
                float len = 1 + _EdgeWidth;
                float dissolve = _Dissolve * len; // dissolve : [0, 1 + _EdgeWidth]

                // step(w, dissolve) -> w <= D? _EdgeColor : c1
                // when w == D, it means this pixel need to dissolve, so we use _EdgeColor.
                float t1 = step(w, dissolve);
                float4 o = lerp(c1, _EdgeColor, t1);

                // cause w is [0, 1], and dissolve is [0, 1 + _EdgeWidth], so right-hand is 'dissolve - _EdgeWidth'
                float t2 = step(w, dissolve - _EdgeWidth);
                return lerp(o, c2, t2);
            }
            ENDCG
        }
    }
}
