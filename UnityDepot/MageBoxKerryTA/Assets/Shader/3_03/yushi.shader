Shader "3_03/yushi"
{
    Properties
    {
        _Diffuse("Diffuse Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Power("Power", Float) = 1.0
        _Scale("Scale", Float) = 1.0
        _Distort("Distort", Float) = 1.0 //控制透射光线的扭曲
        _ThicknessMap("Thickness Map", 2D) = "white"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags{ "LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos: SV_POSITION;
                float3 pos_world : TEXCOORD1;
                float3 normal_world : TEXCOORD2;
                
            };

            float4 _Diffuse;
            float _Power;
            float _Scale;
            float _Distort;
            sampler2D _ThicknessMap;
            float4 _ThicknessMap_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.normal_world = normalize(UnityObjectToWorldNormal(v.normal));
                o.pos_world = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = v.texcoord * _ThicknessMap_ST.xy + _ThicknessMap_ST.zw;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal_dir = normalize(i.normal_world);
                float NdotL =  max(0, dot(normal_dir, _WorldSpaceLightPos0.xyz));
                float3 light_dir = normalize(_WorldSpaceLightPos0.xyz);
                float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
                float3 distort_light_dir = -normalize(light_dir + normal_dir * _Distort);

                //模拟透射光
                float VdotL = max(0, dot(view_dir, distort_light_dir));
                float backlight_term = max(0, pow(VdotL, _Power)) * _Scale;

                //采样厚度贴图
                float thickness = tex2D(_ThicknessMap, i.uv).r;

                float3 diffuse_color = backlight_term * _LightColor0;
                float3 final_color = diffuse_color;
                return float4(thickness.xxx, 1.0);
            }
            ENDCG
        }

        // Pass
        // {
        //     Tags{ "LightMode"="ForwardAdd"}
        //     Blend one one
        //     CGPROGRAM
        //     #pragma vertex vert
        //     #pragma fragment frag
        //     // make fog work
        //     #pragma multi_compile_fwdadd

        //     #include "UnityCG.cginc"
        //     #include "AutoLight.cginc"
        //     #include "Lighting.cginc"

        //     struct appdata
        //     {
        //         float4 vertex : POSITION;
        //         float2 texcoord : TEXCOORD0;
        //         float3 normal : NORMAL;
        //     };

        //     struct v2f
        //     {
        //         float2 uv : TEXCOORD0;
        //         float4 pos: SV_POSITION;
        //         float3 pos_world : TEXCOORD1;
        //         float3 normal_world : TEXCOORD2;
        //     };

        //     float4 _Diffuse;
        //     float _Power;
        //     float _Scale;
        //     float _Distort;

        //     v2f vert (appdata v)
        //     {
        //         v2f o;
        //         o.pos = UnityObjectToClipPos(v.vertex);
        //         o.normal_world = normalize(UnityObjectToWorldNormal(v.normal));
        //         o.pos_world = mul(unity_ObjectToWorld, v.vertex).xyz;


        //         return o;
        //     }

        //     fixed4 frag (v2f i) : SV_Target
        //     {
        //         float3 normal_dir = normalize(i.normal_world);
        //         float NdotL =  max(0, dot(normal_dir, _WorldSpaceLightPos0.xyz));
        //         float3 light_dir = normalize(_WorldSpaceLightPos0.xyz - i.pos_world);
        //         float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
        //         float3 distort_light_dir = -normalize(light_dir + normal_dir * _Distort);

        //         //模拟透射光
        //         float VdotL = max(0, dot(view_dir, distort_light_dir));
        //         float backlight_term = max(0, pow(VdotL, _Power)) * _Scale;

        //         float3 diffuse_color = backlight_term * _LightColor0;
        //         float3 final_color = diffuse_color;
        //         return float4(final_color, 1.0);
        //     }
        //     ENDCG
        // }
    }
}
