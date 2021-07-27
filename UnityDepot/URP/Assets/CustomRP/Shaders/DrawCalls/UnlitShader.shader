Shader "Custom RP/Unlit/UnlitShader"
{
    Properties {}
    SubShader
    {
        Pass { 
            HLSLPROGRAM
            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment
            #include "UnlitPass.hlsl"
      
            ENDHLSL
        }
    }
}
