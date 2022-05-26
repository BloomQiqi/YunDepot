using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class EasyImageEffect : MonoBehaviour
{
    public Material material;
    public float _Brightness = 1.0f;
    public float _Saturattion = 1.0f;
    public float _Contrast = 1.0f;
    [Range(0.05f, 3f)]
    public float _VignetteIntensity = 1.5f;
    [Range(0.05f, 6f)]
    public float _VignetteRoundness = 1.5f;
    [Range(0.05f, 5f)]
    public float _VignetteSmoothnees = 1.5f;
    public float _HueShift = 0.0f;

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
        material.SetFloat("_Brightness", _Brightness);
        material.SetFloat("_Saturattion", _Saturattion);
        material.SetFloat("_Contrast", _Contrast);
        material.SetFloat("_VignetteIntensity", _VignetteIntensity);
        material.SetFloat("_VignetteRoundness", _VignetteRoundness);
        material.SetFloat("_VignetteSmoothnees", _VignetteSmoothnees);
        material.SetFloat("_HueShift", _HueShift);
        Graphics.Blit(source, destination, material, 0);
    }
}
