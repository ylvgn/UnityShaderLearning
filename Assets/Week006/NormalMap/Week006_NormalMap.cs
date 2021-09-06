using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Week006_NormalMap : MonoBehaviour
{
    public class PhongLighting
    {
        const int k_MaxLightCount = 8;

        List<Vector4> m_LightPos    = new List<Vector4>();
        List<Vector4> m_LightColor  = new List<Vector4>();
        List<Vector4> m_LightDir    = new List<Vector4>();
        List<Vector4> m_LightParams = new List<Vector4>();

        public void Update()
        {
            var lights = Object.FindObjectsOfType<Light>();
            if (lights.Length == 0) return;

            m_LightPos.Clear();
            m_LightColor.Clear();
            m_LightDir.Clear();
            m_LightParams.Clear();

            foreach (Light light in lights)
            {
                Vector4 lightPos = light.transform.position; // world position
                Vector4 lightDir = light.transform.forward;
                Vector4 lightColor = light.color;            // float3 lightColor.xyz because light has no alpha
                Vector4 lightParams = Vector4.zero;

                lightDir.w = 0;
                lightColor.w = light.intensity;
                lightPos.w = 1;

                if (light.type == LightType.Directional)
                {
                    lightDir.w = 1;
                }
                else if (light.type == LightType.Spot)
                {
                    lightParams.x = 1;
                    lightParams.y = Mathf.Cos(light.spotAngle * 0.5f * Mathf.Deg2Rad);
                    lightParams.z = Mathf.Cos(light.innerSpotAngle * 0.5f * Mathf.Deg2Rad);
                }
                lightParams.w = light.range;

                m_LightPos.Add(lightPos);
                m_LightDir.Add(lightDir);
                m_LightColor.Add(lightColor);
                m_LightParams.Add(lightParams);
            }

            for (int i = lights.Length; i < k_MaxLightCount; i++)
            {
                m_LightPos.Add(Vector4.zero);
                m_LightDir.Add(Vector4.zero);
                m_LightColor.Add(Vector4.zero);
                m_LightParams.Add(Vector4.zero);
            }

            Shader.SetGlobalInt("g_LightCount", lights.Length);
            Shader.SetGlobalVectorArray("g_LightPos", m_LightPos);
            Shader.SetGlobalVectorArray("g_LightDir", m_LightDir);
            Shader.SetGlobalVectorArray("g_LightColor", m_LightColor);
            Shader.SetGlobalVectorArray("g_LightParams", m_LightParams);
        }
    }

    PhongLighting phongLighting;
    void Start()
    {
        Application.targetFrameRate = 30;
        phongLighting = new PhongLighting();
    }

    void Update()
    {
        phongLighting.Update();
    }
}
