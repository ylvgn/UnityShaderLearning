using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class MyPostProcessRendererFeature : ScriptableRendererFeature
{
    public override void Create()
    {
        //throw new System.NotImplementedException();
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        //Debug.Log("MyPostProcessRendererFeature");
        var mgr = MyPostProcessManager.Instance;
        if (mgr == null) return;
        mgr.AddRenderPasses(renderer, ref renderingData);
    }
}

public class MyPostProcessManager
{
    static MyPostProcessManager m_instance;
    Dictionary<MyPostProcessBase, MyPostProcessRenderPass> m_passes = new Dictionary<MyPostProcessBase, MyPostProcessRenderPass>();
    
    public delegate void OnAddRenderPassesDelegate (ScriptableRenderer renderer, ref RenderingData renderingData);
    public event OnAddRenderPassesDelegate OnAddRenderPasses;

    public static MyPostProcessManager Instance {
        get {
            if (m_instance == null) {
                m_instance = new MyPostProcessManager();
            }
            return m_instance;
        }
    }

    // custom component base on MyPostProcessBase
    public void Register(MyPostProcessBase myPostProcessBase)
    {
        m_passes.Add(myPostProcessBase, new MyPostProcessRenderPass(myPostProcessBase));
    }

    public void Unregister(MyPostProcessBase myPostProcessBase)
    {
        if (m_passes.ContainsKey(myPostProcessBase))
            m_passes.Remove(myPostProcessBase);
    }

    public void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        foreach (var t in m_passes)
        {
            MyPostProcessBase myPostProcessBase = t.Key;
            MyPostProcessRenderPass pass = t.Value;
            if (!myPostProcessBase || pass == null)
                continue;

            pass.renderPassEvent = myPostProcessBase.renderPassEvent;
            myPostProcessBase.cameraColorTarget = renderer.cameraColorTarget;
            myPostProcessBase.cameraDepthTarget = renderer.cameraDepthTarget;
            renderer.EnqueuePass(pass);
        }

        if (OnAddRenderPasses != null)
            OnAddRenderPasses(renderer, ref renderingData);
    }
}

public class MyPostProcessRenderPass : ScriptableRenderPass
{
    MyPostProcessBase m_myPostProcessBase;

    public MyPostProcessRenderPass(MyPostProcessBase myPostProcessBase)
    {
        m_myPostProcessBase = myPostProcessBase;
    }

    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {
        if (m_myPostProcessBase != null)
            m_myPostProcessBase.Configure(this, cmd, cameraTextureDescriptor);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (m_myPostProcessBase != null)
            m_myPostProcessBase.Execute(this, context, ref renderingData);
    }

    public override void FrameCleanup(CommandBuffer cmd)
    {
        if (m_myPostProcessBase != null)
            m_myPostProcessBase.FrameCleanup(this, cmd);
    }
}
