Shader "Unlit/Week001_Dissolve_v5"
{
    Properties
    {
        _Texture1("Texture1", 2D) = "white" {}
        _Texture2("Texture2", 2D) = "white" {}
        _Mask("Mask", 2D) = "white" {}
        _Dissolve("Dissolve", range(0, 1)) = 0
        _EdgeWidth("EdgeWidth", range(0, 1)) = 0
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
            float _EdgeWidth;
            float _EdgeSoftness;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            /*
                    > dissolve      <=> D
                    > EdgeWidth     <=> W
                    > EdgeSoftness  <=> S
                    > center        <=> C
                    > c1            <=> Texture1(Color)
                    > c2            <=> Texture2(Color)
                    > edge          <=> _EdgeColor

                    flow dir : c2 -> softLeft -> edgeColor -> softRight -> c1

                    ==============================================================================================================

                           [ <--------- W + S -----------> ]               [     W + S     ]
                           |          |        |           |               |               |
                     c2    |          |  edge  |           |      c1       |               |
                           |          |        |           |_______________|               |
                           |          |        |           0               1
                         mix(c2, edge)|        |mix(edge, c1)
                           |          |        |           |
                           [ softLeft ]    C   [ softRight ]
                         D-W        C-W/2     C+W/2        D

                    ==============================================================================================================

                use 'smoothstep' to mix 2 color
                    1. softLeft : float tLeft  = smoothstep(D - (W + S), C-W/2, noiseColor.r);
                    2. softRight: float tRight = smoothstep(C + W/2,     D,     noiseColor.r);

                how to mix:
                    1. softLeft:  c2 is to the left of edge， so c2 should be close to 0, then lerp(c2, edge, tLeft);
                    2. softRight: c1 is to the right of edge, so c1 should be close to 1，then lerp(edge, c1, tRight);
            */
            float4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float4 c1 = tex2D(_Texture1, uv);
                float4 c2 = tex2D(_Texture2, uv);
                float w = tex2D(_Mask, uv);
                
                float edgeWidthOver2 = _EdgeWidth * 0.5f;
                float edgeSoftnessOver2 = _EdgeSoftness * 0.5f;
                float widthOver2 = edgeWidthOver2 + edgeSoftnessOver2;
                float width = _EdgeWidth + _EdgeSoftness;
                float len = 1 + width;
                float dissolve = _Dissolve * len;
                float center = dissolve - widthOver2;
                float minWidth = center - widthOver2;
                float maxWidth = dissolve;  // Equivalent to center + widthOver2

                // no _EdgeSoftness, just use 'Week_Dissolve_v3.shader'
                if (_EdgeSoftness == 0) {
                    float t1 = step(w, dissolve);
                    float4 o1 = lerp(c1, _EdgeColor, t1);
                    float t2 = step(w, dissolve - width);
                    float4 o2 = lerp(o1, c2, t2);
                    return o2;
                }

                // 对 Week_Dissolve_v2.shader 嘅进一步改善
                float t3 = smoothstep(minWidth, center - edgeWidthOver2, w); // softLeft
                float t4 = smoothstep(center + edgeWidthOver2, maxWidth, w); // softRight
                float4 o3 = lerp(c2, _EdgeColor, t3);
                float4 o4 = lerp(_EdgeColor, c1, t4); // Equivalent to lerp(c1, _EdgeColor, 1 - t4);
                return lerp(o3, o4, t3);              // Equivalent to lerp(o3, o4, t4);
            }
            ENDCG
        }
    }
}
