using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class BrokenGrass : MonoBehaviour
{
    public Material material;


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
        Graphics.Blit(source, destination, material, 0);
    }
}
