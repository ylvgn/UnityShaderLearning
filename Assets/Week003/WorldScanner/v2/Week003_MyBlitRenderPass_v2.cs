using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

// https://samdriver.xyz/article/scriptable-render
public class Week003_MyBlitRenderPass_v2 : MyPostProcessBase
{
    public Material material;
    RenderTargetHandle tempTexture;

    public override void Configure(MyPostProcessRenderPass pass, CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {
        cmd.GetTemporaryRT(tempTexture.id, cameraTextureDescriptor);
    }

    public override void Execute(MyPostProcessRenderPass pass, ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (!material) return;
        CommandBuffer cmd = CommandBufferPool.Get(GetType().Name);
        cmd.Clear();
        cmd.DrawMesh(GetFullScreenTriangleMesh("Week003_MyPostProcessBlit"), Matrix4x4.identity, material);
        cmd.Blit(this.cameraColorTarget, tempTexture.Identifier(), material, 0);
        cmd.Blit(tempTexture.Identifier(), this.cameraColorTarget);
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }

    public override void FrameCleanup(MyPostProcessRenderPass pass, CommandBuffer cmd)
    {
        cmd.ReleaseTemporaryRT(tempTexture.id);
    }
}
