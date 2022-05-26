Shader "Unlit/Screen"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 pos_clip : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.pos_clip = o.pos;
                o.pos_clip.y = o.pos_clip.y * _ProjectionParams.x;//不同平台uv的起点不同，用内置参数来区别
                // o.pos_clip = ComputeScreenPos(o.pos); Unity内置计算屏幕空间坐标的方法，已经处理好平台差异化，并且映射到了（0,1）
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half2 screen_uv = i.pos_clip.xy / (i.pos_clip.w + 0.000000001); //透视除法，NDC标准化坐标空间 (-1, 1)
                screen_uv = (screen_uv + 1.0) * 0.5;

                half4 col = tex2D(_MainTex, screen_uv);

                return col;
            }
            ENDCG
        }
    }
}
