using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

// enum for 'Week003_WorldScanner_v3.shader'
public enum Week003_WorldScanner_v3
{
    Zero = 0,
    One = 1,
    Two = 2,
};

public class Week003_MyBlitRenderPass_v3 : MyPostProcessBase
{
    public Material material;

    public override void Execute(MyPostProcessRenderPass pass, ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (!material) return;
        CommandBuffer cmd = CommandBufferPool.Get(GetType().Name);
        cmd.Clear();
        cmd.DrawMesh(GetFullScreenTriangleMesh("Week003_MyBlitRenderPass_v3"), Matrix4x4.identity, material); // just use last cameraColorTarget
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }
}
