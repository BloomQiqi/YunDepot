#ifndef CUSTOM_UNLIT_PASS_INCLUDE
#define CUSTOM_UNLIT_PASS_INCLUDE

#include "../../ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "../../ShaderLibrary/UnityInput.hlsl"

CBUFFER_START(UnityPerMaterial)
	float4 _BaseColor;
CBUFFER_END

float4 UnlitPassVertex(float3 positionOS : POSITION) : SV_POSITION{
    float3 positionWS = TransformObjectToWorld(positionOS.xyz);//!!! 注意分割";"号啊
    return TransformWorldToHClip(positionWS.xyz);
}

float4 UnlitPassFragment() : SV_TARGET {
    return _BaseColor;
}

#endif   