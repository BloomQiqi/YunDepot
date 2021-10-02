using UnityEngine;
using UnityEngine.Rendering;

public class CustomRenderPipeline : RenderPipeline
{
    public CustomRenderPipeline()
    {
        GraphicsSettings.useScriptableRenderPipelineBatching = true;//启用SRP Batch
    }

    CameraRenderer renderer = new CameraRenderer();
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        //后续可支持多相机使用不同的Renderer
        foreach(var camera in cameras)
        {
            renderer.Render(context, camera);
        }
    }
}