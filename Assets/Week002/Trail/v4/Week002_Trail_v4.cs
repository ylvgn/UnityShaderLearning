using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
public class Week002_Trail_v4 : MonoBehaviour
{
    public struct Node
    {
        public Vector3 pos0;
        public Vector3 pos1;
        public double time;
    }

    public Transform Source;

    List<Node> Nodes;
    List<int> meshIndices;
    List<Vector3> meshVertices;
    List<Vector2> meshUV0;
    int currentNode = 0;
    double startTime;
    const int MAX_LEVEL = 8;

    public float width = 1f;
    public float duration = 2f;
    public float tolerateErrorDistance = 0.001f;

    Mesh mesh;
    MeshFilter meshFilter;

    void Start()
    {
        if (!mesh)
        {
            mesh = new Mesh() {
                name = "Trial"
            };
        }
        meshFilter = GetComponent<MeshFilter>();
        Nodes = new List<Node>();
        meshIndices = new List<int>();
        meshVertices = new List<Vector3>();
        meshUV0 = new List<Vector2>();
        startTime = Time.timeAsDouble;
    }

    void UpdateNode()
    {
        if (!Source) {
            return;
        }

        double time = Time.timeAsDouble;
        for (int i = currentNode; i < Nodes.Count; i++)
            if (Nodes[i].time + duration < time)
                currentNode = i + 1;

        if (currentNode >= Nodes.Count)
        {
            Nodes.Clear();
            currentNode = 0;
        } else
        {
            int useCount = Nodes.Count - currentNode;
            if (Nodes.Count > 32 && currentNode > useCount * 4)
            {
                Nodes.RemoveRange(0, currentNode);
                currentNode = 0;
            }
        }
        
        Node node = new Node() {
            pos0 = Source.position,
            pos1 = Source.position + Source.right * width,
            time = time,
        };

        AddNode(node);
    }

    void AddNode(Node node, int level = 0)
    {
        if (level > MAX_LEVEL) return;

        int len = Nodes.Count;
        if (len == 0)
        {
            Nodes.Add(node);
            return;
        }

        /*
                         node0
                       /     \
                     /        \(width)
                 mid0           node1
                /    \          /
               /      \      /
          last0         mid1
            \         /          
      (width)\      /          
               last1
         */
        var last = Nodes[len - 1];
        var mid0 = (last.pos0 + node.pos0) / 2.0f;
        var mid1 = (last.pos1 + node.pos1) / 2.0f;
        var dist = Vector3.Distance(mid0, mid1);
        var err = Mathf.Abs(dist - width);
        if (err < tolerateErrorDistance)
        {
            Nodes.Add(node);
            return;
        }

        var mid = new Node()
        {
            pos0 = mid0,
            pos1 = mid0 + (mid1 - mid0).normalized * width,
            time = (last.time + node.time) * 0.5f,
        };

        AddNode(mid, level + 1);
        AddNode(node, level + 1);
    }

    void UpdateMesh()
    {
        if (!meshFilter) return;
        if (Nodes.Count - currentNode <= 0) return;
        meshFilter.sharedMesh = mesh;

        meshIndices.Clear();
        meshVertices.Clear();
        meshUV0.Clear();
        mesh.SetIndices(meshIndices, MeshTopology.Triangles, 0);
        
        for (int i = currentNode; i < Nodes.Count; i ++)
        {
            var node = Nodes[i];
            float u = (float)(node.time - startTime);

            meshVertices.Add(node.pos0);
            meshVertices.Add(node.pos1);
            meshUV0.Add(new Vector2(u, 0));
            meshUV0.Add(new Vector2(u, 1));
        }

        for (int i = 0; i < meshVertices.Count - 2; i += 2)
        {
            /* not
                    2--3
                    |/ |
                    0--1
               but,           because uv for vertex
                    2--3      y
                    |\ |      ↑
                    0--1     -|--->x
            */
            meshIndices.Add(i);
            meshIndices.Add(i + 2);
            meshIndices.Add(i + 1);
            meshIndices.Add(i + 1);
            meshIndices.Add(i + 2);
            meshIndices.Add(i + 3);
        }
        mesh.SetVertices(meshVertices);
        mesh.SetUVs(0, meshUV0);
        mesh.SetIndices(meshIndices, MeshTopology.Triangles, 0);
    }

    // animation first, then c#
    void LateUpdate()
    {
        UpdateNode();
        UpdateMesh();
    }
}
