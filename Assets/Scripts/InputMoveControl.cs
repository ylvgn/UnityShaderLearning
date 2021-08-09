using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InputMoveControl : MonoBehaviour
{
    public float speed = 10f;
    public float rotSpeed = 90f;

    void Update()
    {
        float moveDir = 0;
        float rotAmount = 0;

        if (Input.GetKey(KeyCode.W))
        {
            moveDir += 1;
        }

        if (Input.GetKey(KeyCode.S))
        {
            moveDir -= 1;
        }

        if (Input.GetKey(KeyCode.A))
        {
            rotAmount -= 1;
        }

        if (Input.GetKey(KeyCode.D))
        {
            rotAmount += 1;
        }
        var t = transform.rotation * new Vector3(0, 0, moveDir * speed * Time.fixedDeltaTime);
        var r = new Vector3(0, rotAmount * rotSpeed * Time.fixedDeltaTime, 0);
        transform.Translate(t, Space.World);
        transform.Rotate(r, Space.World);
    }
}
