using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Week002_VertexDissolve_v2 : MonoBehaviour
{
    public Material mat;
    public int group = 4;

    void OnEnable()
    {
        if (mat)
            mat.SetFloat("_MyTime", 0f);
    }

    void Start()
    {
        var mf         = GetComponent<MeshFilter>();
        var sharedMesh = mf.sharedMesh;
        var triangles  = sharedMesh.triangles;
        var vertices   = sharedMesh.vertices;
        var uv         = sharedMesh.uv;

        int[] newTriangle     = new int[triangles.Length];
        Vector2[] newUvs      = new Vector2[triangles.Length];
        Vector3[] newVertices = new Vector3[triangles.Length];
        Vector4[] newUv2s     = new Vector4[triangles.Length];

        for (int i = 0; i < triangles.Length; i+=3)
        {
            newVertices[i]     = vertices[triangles[i    ]];
            newVertices[i + 1] = vertices[triangles[i + 1]];
            newVertices[i + 2] = vertices[triangles[i + 2]];

            Vector3 center = (newVertices[i] + newVertices[i + 1] + newVertices[i + 2]) / 3.0f;
            float groupId = Random.Range(0, group) / (float)group;
            Vector4 t = new Vector4(center.x, center.y, center.z, groupId);
            newUv2s[i    ] = t;
            newUv2s[i + 1] = t;
            newUv2s[i + 2] = t;
        }

        for (int i = 0; i < triangles.Length; i ++)
        {
            newTriangle[i] = i;
            var indice = triangles[i];
            newUvs[i] = uv[indice];
        }

        var newMesh = new Mesh();
        newMesh.SetVertices(newVertices);
        newMesh.SetUVs(0, newUvs);
        newMesh.SetUVs(1, newUv2s);
        newMesh.SetIndices(newTriangle, MeshTopology.Triangles, 0);
        mf.mesh = newMesh;
    }

    void Update()
    {
        if (mat)
            mat.SetFloat("_MyTime", Time.time);
    }

    private void OnDisable()
    {
        if (mat)
            mat.SetFloat("_MyTime", 0f);
    }
}
