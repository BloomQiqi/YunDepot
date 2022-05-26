Shader "Unlit/GassianBlur"
{
    //通用代码
    CGINCLUDE
    #include "UnityCG.cginc"

    sampler2D _MainTex;
    // float4 _MainTex_TexelSize;//x = 1/width; y = 1/height; z = width; w = height
    float4 _BlurOffset;

    fixed4 frag_HorizonalBlur (v2f_img i) : SV_Target
    {
        half4 d = _BlurOffset.xyxy * half4(-1,-1,1,1);//在cpu端计算偏移量
        half2 uv1 = i.uv + _BlurOffset.xy * half2(1,0) * -2.0;
        half2 uv2 = i.uv + _BlurOffset.xy * half2(1,0) * -1.0;
        half2 uv3 = i.uv;
        half2 uv4 = i.uv + _BlurOffset.xy * half2(1,0) * 1.0;
        half2 uv5 = i.uv + _BlurOffset.xy * half2(1,0) * 2.0;
        
        half4 s = 0;
        s += tex2D(_MainTex, uv1) * 0.05;
        s += tex2D(_MainTex, uv2) * 0.25;
        s += tex2D(_MainTex, uv3) * 0.45;
        s += tex2D(_MainTex, uv4) * 0.25;
        s += tex2D(_MainTex, uv5) * 0.05;

        return s;
    }

    fixed4 frag_VerticalBlur (v2f_img i) : SV_Target
    {
        half4 d = _BlurOffset.xyxy * half4(-1,-1,1,1);//在cpu端计算偏移量
        half2 uv1 = i.uv + _BlurOffset.xy * half2(0,1) * -2.0;
        half2 uv2 = i.uv + _BlurOffset.xy * half2(0,1) * -1.0;
        half2 uv3 = i.uv;
        half2 uv4 = i.uv + _BlurOffset.xy * half2(0,1) * 1.0;
        half2 uv5 = i.uv + _BlurOffset.xy * half2(0,1) * 2.0;
        
        half4 s = 0;
        s += tex2D(_MainTex, uv1) * 0.05;
        s += tex2D(_MainTex, uv2) * 0.25;
        s += tex2D(_MainTex, uv3) * 0.45;
        s += tex2D(_MainTex, uv4) * 0.25;
        s += tex2D(_MainTex, uv5) * 0.05;

        return s;
    }

    ENDCG


    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        // _BlurOffset("Blur Offset", Flo) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        //0
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_HorizonalBlur

            ENDCG
        }

        //1
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_VerticalBlur

            ENDCG
        }
    }
}
