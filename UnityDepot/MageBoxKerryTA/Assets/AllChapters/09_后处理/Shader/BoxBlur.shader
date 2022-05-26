Shader "Unlit/BoxBlur"
{
    //通用代码
    CGINCLUDE
    #include "UnityCG.cginc"

    sampler2D _MainTex;
    // float4 _MainTex_TexelSize;//x = 1/width; y = 1/height; z = width; w = height
    float4 _BlurOffset;

    fixed4 frag_BoxBlur_4Tap (v2f_img i) : SV_Target
    {
        fixed4 col = tex2D(_MainTex, i.uv);
        // half4 d = _MainTex_TexelSize.xyxy * half4(-1,-1,1,1) * _BlurScale;
        half4 d = _BlurOffset.xyxy * half4(-1,-1,1,1);//在cpu端计算偏移量

        half4 s = 0;
        s += tex2D(_MainTex, i.uv + d.xy);
        s += tex2D(_MainTex, i.uv + d.zy);
        s += tex2D(_MainTex, i.uv + d.xw);
        s += tex2D(_MainTex, i.uv + d.zw);
        s *= 0.25;

        return s;
    }

    fixed4 frag_BoxBlur_9Tap (v2f_img i) : SV_Target
    {
        fixed4 col = tex2D(_MainTex, i.uv);
        // half4 d = _MainTex_TexelSize.xyxy * half4(-1,-1,1,1) * _BlurScale;
        half4 d = _BlurOffset.xyxy * half4(-1,-1,1,1);//在cpu端计算偏移量

        half4 s = 0;
        //中心点
        s += tex2D(_MainTex, i.uv);//中心

        //四个角
        s += tex2D(_MainTex, i.uv + d.xy);//-1 -1
        s += tex2D(_MainTex, i.uv + d.zy);//1 -1
        s += tex2D(_MainTex, i.uv + d.xw);//-1 1
        s += tex2D(_MainTex, i.uv + d.zw);//1 1

        //四中心
        s += tex2D(_MainTex, i.uv + _BlurOffset.xy * half2(0, 1));//0 1
        s += tex2D(_MainTex, i.uv + _BlurOffset.xy * half2(0, -1));//1 -1
        s += tex2D(_MainTex, i.uv + _BlurOffset.xy * half2(-1, 0));//-1 1
        s += tex2D(_MainTex, i.uv + _BlurOffset.xy * half2(1, 0));//1 1

        s /= 9;

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
            #pragma fragment frag_BoxBlur_4Tap

            ENDCG
        }

        //1
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_BoxBlur_9Tap

            ENDCG
        }
    }
}
