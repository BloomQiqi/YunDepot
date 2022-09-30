using UnityEngine;
using UnityEngine.Rendering;

public partial class CameraRenderer
{
	ScriptableRenderContext context;

	Camera camera;

	const string bufferName = "Camera Render Buffer";
	CommandBuffer buffer = new CommandBuffer()
	{
		name = bufferName,
	};

	CullingResults cullingResults;//剔除后的结果

	static ShaderTagId unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit");//?????

	public void Render(ScriptableRenderContext context, Camera camera)
	{
		this.context = context;
		this.camera = camera;

        PrepareBuffer();//多相机时，为不同的缓冲区命名，便于调试查找
        PrepareForSceneWindow();//绘制Scene 下UI
		if (!Cull())
        {
			return;
        }

		Setup();
		DrawVisibleGeometry();//不透明 天空盒 透明
        DrawUnsupportedShaders();
        DrawGizmos();//绘制 如scene场景下 摄像机的范围线
        Submit();
	}
    void DrawVisibleGeometry()
    {
		//不透明渲染
		SortingSettings sortingSettings = new SortingSettings(camera) { 
			criteria = SortingCriteria.CommonOpaque
		};
		DrawingSettings drawingSettings = new DrawingSettings(unlitShaderTagId, sortingSettings);//传shaderPassName，相机的渲染顺序设置
		FilteringSettings filteringSettings = new FilteringSettings(RenderQueueRange.opaque);
		context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);//对剔除后的结果进行渲染
		//绘制天空盒
		context.DrawSkybox(camera);

		//透明渲染
		DrawTransparentVisibleGeometry(sortingSettings, drawingSettings, filteringSettings);
	}
	//透明渲染
	void DrawTransparentVisibleGeometry(SortingSettings sortingSettings, DrawingSettings drawingSettings, FilteringSettings filteringSettings)
    {
		sortingSettings.criteria = SortingCriteria.CommonTransparent;
		drawingSettings.sortingSettings = sortingSettings;
		filteringSettings.renderQueueRange = RenderQueueRange.transparent;

		context.DrawRenderers(
			cullingResults, ref drawingSettings, ref filteringSettings
		);
	}

	void Setup()
	{
		context.SetupCameraProperties(camera);//在清除渲染目标之前调用则可清除相机属性的设置 否则会使用一个全屏的着色器填充清除
		CameraClearFlags flags = camera.clearFlags;
		buffer.ClearRenderTarget(
			flags <= CameraClearFlags.Depth, flags == CameraClearFlags.Color,
			flags == CameraClearFlags.Color ? camera.backgroundColor.linear : Color.clear);//是否清除深度缓冲区 颜色缓冲区 用什么颜色清除 [深度值 = 1]
		buffer.BeginSample(SampleName);
		//设置相机的一些属性 例如 视图投影矩阵 unity_MatrixVP
		ExecuteBuffer();
	}

	//最终执行的
	void Submit()
    {
		buffer.EndSample(SampleName);
		ExecuteBuffer();//将缓冲
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
