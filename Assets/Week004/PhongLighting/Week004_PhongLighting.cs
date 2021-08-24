using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Week004_PhongLighting : MonoBehaviour
{
    public Light[] lights;

    const int MAX_COUNT = 8;
    int MY_LIGHT_COUNT;

    Vector4[] MY_LIGHT_COLORS;
    Vector4[] MY_LIGHT_POSITION;
    Vector4[] MY_LIGHT_DIRECTIONS;
    Vector4[] MY_LIGHT_PARAMS;

    void Start()
    {
        MY_LIGHT_COLORS = new Vector4[MAX_COUNT];
        MY_LIGHT_POSITION = new Vector4[MAX_COUNT];
        MY_LIGHT_DIRECTIONS = new Vector4[MAX_COUNT];
        MY_LIGHT_PARAMS = new Vector4[MAX_COUNT];
    }

    void Update()
    {
        if (lights == null) return;
        if (lights.Length == 0) return;

        MY_LIGHT_COUNT = 0;

        for (int i = 0; i < lights.Length && i < MAX_COUNT; i ++)
        {
            var light = lights[i];
            if (light == null) continue;
            if (!light.isActiveAndEnabled) continue;

            Vector4 position = light.transform.position;
            Color color = light.color;
            Vector4 direction = light.transform.forward; // light.transform.localToWorldMatrix.GetColumn(2);

            Vector4 param = Vector4.zero;
            direction.w = 0;
            position.w = 0;

            // "UniversalRenderPipelineCore.cs" -> InitializeLightConstants_Common
            if (light.type == LightType.Directional)
            {
                position.w = 1;
            } else if (light.type == LightType.Spot)
            {
                var lightRange = light.range;
                var spotAngle = light.spotAngle;
                var innerSpotAngle = light.innerSpotAngle;
                param.x = 1;
                param.y = spotAngle * Mathf.Deg2Rad * 0.5f;
                param.z = innerSpotAngle * Mathf.Deg2Rad * 0.5f;
                param.w = lightRange;
            }

            MY_LIGHT_POSITION[MY_LIGHT_COUNT] = position;
            MY_LIGHT_DIRECTIONS[MY_LIGHT_COUNT] = direction;
            MY_LIGHT_COLORS[MY_LIGHT_COUNT] = color;
            MY_LIGHT_PARAMS[MY_LIGHT_COUNT] = param;
            MY_LIGHT_COUNT++;
        }

        // why unity Property (MY_LIGHT_COLORS) exceeds previous array size (3 vs 2). Cap to previous size ??
        if (MY_LIGHT_COUNT <= 0) return;
        Shader.SetGlobalInt("MY_LIGHT_COUNT", MY_LIGHT_COUNT);
        Shader.SetGlobalVectorArray("MY_LIGHT_POSITIONS", MY_LIGHT_POSITION);
        Shader.SetGlobalVectorArray("MY_LIGHT_DIRECTIONS", MY_LIGHT_DIRECTIONS);
        Shader.SetGlobalVectorArray("MY_LIGHT_COLORS", MY_LIGHT_COLORS);
        Shader.SetGlobalVectorArray("MY_LIGHT_PARAMS", MY_LIGHT_PARAMS);
    }
}
