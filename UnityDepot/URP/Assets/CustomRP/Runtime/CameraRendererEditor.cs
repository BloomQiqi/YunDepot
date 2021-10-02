using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;
using UnityEngine.Profiling;

public partial class CameraRenderer
{
	partial void DrawGizmos();
	partial void DrawUnsupportedShaders();
	//渲染世界几何图形 如UI在Scene View窗口的显示
	partial void PrepareForSceneWindow();
	//
	partial void PrepareBuffer();
#if UNITY_EDITOR

	static ShaderTagId[] legacyShaderTagIds = {
		new ShaderTagId("Always"),
		new ShaderTagId("ForwardBase"),
		new ShaderTagId("PrepassBase"),
		new ShaderTagId("Vertex"),
		new ShaderTagId("VertexLMRGBM"),
		new ShaderTagId("VertexLM")
	};
	static Material errorMaterial;

	string SampleName { get; set; }

	partial void DrawUnsupportedShaders()
    {
		if(errorMaterial == null)
        {
			errorMaterial = new Material(Shader.Find("Hidden/InternalErrorShader"));
        }
		DrawingSettings drawingSettings = new DrawingSettings(
			legacyShaderTagIds[0], new SortingSettings(camera)
		){
			overrideMaterial = errorMaterial,	
		};
		for(int i = 1; i < legacyShaderTagIds.Length; i++)
        {
			drawingSettings.SetShaderPassName(i, legacyShaderTagIds[i]);
        }
		FilteringSettings filteringSettings = FilteringSettings.defaultValue;
		context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);

    }
    partial void DrawGizmos()
    {
        if (Handles.ShouldRenderGizmos())
        {
			context.DrawGizmos(camera, GizmoSubset.PreImageEffects);
			context.DrawGizmos(camera, GizmoSubset.PostImageEffects);
        }
    }
	partial void PrepareForSceneWindow()
    {
		if(camera.cameraType == CameraType.SceneView)
        {
			ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);//将UI Geometry
        }
    }
	partial void PrepareBuffer()
    {
		Profiler.BeginSample("Editor Only");
        buffer.name = SampleName = camera.name;
        Profiler.EndSample();
	}
#else
	const string SampleName = bufferName;

#endif
}
