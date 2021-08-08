using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MyGizmos : MonoBehaviour
{
    public Color color = Color.red;
    public Vector3 scale = Vector3.one;

    public enum DrawType
    {
        Point,
        Cube,
    }

    public DrawType type = DrawType.Point;

    void OnDrawGizmos()
    {
        Gizmos.color = color;
        Gizmos.matrix = transform.localToWorldMatrix;
        switch (type)
        {
            case DrawType.Cube:
                Gizmos.DrawCube(Vector3.zero, scale);
                break;
            case DrawType.Point:
                Gizmos.DrawSphere(Vector3.zero, scale.x);
                break;
            default:
                break;
        }
    }
}
