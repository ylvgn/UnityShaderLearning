Shader "Unlit/PlotGraph"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LineWidth ("LineWidth", range(1, 10)) = 1
        _LineColor ("LineColor", Color) = (1, 0, 0, 1)
        _Params ("Params", Vector) = (0, 0, 0, 0)
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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _LineWidth;
            float4 _LineColor;
            float4 _Params;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }


            float func(float x) {
                //return x;
                //return abs(x - _Params.x);
                //return abs(-2 * x + 1);

                /*
                float from = _Params.x;
                float to = _Params.y;
                return saturate((x - from) / (to - from));
                */

                //return smoothstep(0, 1, abs(x-0.5));
                //return smoothstep(_Params.x, _Params.y, x);
                //return 1 - smoothstep(_Params.x, _Params.y, x); // return smoothstep(_Params.y, _Params.x, x);
                //return smoothstep(0.2, 0.4, abs(x - 0.5));

                float e = abs(x - _Params.z);
                return smoothstep(min(_Params.x, _Params.y), max(_Params.x, _Params.y), e);
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 tex = tex2D(_MainTex, i.uv);
                // 左下角是原点(0,0), * 10 表示x,y都分成10份(因为图片有10x10格)
                //  -5 是 0.5 * 10, 因为先scale了所以减去的offet也要scale。将左下角原点移到中间, uv(图片)往左下方向移动等价于原点向右上方向移动.
                // 也可以写 float2 uv = (i.uv - 0.5）* 10;
                float2 uv = (i.uv * 10 - 5);
                float width = _LineWidth * ddy(uv.y); // ddy: 相邻两格pixel在y方向上的距离

                float y = func(uv.x);
                float len = abs(uv.y - y);
                float w = width / len; // 如果len很小, 表示图像的y值和图片的y值很接近, 则令 w >= 1
                return lerp(tex, _LineColor, saturate(w));
            }

            ENDCG
        }
    }
}
