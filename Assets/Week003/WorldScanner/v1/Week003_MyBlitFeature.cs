using UnityEngine;
using UnityEngine.Rendering.Universal;

// https://samdriver.xyz/article/scriptable-render
// Assets/Settings/ForwardRenderer -> Render Features -> Add Renderer Feature 'Week003_MyBlitFeature'
public class Week003_MyBlitFeature : ScriptableRendererFeature
{
    Week003_MyBlitRenderPass_v1 myRenderPass;

    public MyFeatureSettings input;
    [System.Serializable]
    public class MyFeatureSettings
    {
        // we're free to put whatever we want here, public fields will be exposed in the inspector
        public bool IsEnabled = true;
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRendering;
        public Material materialToBlit;
    }

    public override void Create()
    {
        MyFeatureSettings input = new MyFeatureSettings();
        this.myRenderPass = new Week003_MyBlitRenderPass_v1(input.renderPassEvent, input.materialToBlit);
    }

    // called every frame once per camera
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (!input.IsEnabled)
            return;
        //Debug.Log("myRenderPass");

        // --> Gather up and pass any extra information our pass will need.
        // In this case we're getting the camera's color buffer target
        myRenderPass.Setup(renderer.cameraColorTarget);

        // Ask the renderer to register our pass.
        renderer.EnqueuePass(myRenderPass);
    }
}
