using UnityEngine;
using UnityEngine.Rendering.Universal;

// https://samdriver.xyz/article/scriptable-render
public class MyBlitFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class MyFeatureSettings
    {
        public bool IsEnabled = true;
        public RenderPassEvent WhenToInsert = RenderPassEvent.AfterRendering;
        public Material MaterialToBlit;
    }

    public MyFeatureSettings settings = new MyFeatureSettings();
    RenderTargetHandle renderTextureHandle;
    MyBlitRenderPass myRenderPass;

    public override void Create()
    {
        myRenderPass = new MyBlitRenderPass(
            "Week003_WorldScanner",
            settings.WhenToInsert,
            settings.MaterialToBlit
        );
    }
  
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (!settings.IsEnabled)
            return;

        var cameraColorTargetIdent = renderer.cameraColorTarget;
        myRenderPass.Setup(cameraColorTargetIdent);
        renderer.EnqueuePass(myRenderPass);
    }
}
