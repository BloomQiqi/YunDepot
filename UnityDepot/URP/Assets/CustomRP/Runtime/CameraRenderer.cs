using UnityEngine;
using UnityEngine.Rendering;

public class CameraRenderer
{
	ScriptableRenderContext context;

	Camera camera;

	const string bufferName = "Camera Render";
	CommandBuffer buffer = new CommandBuffer()
	{
		name = bufferName,
	};

	CullingResults cullingResults;//剔除后的结果

	static ShaderTagId unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit");
	public void Render(ScriptableRenderContext context, Camera camera)
	{
		this.context = context;
		this.camera = camera;

        if (!Cull())
        {
			return;
        }

		Setup();
		DrawVisibleGeometry();
		Submit();
	}
    void DrawVisibleGeometry()
    {
		SortingSettings sortingSettings = new SortingSettings(camera);
		DrawingSettings drawingSettings = new DrawingSettings(unlitShaderTagId, sortingSettings);//传shaderPassName，相机的渲染顺序设置
		FilteringSettings filteringSettings = new FilteringSettings(RenderQueueRange.all);
		context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);//对剔除后的结果进行渲染
		context.DrawSkybox(camera);
    }
	void Setup()
	{
		context.SetupCameraProperties(camera);//在清除渲染目标之前调用则可清除相机属性的设置 否则会使用一个全屏的着色器填充清除
		buffer.ClearRenderTarget(true, true, Color.clear);
		buffer.BeginSample(bufferName);
		//设置相机的一些属性 例如 视图投影矩阵 unity_MatrixVP
		ExecuteBuffer();
	}
	void Submit()
    {
		buffer.EndSample(bufferName);
		ExecuteBuffer();
		context.Submit();
    }

	// 如果不及时提交会怎么样？
	void ExecuteBuffer()
    {
		//命令缓存区的提交和清除总是在一起执行
		context.ExecuteCommandBuffer(buffer);
		buffer.Clear();
    }

	bool Cull()
    {
		if(camera.TryGetCullingParameters(out ScriptableCullingParameters p))
        {
			cullingResults = context.Cull(ref p);
			return true;
        }
		return false;
    }
}
