Shader "Unlit/Week1_Dissolve_v5"
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

                    flow dir : c2 -> softLeft -> edgeColor -> softRight -> c1
                    ==============================================================================================================
                    ԭ��:

                            [     W + S     ]               [     W + S     ]
                            |               |               |               |
                            |               |               |               |
                            |               |_______________|               |
                            ��   ��   ��   ��   0               1   ��   ��   ��   ��
                            ��   ��   ��   ��   ��               ��   ��   ��   ��   ��
                           D-W  ��   C   ��   D             D'-W  ��   C'  ��   D'
                                ��       ��                       ��       ��
                              C-W/2   C+W/2                   C'-W/2  C'+W/2
                            [   ][     ][   ]
                              ��           ��
                          softLeft    softRight

                    ==============================================================================================================
                    ��ʼ:

                            [    W + S     ]               [     W + S     ]
                            |   |      |   |               |               |
                     c2     |   | edge |   |      c1       |               |
                            |   |      |   |_______________|               |
                            |   |      |   |
                   mix(c2, edge)|      |mix(edge, c1)
                            | �� |      | �� |
                            [   ]      [   ]
                              ��          ��
                           softLeft   softRight

                ����, mix��ʽʹ��'smoothstep'
                    ���: float tLeft = smoothstep(D-W, C-W/2, from the color of noise texture 'r'):
                    �ұ�: float tRight = smoothstep(C+W/2, max, from the color of noise texture 'r'):
                
                ���mix��Ч���ǿ���c2��ǳɫedge, ����edge����ɫedge���ұ�ͬ����edge��ɫedge������c1ǳɫedge��
                Ȼ��ע��mix�ķ���
                    1. softLeft:  c2��edge��ߣ���c2Ҫ����0, ����lerp(c2, edge, tLeft)
                    2. softRight: c1��edge�ұ�, ��c1Ҫ����1������lerp(edge, c1, tRight)

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
                float maxWidth = dissolve;  // Equivalent to: center + widthOver2
                
                // ��softʱ�� ֱ���� Week_Dissolve_v3.shader
                if (_EdgeSoftness == 0) {
                    float t1 = step(w, dissolve);
                    float4 o1 = lerp(c1, _EdgeColor, t1);
                    float t2 = step(w, dissolve - width);
                    float4 o2 = lerp(o1, c2, t2);
                    return o2;
                }

                // �� Week_Dissolve_v2.shader �Ľ�һ������
                float t3 = smoothstep(minWidth, center - edgeWidthOver2, w); // softLeft
                float t4 = smoothstep(center + edgeWidthOver2, maxWidth, w); // softRight
                float4 o3 = lerp(c2, _EdgeColor, t3);
                float4 o4 = lerp(_EdgeColor, c1, t4); // Equivalent to: lerp(c1, _EdgeColor, 1 - t4);
                return lerp(o3, o4, t3); // Equivalent to lerp(o3, o4, t4);
            }
            ENDCG
        }
    }
}
