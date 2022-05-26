Shader "3_01/CubeMap"
{
    Properties
    {
        _CubeMap("Cube Map", Cube) = "white"{}
        _NormalMap("Normal Map", 2D) = "bump"{}
        _NormalIntensity("Normal Intensity",Float) = 1.0
        _AOMap("AO Map", 2D) = "white"{}
        _Alpha("Alpha", Float) = 1.0
        _Expose("Expose", Float) = 1.0
        _Rotate("Rotate", Range(0,360)) = 0.0
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT; //使用w分量来确定副法线的方向性
                
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 pos_world : TEXCOORD4;
                float3 normal_world : TEXCOORD1;
                float3 tangent_world : TEXCOORD2;
                float3 binormal_world : TEXCOORD3;
            };

            samplerCUBE _CubeMap;
            float4 _CubeMap_HDR;
            sampler2D _NormalMap;
            float4 _NormalMap_ST;
            float _NormalIntensity;
            sampler2D _AOMap;
            float _Alpha;
            float _Expose;
            float _Rotate;

            float3 GetTangentToWorldNormal(float3 tangent, float3 normal, float3 binormal, float3 normaldata);

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.pos_world = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal_world = UnityObjectToWorldNormal(v.normal);
                o.uv = _NormalMap_ST.xy * v.texcoord + _NormalMap_ST.zw;
                o.tangent_world = UnityObjectToWorldDir(v.tangent.xyz);
                o.binormal_world = cross(o.normal_world, o.tangent_world) * v.tangent.w;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //归一化
                float3 tangent = normalize(i.tangent_world);
                float3 normal = normalize(i.normal_world);
                float3 binormal = normalize(i.binormal_world);
                //采样法线贴图
                float3 normaldata = normalize(UnpackNormal(tex2D(_NormalMap, i.uv)));
                normaldata.xy = normaldata.xy * _NormalIntensity;
                //将获得的法线转换到世界空间
                float3 normal_world = GetTangentToWorldNormal(tangent, binormal, normal, normaldata); //可以写成函数的形式

                float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
                float3 reflect_dir = normalize(reflect(-view_dir, normal_world));

                //角度转弧度
                float rad = _Rotate * UNITY_PI / 180;
                float2x2 m_rotate = float2x2(cos(rad), -sin(rad),
                                             sin(rad), cos(rad));
                reflect_dir.xz = mul(m_rotate, reflect_dir.xz);

                half4 color_cubemap = texCUBE(_CubeMap, reflect_dir);
                half3 color_cubemap_Decode = DecodeHDR(color_cubemap, _CubeMap_HDR); //解码 确保在移动端能拿到

                float ao = tex2D(_AOMap, i.uv).r;//ao 贴图是一张黑白贴图    ??? 为毛只乘一个分量就可以了


                float3 final_color = color_cubemap_Decode * ao * _Expose;

                return float4(final_color, 1.0);
            }

            //获取从切线空间的法线转换到世界空间的法线
            float3 GetTangentToWorldNormal(float3 tangent, float3 binormal, float3 normal, float3 normaldata)
            {

                /*
                方法 构建旋转矩阵 从切线空间变换到世界空间
                //矩阵构建
                1.求从世界空间到切线空间的旋转矩阵
                  首先我们知道，顶点的切线、副法线、法线分别代表切线空间的X、Y、Z轴，也就是说
                  我们知道了切线空间下坐标轴在世界空间坐标系下的向量值。因此，我们可以直接构建
                  从世界空间坐标系到切线空间的旋转矩阵。
                  M = (tangent.xyz)
                      (binormal.xyz)
                      (normal.xyz)
                  因为只是用来变换向量，所以不需要齐次矩阵。
                2.再来求切线空间到世界空间的旋转矩阵
                  M切到世 = M世到切 的逆矩阵
                  根据正交矩阵的成立条件，矩阵 * 矩阵的转置 = 单位矩阵，我们不难得出，M是一个正交矩阵
                  因此，M 的转置矩阵 = M 的逆矩阵
                  所以，M切到世 = M 的转置 = (tangent.x, binormal.x, normal.x)
                                            (tangent.y, binormal.y, normal.y)
                                            (tangent.z, binormal.z, normal.z)
                3.结果
                  M的转置 * normaldata = ((tangent.x + binormal.x + normal.x) * normaldata.x)
                                         ((tangent.y + binormal.y + normal.y) * normaldata.y)
                                         ((tangent.z + binormal.z + normal.z) * normaldata.z)
                4.简化后就得到下面的结果
                */
                return normalize(tangent * normaldata.x + binormal * normaldata.y + normal * normaldata.z);
            }
            ENDCG
        }
    }
}
