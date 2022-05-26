Shader "4/Char_standard"
{
    Properties
    {
        [Header(BaseInfo)]
        _BaseMap("Base Map", 2D) = "white" {}
        _NormalMap("Normal Map", 2D) = "bump"{}
        _NoiseMap("Noise Map", 2D) = "gray"{}
        _SpecIntensity("Specular Intensity", Float) = 1.0
        _RoughnessAdjust("Smoothness Adjust", Range(-1,1)) = 0.0

        _ShiftOffest("Shift Offest", Range(-1,1)) = 0.0
        _NoiseIntensity("Noise Intensity", Float) = 1.0
        _HairPower("Hair Power", Float) = 100

        _SpecularColor("Specular Color", Color) = (1.0,1.0,1.0,1.0)

        [Header(IBL)]
        _EnvMap("Env Map",Cube) = "white"{}
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
            sampler2D _NoiseMap;
            float4 _NoiseMap_ST;
            sampler2D _NormalMap;            


            float _Smoothness;
            float _SpecIntensity;
            float _RoughnessAdjust;
            float _ShiftOffest;
            float _NoiseIntensity;
            float _HairPower;

            float4 _SpecularColor;

            //env
            samplerCUBE _EnvMap;
			float4 _EnvMap_HDR;
			float _Expose;

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

                float roughness = _RoughnessAdjust;

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
                float half_lambert = (diffuse_term + 1) * 0.5;
                float3 common_diffuse = half_lambert * _LightColor0.xyz * albedo_color.xyz * atten;

                #ifdef _DIFFUSECHECK_ON
                    float3 direct_diffuse = common_diffuse; 
                #else
                    float3 direct_diffuse = float3(0,0,0);
                #endif


                //Direct specular  KK
                half2 uv = _NoiseMap_ST * i.uv + _NoiseMap_ST.zw;
                half shiftnoise = tex2D(_NoiseMap, uv).r;
                shiftnoise = (shiftnoise * 2.0 - 1.0) * _NoiseIntensity;//转换到-1,1

                half3 half_dir = normalize(view_dir + light_dir);
                half3 b_offset = normal_dir * (_ShiftOffest + shiftnoise);
                binormal_dir = normalize(binormal_dir + b_offset); //给副法线一个偏移值

                half BdotH = dot(binormal_dir, half_dir);
                half sinTH = sqrt(1.0 - BdotH * BdotH);
                half KKHair_term = pow(max(0, sinTH), _HairPower);

                half3 specular_term = KKHair_term * _SpecIntensity;   //再乘smoothness是经验
                half3 spec_color = _SpecularColor.rgb + albedo_color.rgb;

                #ifdef _SPECULARCHECK_ON
                    float3 direct_specular = specular_term * _LightColor0.xyz * spec_color;
                #else
                    float3 direct_specular = float3(0,0,0);
                #endif

                //Indirect specular 间接光高光反射 IBL
				roughness = roughness * (1.7 - 0.7 * roughness);
				float mip_level = roughness * 6.0;
                float3 reflect_dir = normalize(reflect(-view_dir, normal_dir));
				half4 color_envmap = texCUBElod(_EnvMap, float4(reflect_dir, mip_level));
				half3 env_color = DecodeHDR(color_envmap, _EnvMap_HDR);//确保在移动端能拿到HDR信息

                #ifdef _IBLCHECK_ON
				    half3 indirect_specular = env_color * _Expose * albedo_color * half_lambert;
                #else
                    float3 indirect_specular = float3(0,0,0);
                #endif


                half3 final_color = direct_specular + direct_diffuse + indirect_specular;
                final_color = ACES_Tonemapping(final_color);
                final_color = pow(final_color, 1.0/2.2);//转回 gamma空间

                return half4(final_color, 1.0);
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
