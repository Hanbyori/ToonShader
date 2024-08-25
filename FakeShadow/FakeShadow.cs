using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FakeShadow : ScriptableRendererFeature
{
    [System.Serializable]
    public class Setting
    {
        public Color color;
        [Range(-1f, 1f)] public float offsetX = 0;
        [Range(-1f, 1f)] public float offsetY = 0;
        [Range(-1f, 1f)] public float offsetZ = 0;
        [Range(0, 255)] public int stencilReference = 1;
        public CompareFunction stencilComparison;
        public RenderPassEvent passEvent = RenderPassEvent.BeforeRenderingTransparents;
        public LayerMask hairLayer;
        [Range(1000, 5000)] public int queueMin = 2000;

        [Range(1000, 5000)] public int queueMax = 3000;
        public Material material;

    }
    public Setting setting = new Setting();
    class CustomRenderPass : ScriptableRenderPass
    {
        public ShaderTagId shaderTag = new ShaderTagId("UniversalForward");
        public Setting setting;

        FilteringSettings filtering;
        public CustomRenderPass(Setting setting)
        {
            this.setting = setting;

            RenderQueueRange queue = new RenderQueueRange();
            queue.lowerBound = Mathf.Min(setting.queueMax, setting.queueMin);
            queue.upperBound = Mathf.Max(setting.queueMax, setting.queueMin);
            filtering = new FilteringSettings(queue, setting.hairLayer);
        }
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            setting.material.SetColor("_Color", setting.color);
            setting.material.SetInt("_StencilRef", setting.stencilReference);
            setting.material.SetInt("_StencilComp", (int)setting.stencilComparison);
            setting.material.SetVector("_Offset", new Vector3(setting.offsetX, setting.offsetY, setting.offsetZ));
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var draw = CreateDrawingSettings(shaderTag, ref renderingData, renderingData.cameraData.defaultOpaqueSortFlags);
            draw.overrideMaterial = setting.material;
            draw.overrideMaterialPassIndex = 0;

            Vector3 offset = new Vector3(setting.offsetX, setting.offsetY, setting.offsetZ);
            setting.material.SetVector("_Offset", offset);

            CommandBuffer cmd = CommandBufferPool.Get("FakeShadow");
            context.ExecuteCommandBuffer(cmd);
            context.DrawRenderers(renderingData.cullResults, ref draw, ref filtering);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {

        }
    }

    CustomRenderPass m_ScriptablePass;

    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass(setting);

        m_ScriptablePass.renderPassEvent = setting.passEvent;
    }
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (setting.material != null)
            renderer.EnqueuePass(m_ScriptablePass);
    }
}
