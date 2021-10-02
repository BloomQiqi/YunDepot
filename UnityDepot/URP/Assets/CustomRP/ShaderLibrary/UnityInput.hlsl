#ifndef CUSTOM_UNITY_INPUT_INCLUDED
#define CUSTOM_UNITY_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl" //1

CBUFFER_START(UnityPerDraw)   //CBUFFER_SRART CBUFFER_END 是在上面的1库中定义的
	float4x4 unity_ObjectToWorld;//内置
	float4x4 unity_WorldToObject;
	float4 unity_LODFade;
	real4 unity_WorldTransformParams;
CBUFFER_END

float4x4 unity_MatrixVP;
float4x4 unity_MatrixV; 
float4x4 glstate_matrix_projection;
#endif