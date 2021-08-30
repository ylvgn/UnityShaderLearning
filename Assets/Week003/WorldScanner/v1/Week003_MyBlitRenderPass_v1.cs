using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

// https://samdriver.xyz/article/scriptable-render
class Week003_MyBlitRenderPass_v1 : ScriptableRenderPass
{
    Material materialToBlit;
    RenderTargetIdentifier cameraColorTarget;
    RenderTargetHandle tempTexture;

    public Week003_MyBlitRenderPass_v1(RenderPassEvent renderPassEvent, Material materialToBlit)
    {
        this.renderPassEvent = renderPassEvent;
        this.materialToBlit = materialToBlit;
    }

    // This isn't part of the ScriptableRenderPass class and is our own addition.
    // For this custom pass we need the camera's color target, so that gets passed in.
    public void Setup(RenderTargetIdentifier cameraColorTarget)
    {
        this.cameraColorTarget = cameraColorTarget;
    }

    // called each frame before Execute, use it to set up things the pass will need
    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {
        cmd.GetTemporaryRT(tempTexture.id, cameraTextureDescriptor);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        // fetch a command buffer to use
        CommandBuffer cmd = CommandBufferPool.Get(GetType().Name);
        cmd.Clear();

        // the actual content of our custom render pass!
        // we apply our material while blitting to a temporary texture
        cmd.Blit(cameraColorTarget, tempTexture.Identifier(), materialToBlit, 0);

        // ...then blit it back again 
        cmd.Blit(tempTexture.Identifier(), cameraColorTarget);

        // don't forget to tell ScriptableRenderContext to actually execute the commands
        context.ExecuteCommandBuffer(cmd);

        // tidy up after ourselves
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }

    // called after Execute, use it to clean up anything allocated in Configure
    public override void FrameCleanup(CommandBuffer cmd)
    {
        cmd.ReleaseTemporaryRT(tempTexture.id);
    }
}
