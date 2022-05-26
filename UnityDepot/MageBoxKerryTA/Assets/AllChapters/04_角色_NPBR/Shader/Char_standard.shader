Shader "4/Char_standard"
{
    Properties
    {
        [Header(BaseInfo)]
        _BaseMap("Base Map", 2D) = "white" {}
        _CompMask("Comp Mask(RM)", 2D) = "white"{}
        _NormalMap("Normal Map", 2D) = "bump"{}
        _Smoothness("Smoothness", Float) = 10.0
        _SpecIntensity("Specular Intensity", Float) = 1.0
        _RoughnessAdjust("Smoothness Adjust", Range(-1,1)) = 0.0
        _MetalAdjust("Metal Adjust", Range(-1,1)) = 0.0

        [Header(SSS)]
        _SkinLUTMap("Skin LUT Map", 2D) = "white"{}
        
        [HideInInspector]custom_SHAr("Custom SHAr", Vector) = (0, 0, 0, 0)
		[HideInInspector]custom_SHAg("Custom SHAg", Vector) = (0, 0, 0, 0)
		[HideInInspector]custom_SHAb("Custom SHAb", Vector) = (0, 0, 0, 0)
		[HideInInspector]custom_SHBr("Custom SHBr", Vector) = (0, 0, 0, 0)
		[HideInInspector]custom_SHBg("Custom SHBg", Vector) = (0, 0, 0, 0)
		[HideInInspector]custom_SHBb("Custom SHBb", Vector) = (0, 0, 0, 0)
		[HideInInspector]custom_SHC("Custom SHC", Vector) = (0, 0, 0, 1)

        [Header(IBL)]
        _EnvMap("Env Map",Cube) = "white"{}
		_Tint("Tint",Color) = (1,1,1,1)
		_Expose("Expose",Float) = 1.0

        [Header(Debug)]
        [Toggle(_DIFFUSECHECK_ON)] _DiffuseCheckOn("Diffuse Check On", Float) = 1.0
        [Toggle(_SPECULARCHECK_ON)] _SpecularCheckOn("Specular Check On", Float) = 1.0        
        [Toggle(_IBLCHECK_ON)] _IBLCheckOn("IBL Check On", Float) = 1.0
        [Toggle(_SHCHECK_ON)] _SHCheckOn("SH Check On", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags {"LightMode"="ForwardBase"}  //光照三剑客
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase  //光照三剑客
            //Debug 宏定义  注意：每增加一个shader变体就增加一倍
            #pragma shader_feature _DIFFUSECHECK_ON   
            #pragma shader_feature _SPECULARCHECK_ON
            #pragma shader_feature _IBLCHECK_ON
            #pragma shader_feature _SHCHECK_ON

            #include "UnityCG.cginc"
            #include "AutoLight.cginc" //光照三剑客
            #include "Lighting.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 normal_world : TEXCOORD1;
                float3 tangent_world : TEXCOORD2;
                float3 binormal_world : TEXCOORD3;
                float4 pos_world : TEXCOORD4;
                LIGHTING_COORDS(5, 6)   //阴影三剑客 ？？？
            };

            sampler2D _BaseMap;
            sampler2D _CompMask;
            sampler2D _NormalMap;            


            float _Smoothness;
            float _SpecIntensity;

            float _RoughnessAdjust;
            float _MetalAdjust;

            sampler2D _SkinLUTMap;
            

            //SH
            half4 custom_SHAr;
			half4 custom_SHAg;
			half4 custom_SHAb;
			half4 custom_SHBr;
			half4 custom_SHBg;
			half4 custom_SHBb;
			half4 custom_SHC;

            //env
            samplerCUBE _EnvMap;
			float4 _EnvMap_HDR;
			float4 _Tint;
			float _Expose;

            float3 custom_sh(float3 normal_dir);
            inline float3 ACES_Tonemapping(float3 x);

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.pos_world = mul(unity_ObjectToWorld, v.vertex);
                o.normal_world = UnityObjectToWorldNormal(v.normal);
                o.tangent_world = UnityObjectToWorldDir(v.tangent);
                o.binormal_world = normalize(cross(o.normal_world, o.tangent_world) * v.tangent.w);  //切线空间属于右手坐标系
                TRANSFER_VERTEX_TO_FRAGMENT(o);//阴影三剑客之二
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                //tex info
                float4 base_color_gamma = tex2D(_BaseMap, i.uv);  //???
                float4 albedo_color = pow(base_color_gamma, 2.2);  //转线性颜色空间    
                float4 comp_mask = tex2D(_CompMask, i.uv);
                float metal = saturate(comp_mask.g + _MetalAdjust);
                float roughness = saturate(comp_mask.r + _RoughnessAdjust);
                float skin_area = saturate(1.0 - comp_mask.b);
                float3 base_color = albedo_color.rgb * (1 - metal); //非金属的固有色
                float3 spec_color = lerp(0.04, albedo_color.rgb, metal);       //金属的高光色

                float3 normaldata = UnpackNormal(tex2D(_NormalMap, i.uv));

                //dir info
                float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
                float3 normal_dir = normalize(i.normal_world);
                float3 tangent_dir = normalize(i.tangent_world);
                float3 binormal_dir = normalize(i.binormal_world);
                float3x3 TBN = float3x3(tangent_dir, binormal_dir, normal_dir);//世界空间到切线空间的旋转矩阵
                normal_dir = mul(normaldata, TBN);

                //light info
                float3 light_dir = normalize(_WorldSpaceLightPos0.xyz);
                float atten = LIGHT_ATTENUATION(i);

                //Direct diffuse 
                float diffuse_term = max(0, dot(normal_dir, light_dir));
                float3 common_diffuse = diffuse_term * _LightColor0.xyz * base_color.xyz * atten;

                float2 uv_lut = float2(diffuse_term, 1.0);
                float3 lut_color_gamma = tex2D(_SkinLUTMap, uv_lut);
                float3 lut_color = pow(lut_color_gamma, 2.2);
                float3 sss_diffuse = lut_color * _LightColor0.xyz * base_color.xyz;

                #ifdef _DIFFUSECHECK_ON
                    float3 direct_diffuse = lerp(common_diffuse, sss_diffuse, 0);   //sss没搞懂
                #else
                    float3 direct_diffuse = float3(0,0,0);
                #endif


                //Direct specular  Blinn-Phong 
                float3 half_dir = normalize(view_dir + light_dir);
                float NdotH = dot(normal_dir, half_dir);
                float smoothness = 1.0 - roughness;
                float shinness = lerp(1.0, _Smoothness, smoothness); //控制整体光滑度
                float specular_term = pow(max(0, NdotH), shinness * smoothness);   //再乘smoothness是经验

                #ifdef _SPECULARCHECK_ON
                    float3 direct_specular = specular_term * _LightColor0.xyz * spec_color * atten;
                #else
                    float3 direct_specular = float3(0,0,0);
                #endif

                //Indirect diffuse 间接光漫反射 SH
                half half_lambert = (diffuse_term + 1.0) * 0.5;

                #ifdef _SHCHECK_ON
                    float3 indirect_diffuse = custom_sh(normal_dir) * base_color * half_lambert * atten;
                #else
                    float3 indirect_diffuse = float3(0,0,0);
                #endif

                //Indirect specular 间接光高光反射 IBL
				roughness = roughness * (1.7 - 0.7 * roughness);
				float mip_level = roughness * 6.0;
                float3 reflect_dir = normalize(reflect(-view_dir, normal_dir));
				half4 color_envmap = texCUBElod(_EnvMap, float4(reflect_dir, mip_level));
				half3 env_color = DecodeHDR(color_envmap, _EnvMap_HDR);//确保在移动端能拿到HDR信息

                #ifdef _IBLCHECK_ON
				    half3 indirect_specular = env_color * _Expose * spec_color * half_lambert;
                #else
                    float3 indirect_specular = float3(0,0,0);
                #endif


                half3 final_color = direct_specular + direct_diffuse + (indirect_diffuse  + indirect_specular) * 0.5;
                final_color = ACES_Tonemapping(final_color);
                final_color = pow(final_color, 1.0/2.2);//转回 gamma空间

                return half4(final_color, 1.0);
            }

            float3 custom_sh(float3 normal_dir)
            {
                float4 normalForSH = float4(normal_dir, 1.0);
				//SHEvalLinearL0L1
				half3 x;
				x.r = dot(custom_SHAr, normalForSH);
				x.g = dot(custom_SHAg, normalForSH);
				x.b = dot(custom_SHAb, normalForSH);

				//SHEvalLinearL2
				half3 x1, x2;
				// 4 of the quadratic (L2) polynomials
				half4 vB = normalForSH.xyzz * normalForSH.yzzx;
				x1.r = dot(custom_SHBr, vB);
				x1.g = dot(custom_SHBg, vB);
				x1.b = dot(custom_SHBb, vB);

				// Final (5th) quadratic (L2) polynomial
				half vC = normalForSH.x*normalForSH.x - normalForSH.y*normalForSH.y;
				x2 = custom_SHC.rgb * vC;

				float3 sh = max(float3(0.0, 0.0, 0.0), (x + x1 + x2));
				sh = pow(sh, 1.0 / 2.2);

                return sh;
            }

            inline float3 ACES_Tonemapping(float3 x)
			{
				float a = 2.51f;
				float b = 0.03f;
				float c = 2.43f;
				float d = 0.59f;
				float e = 0.14f;
				float3 encode_color = saturate((x*(a*x + b)) / (x*(c*x + d) + e));
				return encode_color;
			};
            ENDCG
        }
        //多光源
        Pass
        {
            Tags {"LightMode"="Forwardadd"}  //光照三剑客
            Blend one one

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd  //光照三剑客

            #include "UnityCG.cginc"
            #include "AutoLight.cginc" //光照三剑客
            #include "Lighting.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 normal_world : TEXCOORD1;
                float3 tangent_world : TEXCOORD2;
                float3 binormal_world : TEXCOORD3;
                float4 pos_world : TEXCOORD4;
                LIGHTING_COORDS(5, 6)   //阴影三剑客 ？？？
            };

            sampler2D _BaseMap;
            sampler2D _CompMask;
            sampler2D _NormalMap;            


            float _Smoothness;
            float _SpecIntensity;

            float _RoughnessAdjust;
            float _MetalAdjust;

            sampler2D _SkinLUTMap;
            

            //SH
            half4 custom_SHAr;
			half4 custom_SHAg;
			half4 custom_SHAb;
			half4 custom_SHBr;
			half4 custom_SHBg;
			half4 custom_SHBb;
			half4 custom_SHC;

            //env
            samplerCUBE _EnvMap;
			float4 _EnvMap_HDR;
			float4 _Tint;
			float _Expose;

            float3 custom_sh(float3 normal_dir);
            inline float3 ACES_Tonemapping(float3 x);

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.pos_world = mul(unity_ObjectToWorld, v.vertex);
                o.normal_world = UnityObjectToWorldNormal(v.normal);
                o.tangent_world = UnityObjectToWorldDir(v.tangent);
                o.binormal_world = normalize(cross(o.normal_world, o.tangent_world) * v.tangent.w);  //切线空间属于右手坐标系
                TRANSFER_VERTEX_TO_FRAGMENT(o);//阴影三剑客之二
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                //tex info
                float4 base_color_gamma = tex2D(_BaseMap, i.uv);  //???
                float4 albedo_color = pow(base_color_gamma, 2.2);  //转线性颜色空间    
                float4 comp_mask = tex2D(_CompMask, i.uv);
                float metal = saturate(comp_mask.g + _MetalAdjust);
                float roughness = saturate(comp_mask.r + _RoughnessAdjust);
                float skin_area = saturate(1.0 - comp_mask.b);
                float3 base_color = albedo_color.rgb * (1 - metal); //非金属的固有色
                float3 spec_color = lerp(0.04, albedo_color.rgb, metal);       //金属的高光色

                float3 normaldata = UnpackNormal(tex2D(_NormalMap, i.uv));

                //dir info
                float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
                float3 normal_dir = normalize(i.normal_world);
                float3 tangent_dir = normalize(i.tangent_world);
                float3 binormal_dir = normalize(i.binormal_world);
                float3x3 TBN = float3x3(tangent_dir, binormal_dir, normal_dir);//世界空间到切线空间的旋转矩阵
                normal_dir = mul(normaldata, TBN);

                float3 light_dir;
                //light info
                #ifdef USING_DIRECTIONAL_LIGHT
                    light_dir = normalize(_WorldSpaceLightPos0.xyz);
                #else
                    light_dir = normalize(_WorldSpaceLightPos0.xyz - i.pos_world);
                #endif
                    
                float atten = LIGHT_ATTENUATION(i);

                //Direct diffuse 
                float diffuse_term = max(0, dot(normal_dir, light_dir));
                float3 common_diffuse = diffuse_term * _LightColor0.xyz * base_color.xyz * atten;

                float2 uv_lut = float2(diffuse_term, 1.0);
                float3 lut_color_gamma = tex2D(_SkinLUTMap, uv_lut);
                float3 lut_color = pow(lut_color_gamma, 2.2);
                float3 sss_diffuse = lut_color * _LightColor0.xyz * base_color.xyz;

                float3 direct_diffuse = lerp(common_diffuse, sss_diffuse, 0);   //sss没搞懂

                //Direct specular  Blinn-Phong 
                float3 half_dir = normalize(view_dir + light_dir);
                float NdotH = dot(normal_dir, half_dir);
                float smoothness = 1.0 - roughness;
                float shinness = lerp(1.0, _Smoothness, smoothness); //控制整体光滑度
                float specular_term = pow(max(0, NdotH), shinness * smoothness);   //再乘smoothness是经验
                float3 direct_specular = specular_term * _LightColor0.xyz * spec_color * atten;

                half3 final_color = direct_specular + direct_diffuse;
                final_color = ACES_Tonemapping(final_color);
                final_color = pow(final_color, 1.0/2.2);//转回 gamma空间

                return half4(final_color, 1.0);
            }

            float3 custom_sh(float3 normal_dir)
            {
                float4 normalForSH = float4(normal_dir, 1.0);
				//SHEvalLinearL0L1
				half3 x;
				x.r = dot(custom_SHAr, normalForSH);
				x.g = dot(custom_SHAg, normalForSH);
				x.b = dot(custom_SHAb, normalForSH);

				//SHEvalLinearL2
				half3 x1, x2;
				// 4 of the quadratic (L2) polynomials
				half4 vB = normalForSH.xyzz * normalForSH.yzzx;
				x1.r = dot(custom_SHBr, vB);
				x1.g = dot(custom_SHBg, vB);
				x1.b = dot(custom_SHBb, vB);

				// Final (5th) quadratic (L2) polynomial
				half vC = normalForSH.x*normalForSH.x - normalForSH.y*normalForSH.y;
				x2 = custom_SHC.rgb * vC;

				float3 sh = max(float3(0.0, 0.0, 0.0), (x + x1 + x2));
				sh = pow(sh, 1.0 / 2.2);

                return sh;
            }

            inline float3 ACES_Tonemapping(float3 x)
			{
				float a = 2.51f;
				float b = 0.03f;
				float c = 2.43f;
				float d = 0.59f;
				float e = 0.14f;
				float3 encode_color = saturate((x*(a*x + b)) / (x*(c*x + d) + e));
				return encode_color;
			};
            ENDCG
        }
    }
    FallBack "Diffuse" 
}
