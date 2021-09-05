using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[ExecuteInEditMode]
public class Week004_LambertLightingSample : MonoBehaviour
{
    public Light m_light;
    public Material mat;

    void Update()
    {
        if (!mat) return;
        if (m_light == null) return;
        if (!m_light.isActiveAndEnabled) return;
        var position = m_light.transform.position;
        var color = m_light.color;
        mat.SetVector($"MY_LIGHT_POSITION", new Vector4(position.x, position.y, position.z, 1));
        mat.SetVector($"MY_LIGHT_COLOR", color);
    }
}
