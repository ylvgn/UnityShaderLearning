using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Week002_Trial_v3 : MonoBehaviour
{
    public struct Point
    {
        public Vector3 position;
        public Vector3 up;
        public Vector3 forward;
        public Vector3 right;

        public Point(Transform t)
        {
            position = t.localPosition;
            up = t.up;
            forward = t.forward;
            right = t.right;
        }
    }

    public static int POINT_COUNT = 8;

    [Range(0f, 5f)]
    public float trialWidth = 1f;

    private List<Point> points;
    Vector3[] vertices;
    Vector2[] UVs;
    int[] triangles;
    int triangleNum;

    private static int GROUP = 3;
    private int index = 0;
    private float lastTime;

    #region
    [Header("Debug")]
    [Range(0.01f, 0.1f)]
    public float trialVertexRadius = 0.03f;
    public Color trialVertexColor = Color.red;
    public Color fontColor = Color.white;
    [Range(5, 10)]
    public int fontSize = 8;
    [Range(10f, 100f)]
    #endregion

    public MeshFilter meshFilter;
    public Transform lookAtTarget;

    void Start()
    {
        if (!meshFilter)
        {
            Debug.LogError("meshFilter == null");
            return;
        }

        if (!lookAtTarget)
        {
            Debug.LogError("lookAtTarget == null");
            return;
        }

        lastTime = Time.realtimeSinceStartup;
        points = new List<Point>(POINT_COUNT);
        triangleNum = (GROUP - 2) * 2 + 2;

        for (int i = 0; i < POINT_COUNT; i++)
        {
            points.Add(new Point(lookAtTarget));
        }
    }

    void Update()
    {
        float now = Time.realtimeSinceStartup;
        if (now - lastTime < 0.1f) {
            return;
        }
        lastTime = now;

        points[index] = new Point(lookAtTarget);
        index = (index + 1) % POINT_COUNT;

        meshFilter.mesh = createMesh();
    }

    private Mesh createMesh()
    {
        List<Point> _points = smoothness(points);
        Debug.Log($"totle_points={_points.Count}");

        int pointCount = _points.Count;
        vertices = new Vector3[pointCount * GROUP];
        UVs = new Vector2[pointCount * GROUP];
        triangles = new int[3 * (pointCount - 1) * triangleNum];

        Mesh mesh = new Mesh();
        for (int i = 0; i < pointCount; i++)
        {
            var point = _points[i];
            var position = point.position;
            var right = point.right;
            var width = right * trialWidth;

            var k = i * GROUP;
            vertices[k] = position - width;
            vertices[k + 1] = position;
            vertices[k + 2] = position + width;

            float v = ((float)i / (float)pointCount); // tmp
            UVs[k] = new Vector2(0f, v);
            UVs[k + 1] = new Vector2(0.5f, v);
            UVs[k + 2] = new Vector2(1f, v);
        }

        for (int i = 0; i < pointCount - 1; i++)
        {
            int index = triangleNum * i * 3;
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
        mesh.uv = UVs;
        return mesh;
    }

    const float AMOUNT = 0.3333333f; // 1/3
    const float ERR_DISTANCE = 0.1f;
    List<Point> smoothness(List<Point> src)
    {
        List<Point> res = new List<Point>();
        int j = index;
        for (int i = 0; i < POINT_COUNT - 1; i ++)
        {
            var first = src[j];
            Vector3 P0 = first.position;
            Vector3 P1 = P0 + first.forward * AMOUNT;

            j = (j + 1) % POINT_COUNT;

            var second = src[j];
            Vector3 P3 = second.position;
            Vector3 P2 = P3 - second.forward * AMOUNT;

            // Add P1
            res.Add(first);

            if (Vector3.Distance(P0, P3) <= ERR_DISTANCE) continue;

            // 6 points
            for (int k = 1; k < 7; k ++)
            {
                float t = (float)k / 6f;
                var p = new Point
                {
                    right = Vector3.Lerp(first.right, second.right, t),
                    position = CubicBezierCurves(t, P0, P1, P2, P3),
                };
                res.Add(p);
            }
        }

        res.Add(src[j]);
        return res;
    }

    // Cubic Bézier curves: B(t) = (1-t)³P0 + 3(1-t)²tP1 + 3(1-t)t²P2 + t³P3, 0 <= t <= 1
    Vector3 CubicBezierCurves(float t, Vector3 P0, Vector3 P1, Vector3 P2, Vector3 P3)
    {
        float u = 1 - t;
        float uu = u * u;
        float uuu = u * uu;
        float tt = t * t;
        float ttt = tt * t;
        return (uuu * P0) + (3.0f * uu * t * P1) + (3.0f * u * tt * P2) + (ttt * P3);
    }

    // debug
    private void OnDrawGizmos()
    {
        if (points == null || points.Count <= 0)
            return;
        if (vertices == null || vertices.Length <= 0)
            return;
        if (triangles == null || triangles.Length <= 0)
            return;

        // pos
        Gizmos.color = Color.white;
        for (int i = 0; i < points.Count; i++)
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
            MyUtility.LogPoint(vertex, vertex.ToString(), fontColor: fontColor, fontSize: fontSize);
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

            var delta = Vector3.up;
            MyUtility.LogPoint(a + delta, triangles[i].ToString(), fontColor: fontColor, fontSize: 15);
            MyUtility.LogPoint(b + delta, triangles[i + 1].ToString(), fontColor: fontColor, fontSize: 15);
            MyUtility.LogPoint(c + delta, triangles[i + 2].ToString(), fontColor: fontColor, fontSize: 15);
        }
    }
}
