Shader "Unlit/Week003_DepthTextureSample"
{
    Properties
    {
        _Scale("Scale", float) = 10
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // HLSL files (for example, Common.hlsl, SpaceTransforms.hlsl, etc.).
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Camera depth texture.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
            };

            float _Scale;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                // to calculate the UV coordinates for sampling the depth buffer
                //In D3D, Z is in range[0, 1], in OpenGL, Z is in range[-1, 1].
                float2 UV = IN.positionHCS.xy / _ScaledScreenParams.xy;
                #if UNITY_REVERSED_Z // use different Z values for far clipping planes (0 == far, or 1 == far)
                    // D3D
                    real depth = SampleSceneDepth(UV);
                #else
                    // OpenGL
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
                #endif

                // clip space -> world space.
                float3 worldPos = ComputeWorldSpacePosition(UV, depth, UNITY_MATRIX_I_VP);
                uint3 worldIntPos = uint3(abs(worldPos.xyz * _Scale));
                bool white = (worldIntPos.x & 1) ^ (worldIntPos.y & 1) ^ (worldIntPos.z & 1);
                float4 color = lerp(float4(1, 1, 1, 1), float4(0, 0, 0, 1), white);

                // Set the color to black in the proximity to the far clipping
                #if UNITY_REVERSED_Z
                    // D3D
                    if (depth < 0.0001)
                        return half4(0, 0, 0, 1);
                #else
                    // OpenGL
                    if (depth > 0.9999)
                        return half4(0, 0, 0, 1);
                #endif
                return color;
            }
            ENDHLSL
        }
    }
}