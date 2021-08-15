Shader "Unlit/Week001_Dissolve_v6"
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

        _PivotX ("PivotX", float) = 0.5
        _PivotY("PivotY", float) = 0.5
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
                float2 maskUv : TEXCOORD1;
            };

            void style1(v2f i);
            void style2(v2f i);
            const static float EPS = 1E-4;

            sampler2D _Texture1;
            sampler2D _Texture2;
            sampler2D _Mask;
            float4 _Mask_ST;
            float _Dissolve;
            float4 _EdgeColor;
            float _EdgeWidth;
            float _EdgeSoftness;

            float _PivotX;
            float _PivotY;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.maskUv = TRANSFORM_TEX(v.uv, _Mask);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float4 c1 = tex2D(_Texture1, uv);
                float4 c2 = tex2D(_Texture2, uv);
                float mask = 1 - tex2D(_Mask, i.maskUv).r; // change dir: black -> white
                
                /*
                float t = step(mask, _Dissolve);
                return lerp(c1, c2, t);
                */

                float hard = _EdgeWidth * 0.5f;
                float soft = hard + _EdgeSoftness + EPS;

                //style1(i);
                style2(i); // 注意有些Mask可能不能用 Tiling, (比如gradient不可以用Tiling)
                float dissolve = lerp(-soft, 1 + soft, _Dissolve); // [0, 1] -> [-soft, 1 + soft]
                //return float4(dissolve, 0, 0, 1);

                float4 o = lerp(c1, c2, step(mask, dissolve));
                //return o;

                if (_EdgeWidth || _EdgeSoftness)
                {
                    float e = abs(mask - dissolve);
                    float w = smoothstep(hard, soft, e);
                    //return float4(w, 0, 0, 1);
                    o = lerp(_EdgeColor, o, w);

                    /* 考虑边界 _Dissolve = 0 时, e > 0, w -> 1, 因此o必须放在1的位置, 所以只能按照上面的写法, 下面的写法是错误的.
                    float w = smoothstep(soft, hard, e);
                    o = lerp(o, _EdgeColor, w);
                    */
                }
                return o;
            }

             // Circle
            void style1(v2f i) {
                float2 uv = i.uv - float2(_PivotX, _PivotY);
                float len = length(uv);
                _Dissolve = saturate(_Dissolve / max(len, EPS));
            }

            // Rhombus
            void style2(v2f i) {
                float2 uv = i.uv - float2(_PivotX, _PivotY);
                float len = abs(uv.x) + abs(uv.y);
                _Dissolve = saturate(_Dissolve / max(len, EPS)); // 如果len很小 则令_Dissolve >= 1
            }

            ENDCG
        }
    }
}
