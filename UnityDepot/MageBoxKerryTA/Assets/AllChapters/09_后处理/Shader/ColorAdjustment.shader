Shader "Hidden/ColorAdjustment"  //Hidden 下的不会在材质球上显示
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Brightness("Brightness", Float) = 1.0
        _Saturattion("Saturation", Float) = 1.0
        _Contrast("Contrast", Float) = 1.0
        _VignetteIntensity("Vignette Intensity", Range(0.05, 3)) = 1.5
        _VignetteRoundness("Vignette Roundness", Range(0.05, 6)) = 1.5
        _VignetteSmoothnees("Vignette Smoothnees", Range(0.05, 5)) = 1.5
        _HueShift("Hue Shift", Float) = 0.0
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
            float _Brightness;
            float _Saturattion;
            float _Contrast;
            float _VignetteIntensity;
            float _VignetteRoundness;
            float _VignetteSmoothnees;
            float _HueShift;

            //函数预定义
            float3 HSVToRGB(float3 c);
            float3 RGBToHSV(float3 c);

            half4 frag (v2f_img i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);
                half3 final_color = col.rgb;
                //调整色相
                half3 hsv = RGBToHSV(final_color);
                hsv.r = hsv.r + _HueShift;

                final_color = HSVToRGB(hsv);

                //调整亮度
                final_color = final_color.rgb * _Brightness;//对应V 
                
                //饱和度
                float lumin = dot(final_color, float3(0.22,0.707,0.071));//Gamma空间求明度
                // float lumin = dot(final_color, float3(0.0396,0.458,0.0061));//线性空间求明度
                final_color = lerp(lumin, final_color, _Saturattion);

                //对比度
                float3 midpoint = float3(0.5,0.5,0.5);
                final_color = lerp(midpoint, final_color, _Contrast);

                //暗角/晕影 方形
                float2 d = abs(i.uv - half2(0.5,0.5)) * _VignetteIntensity;
                d = pow(saturate(d), _VignetteRoundness);
                float dist = length(d);
                float vfactor = pow(saturate(1.0 - dist * dist), _VignetteSmoothnees);

                final_color = final_color * vfactor;
                return half4(final_color, 1.0);
            }

            float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}
			
			float3 RGBToHSV(float3 c)
			{
				float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
				float4 p = lerp( float4( c.bg, K.wz ), float4( c.gb, K.xy ), step( c.b, c.g ) );
				float4 q = lerp( float4( p.xyw, c.r ), float4( c.r, p.yzx ), step( p.x, c.r ) );
				float d = q.x - min( q.w, q.y );
				float e = 1.0e-10;
				return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}
            ENDCG
        }
    }
}
