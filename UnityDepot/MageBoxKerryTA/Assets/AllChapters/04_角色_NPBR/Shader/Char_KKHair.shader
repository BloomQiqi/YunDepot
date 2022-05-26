Shader "Unlit/Char_KKHair"
{
    Properties
    {
        _HairPower("Hair Power", Float) = 1.0
        _SpecIntensity("Specular Intensity", Float) = 1.0
        _ShiftOffest("Shift Offest", Range(-1,1)) = 0.0
        _NoiseIntensity("Noise Intensity", Float) = 1.0
        _NoiseMap("Noise Map", 2D) = "white"{}
        _FlowMap("FlowMap", 2D) = "gray"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags { "LightMode"="Forwardbase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

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
                float3 pos_world : TEXCOORD1;
                float3 normal_world : TEXCOORD2;
                float3 tangent_world : TEXCOORD3;
                float3 binormal_world : TEXCOORD4;
            };

            float _HairPower;
            float _SpecIntensity;
            float _ShiftOffest;
            float _NoiseIntensity;
            sampler2D _NoiseMap;
            float4 _NoiseMap_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.pos_world = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.tangent_world = UnityObjectToWorldDir(v.tangent.xyz);
                o.normal_world = UnityObjectToWorldNormal(v.normal);
                o.binormal_world = normalize(cross(o.normal_world, o.tangent_world) * v.tangent.w);
                o.uv = _NoiseMap_ST.xy * v.texcoord + _NoiseMap_ST.zw;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half3 normal_dir = normalize(i.normal_world);
                half3 tangent_dir = normalize(i.tangent_world);
                half3 binormal_dir = normalize(i.binormal_world);
                half3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
                half3 light_dir = normalize(_WorldSpaceLightPos0.xyz);

                half shiftnoise = tex2D(_NoiseMap, i.uv).r;
                shiftnoise = (shiftnoise * 2.0 - 1.0) * _NoiseIntensity;//转换到-1,1

                half3 half_dir = normalize(view_dir + light_dir);
                half3 b_offset = normal_dir * (_ShiftOffest + shiftnoise);
                binormal_dir = normalize(binormal_dir + b_offset); //给副法线一个偏移值

                half BdotH = dot(binormal_dir, half_dir);
                half sinTH = sqrt(1.0 - BdotH * BdotH);
                half KKHair_term = pow(max(0, sinTH), _HairPower);

                half3 specular_color = KKHair_term * _LightColor0.rgb * _SpecIntensity;

                half3 final_color = specular_color;
                return half4(final_color, 1.0);
            }
            ENDCG
        }
    }
}
