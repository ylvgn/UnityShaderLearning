using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Week003_WorldScanner : MonoBehaviour
{
    public Material mat;
    Vector3 lastPos;

    private void Start()
    {
        Application.targetFrameRate = 30;
    }

    void Update()
    {
        if (!mat) return;
        var pos = transform.position;
        if (lastPos == pos) return;
        lastPos = pos;
        mat.SetVector("_ScanerCenter", new Vector4(pos.x, pos.y, pos.z, 0));
    }
}
