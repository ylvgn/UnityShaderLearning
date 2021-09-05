using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[ExecuteInEditMode]
public class Week004_StainedGlass_v1 : MonoBehaviour
{
    public Camera projectorCamera;
    public RenderTexture projColorRenderTarget;
    public RenderTexture projDepthRenderTarget;
    public Shader copyDepthShader;
    public Material material;

    MyClearOpaquePass clearOpaquePass;
    MyCopyDepthPass copyDepthPass;
    MyProjectPass projectPass;

    void Start()
    {
        Application.targetFrameRate = 30;
    }

    private void OnEnable()
    {
        clearOpaquePass = new MyClearOpaquePass(this);
        copyDepthPass   = new MyCopyDepthPass(this);
        projectPass     = new MyProjectPass(this);

        MyPostProcessManager.Instance.OnAddRenderPasses += OnAddRenderPasses;
    }

    private void OnDisable()
    {
        MyPostProcessManager.Instance.OnAddRenderPasses -= OnAddRenderPasses;
    }

    public void OnAddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (!projectorCamera) return;

        projectorCamera.targetTexture = projColorRenderTarget;
        renderer.EnqueuePass(clearOpaquePass);
        renderer.EnqueuePass(copyDepthPass);
        renderer.EnqueuePass(projectPass);
    }

    public class MyClearOpaquePass : ScriptableRenderPass
    {
        readonly Week004_StainedGlass_v1 owner;
        public MyClearOpaquePass(Week004_StainedGlass_v1 owner)
        {
            this.owner = owner;
            renderPassEvent = RenderPassEvent.AfterRenderingSkybox;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.camera != owner.projectorCamera) return;

            CommandBuffer cmd = CommandBufferPool.Get(GetType().Name);
            cmd.Clear();
            cmd.ClearRenderTarget(false, true, Color.black);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }
    }

    public class MyCopyDepthPass : ScriptableRenderPass
    {
        readonly Week004_StainedGlass_v1 owner;
        Material copyDepthMaterial;

        public MyCopyDepthPass(Week004_StainedGlass_v1 owner)
        {
            this.owner = owner;
            renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            ConfigureTarget(owner.projDepthRenderTarget);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.camera != owner.projectorCamera) return;

            CommandBuffer cmd = CommandBufferPool.Get(GetType().Name);
            cmd.Clear();

            if (!copyDepthMaterial)
            {
                copyDepthMaterial = new Material(owner.copyDepthShader);
            }

            cmd.DrawMesh(MyPostProcessBase.GetFullScreenTriangleMesh(), Matrix4x4.identity, copyDepthMaterial);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }
    }


    public class MyProjectPass : ScriptableRenderPass
    {
        readonly Week004_StainedGlass_v1 owner;

        public MyProjectPass(Week004_StainedGlass_v1 owner)
        {
            this.owner = owner;
            renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (!owner.material) return;
            if (renderingData.cameraData.camera == owner.projectorCamera) return;

            var cam = owner.projectorCamera;
            var projMatrix = GL.GetGPUProjectionMatrix(cam.projectionMatrix, false);
            var viewMatrix = cam.transform.worldToLocalMatrix;

            owner.material.SetMatrix("_MyProjVP", projMatrix * viewMatrix);
            owner.material.SetVector("_MyProjPos", cam.transform.position);
            owner.material.SetTexture("_MyProjColorTex", cam.targetTexture);
            owner.material.SetTexture("_MyProjDepthTex", owner.projDepthRenderTarget);

            CommandBuffer cmd = CommandBufferPool.Get(GetType().Name);
            cmd.Clear();
            cmd.DrawMesh(MyPostProcessBase.GetFullScreenTriangleMesh(), Matrix4x4.identity, owner.material);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }
    }
}