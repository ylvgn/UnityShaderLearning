using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Week006_FakeLiquid_v4 : MonoBehaviour
{
    public Material material;
    public Vector4 _Plane;

    Vector3 lastPos;

    void Start()
    {
        Application.targetFrameRate = 30;
    }

    void Update()
    {
        if (!material) return;

        _Plane = lastPos + transform.up;

        material.SetVector("_Plane", _Plane);
        lastPos = transform.position;
    }
}
