Shader "Unlit/Toon"
{
    Properties
    {
        _BaseMap("Base Map", 2D) = "white" {}
        _SSSMap("SSS Map", 2D) = "Black" {}
        _ILMMap("ILM Map", 2D) = "white" {}
        _DetailMap("Detail Map", 2D) = "white" {}
        _ToonThreshold("Toon Threshold", Range(0, 1.0)) = 0.5
        _ToonHardness("Toon Hardness", Float) = 20
        _SpecSize("Spec Size", Range(0, 1.0)) = 0.8
        _SpecColor("Spec Color", Color) = (1,1,1,1)
        _OutlineWidth("OutLine Width", Float) = 0.01
        _OutlineColor("OutLine Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _OutlineZBais("OutLine Z Bias", Float) = -10.0
        _RimLightDir("RimLight Dir", Vector) = (1, 0, -1, 0)
        _RimLightColor("RimLight Color", Color) = (1.0,1.0,1.0,1.0)
    }
    SubShader
    {
        Tags { "LightMode"="ForwardBase" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                float3 normal : NORMAL;
                float4 color : COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 pos_world : TEXCOORD1;
                float3 normal_world : TEXCOORD2;
                float4 vertex_color : TEXCOORD3;
                LIGHTING_COORDS(4,5)
            };

            sampler2D _BaseMap;
            sampler2D _SSSMap;
            sampler2D _ILMMap;
            sampler2D _DetailMap;

            float _ToonThreshold;
            float _ToonHardness; 
            float _SpecSize;
            float4 _SpecColor;
            float4 _RimLightDir;
            float4 _RimLightColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.pos_world = mul(unity_ObjectToWorld, v.vertex);
                o.normal_world = UnityObjectToWorldNormal(v.normal);
                o.uv = float4(v.texcoord0, v.texcoord1);
                o.vertex_color = v.color;
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
                half2 uv1 = i.uv.xy;
                half2 uv2 = i.uv.zw;
                //向量
                float3 normalDir = normalize(i.normal_world);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz);
                  
                //Base 贴图
                half4 base_map = tex2D(_BaseMap, uv1);
                half3 base_color = base_map.rgb;//亮部的颜色
                half base_mask = base_map.a;//区分皮肤和非皮肤  0为皮肤区域 1非皮肤

                //SSS 贴图
                half4 sss_map = tex2D(_SSSMap, uv1);
                half3 sss_color = sss_map.rgb;//暗部的颜色
                half sss_mask = sss_map.a;//除了区分皮肤和非皮肤之外，还区分了 披风和鞋子，更细腻

                //ILM 贴图
                half4 ilm_map = tex2D(_ILMMap, uv1);
                half spec_intensity = ilm_map.r;//控制高光强度
                half diffuse_control = ilm_map.g * 2 - 1.0;//控制光照偏移  -1到1
                half spec_size = ilm_map.b;//控制高光区域
                half inner_line = ilm_map.a;//内描线
                //顶点色 保存了一些其他信息
                half ao = i.vertex_color.r;

                //漫反射光照
                half NdotL = dot(normalDir, lightDir); // -1到1
                half half_lambert = (NdotL + 1) * 0.5; // 0到1
                half lambert_term = half_lambert * ao + diffuse_control;
                half toon_diffuse = saturate((lambert_term - _ToonThreshold) * _ToonHardness);//色阶化
                half3 final_diffuse = lerp(sss_color, base_color, toon_diffuse);

                //高光
                half NdotV = saturate((dot(normalDir, viewDir) + 1.0) * 0.5);
                half spec_term = NdotV * ao + diffuse_control;
                spec_term = saturate(half_lambert * 0.9 + spec_term * 0.1);//这里让高光，既受视角影响也受光照方向影响
                half toon_spec = saturate((spec_term - (1 - spec_size * _SpecSize)) * 500);//色阶化 
                half spec_color = (_SpecColor.xyz + base_color) * 0.5;//给高光部分一些颜色
                half3 final_spec = toon_spec * spec_intensity * spec_color;

                //补光(或边缘光) 基于相机空间
                float3 rimlight_worldDir = normalize(mul((float3x3)unity_MatrixInvV, _RimLightDir));//从相机空间转换到世界空间，
                                                                                            //这里假设_RimLightDir是相机空间上的
                half rimlight_term = (dot(normalDir, rimlight_worldDir) + 1) * 0.5;
                half toon_rimlight = saturate((rimlight_term - _ToonThreshold) * 20);
                half rimlight_controlterm = lambert_term * base_mask * sss_mask;
                half3 final_rimlight = toon_rimlight * _RimLightColor * rimlight_controlterm;

                //阴影因子
                float atten = LIGHT_ATTENUATION(i);
                
                //内描线
                half inner_line_color = lerp(base_color * 0.2, float3(1.0,1.0,1.0), inner_line);//给描线添加一些颜色
                half3 detail_color = tex2D(_DetailMap, uv2);
                detail_color = lerp(base_color * 0.2, float3(1.0,1.0,1.0), detail_color.r);
                half final_line = inner_line_color * inner_line_color * detail_color;//使描线变粗

                half3 final_color;
                final_color = (final_spec + final_diffuse + final_rimlight) * final_line * atten;
                final_color = sqrt(max(exp2(log2(max(final_color, 0.0)) * 2.2), 0.0));//稍微有一个对比度的压暗
                return half4(final_color, 1);
            }
            ENDCG
        }
        Pass
        {
            cull front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float3 normal : NORMAL;
                float4 color : COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 pos_world : TEXCOORD1;
                float4 vertex_color : TEXCOORD2;
            };

            sampler2D _BaseMap;
            sampler2D _SSSMap;
            sampler2D _ILMMap;

            float _OutlineWidth;
            float4 _OutlineColor;
            float _OutlineZBais;

            v2f vert (appdata v)
            {
                v2f o;
                float3 pos_view = mul(UNITY_MATRIX_MV, v.vertex);
                float3 normal_world = UnityObjectToWorldNormal(v.normal);
                float3 normal_view = normalize(mul((float3x3)UNITY_MATRIX_V, normal_world));
                normal_view.z = _OutlineZBais * (1 - v.color.b); 
                pos_view = pos_view + normal_view * _OutlineWidth * v.color.a;
                o.pos = mul(UNITY_MATRIX_P, float4(pos_view, 1.0));

                // float3 pos_world = mul(UNITY_MATRIX_M, v.vertex);
                // float3 normal_world = UnityObjectToWorldNormal(v.normal);
                // pos_world = pos_world + normal_world * _OutlineWidth;
                // o.pos = mul(UNITY_MATRIX_VP, float4(pos_world, 1.0));

                o.uv = v.texcoord0;
                o.vertex_color = v.color;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                //Base 贴图
                half3 base_color = tex2D(_BaseMap, i.uv).rgb;
                half maxComponent = max(max(base_color.r, base_color.g), base_color.b);
                half3 saturatedColor = step(maxComponent, base_color) * base_color;//让rgb通道中值更大的一个保留原值，其余通道值置0
                saturatedColor = lerp(base_color.rgb, saturatedColor, 0.6);//插值混合
                half3 outlineColor = 0.8 * saturatedColor * base_color * _OutlineColor;

                return half4(outlineColor, 1.0);
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
