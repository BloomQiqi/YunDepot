Shader "Hidden/BrokenGlass"  //Hidden 下的不会在材质球上显示
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _GlassMask("Glass Mask", 2D) = "white" {}
        _GlassCrack("Glass Crack", Float) = 1.0
        _GlassNormal("Glass Normal", 2D) = "Bump"{}
        _Distort("Distort", Float) = 1.0
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img   //v2f_img 内置
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _GlassMask;
            float4 _GlassMask_ST;
            sampler2D _GlassNormal;
            float _GlassCrack;
            float _Distort;

            half4 frag (v2f_img i) : SV_Target
            {
                float aspect = _ScreenParams.x / _ScreenParams.y;
                half2 glass_uv = i.uv * _GlassMask_ST.xy + _GlassMask_ST.zw;
                glass_uv.x = glass_uv.x * aspect;

                half glass_opacity = tex2D(_GlassMask, glass_uv).r;
                half3 glass_normal = UnpackNormal(tex2D(_GlassNormal, glass_uv));

                /*求边缘mask*/
                // half d = abs(i.uv.x * 2.0 - 1.0);//中心处是0
                // d = smoothstep(0.95, 1, d);//小于0.95 就是0
                // d = 1 - d;//反向
                // half d = 1 - smoothstep(0.95, 1, abs(i.uv.x * 2.0 - 1.0));
                // half d2 = 1 - smoothstep(0.95, 1, abs(i.uv.y * 2.0 - 1.0));
                // d = d * d2;
                half2 d = 1.0 - smoothstep(0.95, 1, abs(i.uv * 2.0 - 1.0));
                half vfactor = d.x * d.y;

                float2 d_mask = step(0.005, abs(glass_normal.xy));//小于0.005就置0
                half mask = d_mask.x * d_mask.y;


                half2 uv_distort = i.uv + glass_normal.xy * _Distort * vfactor * mask;
                half4 col = tex2D(_MainTex, uv_distort);
                half3 final_color = col.rgb;
                final_color = lerp(final_color, _GlassCrack.xxx, glass_opacity);
                return half4(final_color, 1.0);
                // return d.xxxx;
            }
            ENDCG
        }
    }
}
