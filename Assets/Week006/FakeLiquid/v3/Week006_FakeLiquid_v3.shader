// https://pastebin.com/ppbzx7mn
Shader "Unlit/Week006_FakeLiquid_v3"
{
    Properties
    {
        _MainTex        ("Texture",                     2D) = "white" {}
        _Tint           ("Tint",                     Color) = (1, 1, 1, 1)
        _FillAmount     ("FillAmount",       Range(-10,10)) = 0
        _TopColor       ("TopColor",                 Color) = (1, 1, 1, 1)
        _FoamColor      ("FoamColor",                Color) = (1, 1, 1, 1)
        _Rim            ("Rim",               Range(0,0.1)) = 0
        _RimColor       ("Rim Color",                Color) = (1, 1, 1, 1)
        _RimPower       ("Rim Power",          Range(0,10)) = 0
// debug
        [HideInInspector] _WobbleX("WobbleX", Range(-1, 1)) = 0
        [HideInInspector] _WobbleZ("WobbleZ", Range(-1, 1)) = 0
    }

    SubShader
    {
        Tags {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            //"DisableBatching" = "True"
        }

        Zwrite On
        Cull Off
        AlphaToMask On // transparency

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "../../../MyCommon/My_Common.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float  fillEdge     : TEXCOORD6;
                float3 viewDirOS    : TEXCOORD8;
                float3 normalOS     : TEXCOORD7;
            };

            float4 _TopColor;
            float4 _RimColor;
            float4 _FoamColor;
            float4 _Tint;
            float  _FillAmount;
            float  _WobbleX;
            float  _WobbleZ;
            float  _Rim;
            float  _RimPower;
            MY_TEXTURE2D(_MainTex);

            // https://answers.unity.com/questions/1076969/how-do-i-rotate-around-the-x-axis-in-a-vertex-shad.html
            float3 RotateAroundYInDegrees(float4 vertex, float degrees)
            {
                float alpha = degrees * PI / 180;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                //float2x2 m = float2x2(cosa, sina, -sina, cosa);
                //return float4(vertex.yz, mul(m, vertex.xz)).xzy;

                float2x2 m = float2x2(cosa, -sina, sina, cosa); // https://en.wikipedia.org/wiki/Rotation_matrix
                return float3(mul(m, vertex.xz), vertex.y).xzy;
            }

            Varyings vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);

                float3 worldPos = TransformObjectToWorld(i.positionOS.xyz);
                float3 worldPosX = RotateAroundYInDegrees(float4(worldPos, 0), 360);
                // rotate around XZ
                float3 worldPosZ = float3 (worldPosX.y, worldPosX.z, worldPosX.x);
                // combine rotations with worldPos, based on sine wave from script
                float3 worldPosAdjusted = worldPos + (worldPosX * _WobbleX) + (worldPosZ * _WobbleZ);
                // how high up the liquid is
                o.fillEdge = worldPosAdjusted.y + _FillAmount;

                float3 cameraPosOS = mul((float3x3)unity_WorldToObject, _WorldSpaceCameraPos); // world space -> object space
                o.viewDirOS = (cameraPosOS - i.positionOS.xyz);
                o.normalOS = i.normalOS;
                o.uv = i.uv;
                return o;
            }

            float4 frag(Varyings i, float facing : VFACE) : SV_Target
            {
                float4 col = _Tint * MY_SAMPLE_TEXTURE2D(_MainTex, i.uv);

                // rim light
                float dotProduct = 1 - pow(dot(normalize(i.normalOS), normalize(i.viewDirOS)), _RimPower);
                float4 rimColor = _RimColor * smoothstep(0.5, 1.0, dotProduct);

                // foam edge
                float4 foam = step(i.fillEdge, 0.5) - step(i.fillEdge, (0.5 - _Rim));
                float4 foamColored = foam * (_FoamColor * 0.9);
                //return foamColored;

                // rest of the liquid
                float4 result = step(i.fillEdge, 0.5) - foam;
                float4 resultColored = result * col;
                //return resultColored;

                // both together, with the texture
                float4 finalResult = resultColored + foamColored;
                finalResult.rgb += rimColor;

                // color of backfaces/ top
                float4 topColor = _TopColor * (foam + result);

                //VFACE returns positive for front facing, negative for backfacing
                return facing > 0 ? finalResult : topColor;
            }
            ENDHLSL
        }
    }
}

