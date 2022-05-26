using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class DualBoxBlur : MonoBehaviour
{
    public Material material;
    [Range(0, 10)]
    public float _Iteration = 4;
    [Range(1, 10)]
    public float _BlurRadius = 1f;
    [Range(1, 10)]
    public float _DownSample = 2f;

    void Start()
    {
        if(material == null || material.shader.isSupported == false || SystemInfo.supportsImageEffects == false
            || material.shader == null)
        {
            enabled = false;
            Debug.Log("图像处理初始化错误");
            return;
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        int width = source.width;
        int height = source.height;
        //降采样 提高性能
        width = (int)(width/_DownSample);
        height = (int)(height/_DownSample);
        RenderTexture RT1 = RenderTexture.GetTemporary(width, height);
        RenderTexture RT2 = RenderTexture.GetTemporary(width, height);

        material.SetVector("_BlurOffset", new Vector4(_BlurRadius / width, _BlurRadius / height, 0, 0));

        Graphics.Blit(source, RT1);
        //降采样
        for(int i = 0; i < _Iteration; i++)
        {
            RenderTexture.ReleaseTemporary(RT2);
            width /= 2;
            height /= 2;
            RT2 = RenderTexture.GetTemporary(width, height);
            Graphics.Blit(RT1, RT2, material, 0);

            RenderTexture.ReleaseTemporary(RT1);
            width /= 2;
            height /= 2;
            RT1 = RenderTexture.GetTemporary(width, height);
            Graphics.Blit(RT2, RT1, material, 1);
        }

        //升采样
        for (int i = 0; i < _Iteration; i++)
        {
            RenderTexture.ReleaseTemporary(RT2);
            width *= 2;
            height *= 2;
            RT2 = RenderTexture.GetTemporary(width, height);
            Graphics.Blit(RT1, RT2, material, 0);

            RenderTexture.ReleaseTemporary(RT1);
            width *= 2;
            height *= 2;
            RT1 = RenderTexture.GetTemporary(width, height);
            Graphics.Blit(RT2, RT1, material, 1);
        }

        Graphics.Blit(RT1, destination);
        //release
        RenderTexture.ReleaseTemporary(RT1);
        RenderTexture.ReleaseTemporary(RT2);
    }
}
