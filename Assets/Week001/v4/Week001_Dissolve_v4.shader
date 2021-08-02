Shader "Unlit/Week001_Dissolve_v4"
{
    Properties
    {
        _Texture1("Texture1", 2D) = "white" {}
        _Mask("Mask", 2D) = "white" {}
        _Dissolve("Dissolve", range(0, 1)) = 0
        _EdgeWidth("EdgeWidth", range(0, 1)) = 0
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
                float w = tex2D(_Mask, uv);
                
                //flow dir : discard -> edgeColor -> c1------->

                float len = 1 + _EdgeWidth;
                float dissolve = _Dissolve * len;

                float t1 = step(w, dissolve);              // w <= D? _EdgeColor : c1
                float4 o = lerp(c1, _EdgeColor, t1);

                float t2 = step(w, dissolve - _EdgeWidth); // w <= D - W? discard : o(c1 or _EdgeColor)

                // clip: https://docs.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-clip
                clip(t2? -1 : 1);
                
                /*
                    Equivalent to
                    if (t2 == 1) {
                        discard;
                    }
                */
                return o;
            }
            ENDCG
        }
    }
}
