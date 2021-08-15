using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Week002_Trail_v1 : MonoBehaviour
{
    public struct Point
    {
        public Vector3 position;
        public Vector3 up;
        public Vector3 forward;
        public Vector3 right;

        public Point(Transform t)
        {
            position = t.position;
            up = t.up;
            forward = t.forward;
            right = t.right;
        }
    }

    public static int POINT_COUNT = 5;

    [Range(0f, 5f)]
    public float trialWidth = 1f;

    private List<Point> points;
    Vector3[] vertices;
    int[] triangles;
    int triangleNum;

    private static int GROUP = 3;
    private int index = 0;
    private float lastTime;

    [Header("Debug")]
    [Range(0.01f, 0.1f)]
    public float trialVertexRadius = 0.01f;
    public Color trialVertexColor = Color.red;
    public Color fontColor = Color.white;
    [Range(5, 10)]
    public int fontSize = 8;
    [Range(10f, 100f)]
    public float debugRange = 100f;

    void Start()
    {
        lastTime = Time.realtimeSinceStartup;
        points = new List<Point>(POINT_COUNT);
        for (int i = 0; i < POINT_COUNT; i ++)
        {
            points.Add(new Point {
                position = transform.position,
                up = transform.up,
                forward = transform.forward,
            });
        }

        triangleNum = (GROUP - 2) * 2 + 2;
        vertices = new Vector3[POINT_COUNT * GROUP];
        triangles = new int[3 * (POINT_COUNT - 1) * triangleNum];
    }

    void Update()
    {
        if (Vector3.Magnitude(transform.position) > debugRange) {
            return;
        }

        float now = Time.realtimeSinceStartup;
        if (now - lastTime < 0.05f) {
            return;
        }
        lastTime = now;

        points[index] = new Point(transform);
        index = (index + 1) % POINT_COUNT;

        createMesh();
    }

    Mesh createMesh()
    {
        Mesh mesh = new Mesh();

        for (int i = 0, j = index; i < POINT_COUNT; i++)
        {
            var point = points[j];
            var position = point.position;
            var right = point.right;
            var width = right * trialWidth;

            var index = i * GROUP;
            vertices[index] = position - width;
            vertices[index + 1] = position;
            vertices[index + 2] = position + width;
            j = (j + 1) % POINT_COUNT;
        }

        for (int i = 0; i < POINT_COUNT - 1; i++)
        {
            int index = triangleNum * i * 3;
            /* clock wise
                3--4--5
                | /| /|
                0--1--2   <-- 1 group = 3 points
            */
            int n0 = i * GROUP;
            int n1 = i * GROUP + 1;
            int n2 = i * GROUP + 2;
            int n3 = (i + 1) * GROUP;
            int n4 = (i + 1) * GROUP + 1;
            int n5 = (i + 1) * GROUP + 2;
            for (int j = 0; j < GROUP; j++)
            {
                if (j == 0)
                {
                    triangles[index] = n0;
                    triangles[index + 1] = n3;
                    triangles[index + 2] = n4;
                    index += 3;
                }
                else if (j == GROUP - 1)
                {
                    triangles[index] = n1;
                    triangles[index + 1] = n5;
                    triangles[index + 2] = n2;
                    index += 3;
                }
                else
                {
                    triangles[index] = n0;
                    triangles[index + 1] = n4;
                    triangles[index + 2] = n1;

                    triangles[index + 3] = n1;
                    triangles[index + 4] = n4;
                    triangles[index + 5] = n5;
                    index += 6;
                }
            }
        }

        mesh.vertices = vertices;
        mesh.triangles = triangles;
        return mesh;
    }

    // debug
    private void OnDrawGizmos()
    {
        if (points == null || points.Count <= 0)
            return;

        // pos
        Gizmos.color = Color.white;
        for (int i = 0; i < POINT_COUNT; i++)
        {
            var point = points[i];
            var pos = point.position;
            Gizmos.DrawSphere(pos, Mathf.Max(0.1f, trialVertexRadius - 0.2f));
        }

        // vertex
        Gizmos.color = trialVertexColor;
        for (int i = 0; i < vertices.Length; i++)
        {
            var vertex = vertices[i];
            Gizmos.DrawSphere(vertex, trialVertexRadius);
            MyUtility.LogPoint(vertex, vertex.ToString(), fontColor : fontColor, fontSize : fontSize);
        }

        // triangle
        for (int i = 0; i < triangles.Length; i += 3)
        {
            var a = vertices[triangles[i]];
            var b = vertices[triangles[i + 1]];
            var c = vertices[triangles[i + 2]];
            Gizmos.color = Color.red;
            Gizmos.DrawLine(a, b);
            Gizmos.color = Color.green;
            Gizmos.DrawLine(b, c);
            Gizmos.color = Color.blue;
            Gizmos.DrawLine(c, a);

            var delta = Vector3.down;
            MyUtility.LogPoint(a - delta, triangles[i].ToString(), fontColor: fontColor, fontSize: 15);
            MyUtility.LogPoint(b - delta, triangles[i +1].ToString(), fontColor: fontColor, fontSize: 15);
            MyUtility.LogPoint(c - delta, triangles[i +2].ToString(), fontColor: fontColor, fontSize: 15);
        }
    }

}
