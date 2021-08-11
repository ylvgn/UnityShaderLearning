using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Week002_VertexDissolve : MonoBehaviour
{
    public Material mat;

    [Range(0.1f, 2f)]
    public float speed = 0.5f;

    void Start()
    {
        Mesh omesh = GetComponent<MeshFilter>().sharedMesh;
        var vertices = omesh.vertices;
        var triangles = omesh.triangles;
        var normals = omesh.normals;
        var uv = omesh.uv;

        List<int> myTriangles = new List<int>();
        List<Vector3> myVertices = new List<Vector3>(vertices);
        List<Vector3> myNormals = new List<Vector3>(normals);
        List<Vector2> myUVs = new List<Vector2>(uv);
        HashSet<int> st = new HashSet<int>();
        int id = vertices.Length;
        var s = "";
        for (int i = 0; i < triangles.Length; i++)
        {
            var indice = triangles[i];
            var vertex = vertices[indice];
            var normal = normals[indice];
            var _uv = uv[indice];

            if (st.Contains(indice))
            {
                myTriangles.Add(id);
                myNormals.Add(normal);
                myVertices.Add(vertex);
                myUVs.Add(_uv);
                id++;
            } else
            {
                st.Add(indice);
                myTriangles.Add(indice);
            }

            // debug
            /*
            if (i == 0 || i % 3 != 0)
            {
                s += $"{indice},";
            }
            else
            {
                s = s + $"\n{indice},";
            }
            */
        }
        // debug
        /*
        Debug.Log($"origin=\n{s}");
        s = "";
        for (int i = 0; i < myTriangles.Count; i++)
        {
            var indice = myTriangles[i];
            if (i == 0 || i % 3 != 0)
            {
                s += $"{indice},";
            }
            else
            {
                s = s + $"-->{(i - 1) / 3}\n{indice},";
            }
        }
        Debug.Log($"now=\n{s}" + "-->" + (myTriangles.Count) / 3);
        */

        Mesh myMesh = new Mesh();
        Color[] myColors = new Color[myVertices.Count];
        for (int i = 0; i < myTriangles.Count; i += 3)
        {
            var noise = Random.Range(0.1f, 0.9f);
            Vector3 center = Vector3.zero;
            for (int j = 0; j < 3; j ++)
            {
                var indice = myTriangles[i + j];
                var vertex = myVertices[indice];
                center += vertex;
            }
            center = center / 3.0f;
            for (int j = 0; j < 3; j++)
            {
                var indice = myTriangles[i + j];
                myColors[indice] = new Color(center.x, center.y, center.z, noise);
            }
        }

        myMesh.vertices = myVertices.ToArray();
        myMesh.triangles = myTriangles.ToArray();
        myMesh.normals = myNormals.ToArray();
        myMesh.uv = myUVs.ToArray();
        myMesh.colors = myColors;
        GetComponent<MeshFilter>().mesh = myMesh;

        if (mat)
        {
            mat.SetFloat("_DissolveSpeed", speed);
        }
    }

    private void OnDisable()
    {
        if (mat)
        {
            mat.SetFloat("_DissolveSpeed", 0f);
        }
    }
}
