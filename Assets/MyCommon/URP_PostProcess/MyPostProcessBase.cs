using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[ExecuteInEditMode]
public class MyPostProcessBase : MonoBehaviour
{
    public RenderPassEvent renderPassEvent;
    public RenderTargetIdentifier cameraColorTarget;
    public RenderTargetIdentifier cameraDepthTarget;
    static Mesh fullScreenTriangle;

    public virtual void OnEnable()
    {
        MyPostProcessManager.Instance.Register(this);
    }

    public virtual void OnDisable()
    {
        MyPostProcessManager.Instance.Unregister(this);
    }

    public virtual void Configure(MyPostProcessRenderPass pass, CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {
    }

    public virtual void Execute(MyPostProcessRenderPass pass, ScriptableRenderContext context, ref RenderingData renderingData)
    {
    }

    public virtual void FrameCleanup(MyPostProcessRenderPass pass, CommandBuffer cmd)
    {
    }

    static public Mesh GetFullScreenTriangleMesh(string name = "Week004" )
    {
        if (!fullScreenTriangle)
        {
            /*
             
         (-1,1) _________(1,1)
                |       |
                |  NDC  |
                |_______|
          (-1,-1)       (1, -1)
                   ¡ý

             (-1, 3)
                *
                | \
                |    \
                |       \
                |          \
                *------------*             
            (-1, -1)       (3, -1)
             */
            fullScreenTriangle = new Mesh()
            {
                name = name,
                vertices = new Vector3[] {
                    new Vector3(-1, -1, 0),
                    new Vector3( 3, -1, 0),
                    new Vector3(-1,  3, 0),
                },
                triangles = new int[] { 0, 1, 2 }
            };
            fullScreenTriangle.UploadMeshData(true);
        }

        return fullScreenTriangle;
    }
}
