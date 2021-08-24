using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Week004_ProjectShadow : MonoBehaviour
{
    private Camera cam;
    public Shader shader;
    public RenderTexture shadowMap;

    void Start()
    {
        Application.targetFrameRate = 60;
        cam = GetComponent<Camera>();
    }

    void Update()
    {
        if (!cam) return;
        if (!shader) return;
        if (!shadowMap) return;
        Shader.SetGlobalMatrix("MY_SHADOW_VP", cam.projectionMatrix * cam.worldToCameraMatrix);
        Shader.SetGlobalVector("MY_LIGHT_DIR", transform.forward);
        Shader.SetGlobalTexture("MY_SHADOW_MAP", shadowMap);
        cam.targetTexture = shadowMap;
        cam.SetReplacementShader(shader, null);
    }
}
