// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Nyx_body"
{
	Properties
	{
		_NormalMap("NormalMap", 2D) = "bump" {}
		_RimColor("RimColor", Color) = (0,0,0,0)
		_RimPower("RimPower", Float) = 5
		_FlowPower("FlowPower", Float) = 5
		_RimScale("RimScale", Float) = 1
		_FlowRimScale("FlowRimScale", Float) = 1
		_RimBais("RimBais", Float) = 0
		_FlowRimBais("FlowRimBais", Float) = 0
		_EmissMap("EmissMap", 2D) = "white" {}
		_FlowTillingSpeed("FlowTillingSpeed", Vector) = (1,1,1,1)
		_FlowLightColor("FlowLightColor", Color) = (0,0,0,0)
		_CloudTex("CloudTex", 2D) = "white" {}
		_CloudTillingOffset("CloudTillingOffset", Vector) = (1,1,0,0)
		_CloudNorDistort("CloudNorDistort", Float) = 0
		_CloudPower("CloudPower", Float) = 0
		_CloudStarIntensity("CloudStarIntensity", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float3 worldNormal;
			INTERNAL_DATA
			float2 uv_texcoord;
			float3 worldPos;
		};

		uniform float4 _RimColor;
		uniform sampler2D _NormalMap;
		uniform float4 _NormalMap_ST;
		uniform float _RimPower;
		uniform float _RimScale;
		uniform float _RimBais;
		uniform sampler2D _EmissMap;
		SamplerState sampler_EmissMap;
		uniform float4 _FlowTillingSpeed;
		uniform float _FlowPower;
		uniform float _FlowRimScale;
		uniform float _FlowRimBais;
		uniform float4 _FlowLightColor;
		uniform sampler2D _CloudTex;
		uniform float4 _CloudTillingOffset;
		uniform float _CloudNorDistort;
		uniform float _CloudPower;
		uniform float _CloudStarIntensity;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			o.Normal = float3(0,0,1);
			float2 uv_NormalMap = i.uv_texcoord * _NormalMap_ST.xy + _NormalMap_ST.zw;
			float3 WorldNormal3 = normalize( (WorldNormalVector( i , UnpackNormal( tex2D( _NormalMap, uv_NormalMap ) ) )) );
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float dotResult7 = dot( WorldNormal3 , ase_worldViewDir );
			float NdotV8 = dotResult7;
			float clampResult11 = clamp( NdotV8 , 0.0 , 1.0 );
			float4 RimColor21 = ( _RimColor * ( ( pow( ( 1.0 - clampResult11 ) , _RimPower ) * _RimScale ) + _RimBais ) );
			float3 objToWorld25 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float2 panner33 = ( 1.0 * _Time.y * (_FlowTillingSpeed).zw + ( ( (NdotV8*0.5 + 0.5) + (( ase_worldPos - objToWorld25 )).xy ) * (_FlowTillingSpeed).xy ));
			float FlowLight35 = tex2D( _EmissMap, panner33 ).r;
			float clampResult53 = clamp( NdotV8 , 0.0 , 1.0 );
			float4 FlowLightColor44 = ( ( FlowLight35 * ( ( pow( ( 1.0 - clampResult53 ) , _FlowPower ) * _FlowRimScale ) + _FlowRimBais ) ) * _FlowLightColor );
			float3 ase_vertex3Pos = mul( unity_WorldToObject, float4( i.worldPos , 1 ) );
			float3 objToView58 = mul( UNITY_MATRIX_MV, float4( ase_vertex3Pos, 1 ) ).xyz;
			float3 objToView66 = mul( UNITY_MATRIX_MV, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float3 worldToViewDir70 = normalize( mul( UNITY_MATRIX_V, float4( WorldNormal3, 0 ) ).xyz );
			float4 CloudColor68 = tex2D( _CloudTex, ( float3( ( ( (( objToView58 - objToView66 )).xy * (_CloudTillingOffset).xy ) + (_CloudTillingOffset).zw ) ,  0.0 ) + ( worldToViewDir70 * _CloudNorDistort ) ).xy );
			float4 saferPower81 = max( CloudColor68 , 0.0001 );
			float4 temp_cast_2 = (_CloudPower).xxxx;
			float4 CloudStar86 = ( pow( saferPower81 , temp_cast_2 ) * pow( FlowLight35 , 2.0 ) * _CloudStarIntensity );
			o.Emission = ( RimColor21 + FlowLightColor44 + ( CloudColor68 * FlowLight35 ) + CloudStar86 ).rgb;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha fullforwardshadows 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18500
0;140;1436;663;2334.55;-2708.356;1;True;False
Node;AmplifyShaderEditor.CommentaryNode;4;-1248.118,-239.5691;Inherit;False;888.1088;280;NormalMap;3;1;2;3;WorldNormal;1,1,1,1;0;0
Node;AmplifyShaderEditor.SamplerNode;1;-1198.118,-189.5691;Inherit;True;Property;_NormalMap;NormalMap;0;0;Create;True;0;0;False;0;False;-1;None;1286e0c8d3ac62a42810b2cae9d2cfef;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldNormalVector;2;-849.9515,-183.827;Inherit;True;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CommentaryNode;9;-1245.55,125.8023;Inherit;False;741.5;366.9;NdotV;4;5;6;7;8;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;3;-584.8089,-187.2693;Inherit;False;WorldNormal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;5;-1183.85,307.1022;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;6;-1195.55,177.1023;Inherit;False;3;WorldNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;76;-1985.662,2752.813;Inherit;False;1934.01;814.5869;CloudColor;17;57;66;60;58;59;62;69;64;71;61;70;75;63;73;65;68;89;CloudColor;1,1,1,1;0;0
Node;AmplifyShaderEditor.DotProductOpNode;7;-926.4498,248.6022;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;36;-1859.544,1189.281;Inherit;False;2071.653;867.3198;FlowLight;14;35;34;33;28;32;27;31;29;26;24;25;38;39;40;FlowLight;1,1,1,1;0;0
Node;AmplifyShaderEditor.PosVertexDataNode;57;-1909.058,2802.813;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldPosInputsNode;24;-1778.815,1482.701;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;8;-728.8502,244.7022;Inherit;False;NdotV;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;66;-1935.662,3008.971;Inherit;False;Object;View;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformPositionNode;58;-1687.875,2808.109;Inherit;False;Object;View;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformPositionNode;25;-1793.84,1658.495;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleSubtractOpNode;89;-1457.55,2889.356;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;26;-1542.509,1569.047;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;38;-1674.83,1333.082;Inherit;False;8;NdotV;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;60;-1513.387,3041.861;Inherit;False;Property;_CloudTillingOffset;CloudTillingOffset;12;0;Create;True;0;0;False;0;False;1,1,0,0;0.8,0.8,2.25,-0.93;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SwizzleNode;27;-1357.509,1604.047;Inherit;False;FLOAT2;0;1;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;69;-1665.251,3274.264;Inherit;False;3;WorldNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SwizzleNode;59;-1286.734,2877.428;Inherit;False;FLOAT2;0;1;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;45;-1854.321,2133.937;Inherit;False;1850.672;562.6912;FlowLightColor;14;54;53;52;51;50;49;48;47;46;42;44;43;41;55;FlowLightColor;0.4509732,0.9056604,0.4400143,1;0;0
Node;AmplifyShaderEditor.Vector4Node;29;-1609.509,1877.047;Inherit;False;Property;_FlowTillingSpeed;FlowTillingSpeed;9;0;Create;True;0;0;False;0;False;1,1,1,1;1,1,0,0.5;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SwizzleNode;62;-1286.368,2997.305;Inherit;False;FLOAT2;0;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;39;-1441.745,1382.152;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;48;-1833.626,2392.272;Inherit;False;8;NdotV;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;40;-1231.836,1469.388;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SwizzleNode;31;-1363.509,1829.047;Inherit;False;FLOAT2;0;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TransformDirectionNode;70;-1394.682,3273.635;Inherit;False;World;View;True;Fast;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;61;-1110.469,2927.705;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;71;-1419.904,3452;Inherit;False;Property;_CloudNorDistort;CloudNorDistort;13;0;Create;True;0;0;False;0;False;0;0.05;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;22;-1858.749,588.2396;Inherit;False;1775.98;481.3004;RimColor;12;10;11;12;14;13;16;15;18;17;19;21;20;;1,0.7490196,0.482353,1;0;0
Node;AmplifyShaderEditor.SwizzleNode;64;-1287.288,3105.507;Inherit;False;FLOAT2;2;3;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;28;-1140.509,1660.047;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;10;-1808.749,761.5752;Inherit;False;8;NdotV;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;63;-933.6895,3030.752;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;75;-1118.481,3329.065;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ClampOpNode;53;-1652.417,2382.333;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;32;-1358.509,1954.047;Inherit;False;FLOAT2;2;3;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.OneMinusNode;51;-1479.182,2389.45;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;52;-1487.282,2491.951;Inherit;False;Property;_FlowPower;FlowPower;3;0;Create;True;0;0;False;0;False;5;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;11;-1576.838,759.4363;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;73;-821.5642,3249.736;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PannerNode;33;-928.1193,1729.346;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;65;-729.485,3002.205;Inherit;True;Property;_CloudTex;CloudTex;11;0;Create;True;0;0;False;0;False;-1;None;be0611c2c6c29704fb63a1fadfa2f70b;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PowerNode;49;-1288.082,2401.45;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;12;-1341.203,775.6542;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;34;-587.3559,1730.942;Inherit;True;Property;_EmissMap;EmissMap;8;0;Create;True;0;0;False;0;False;-1;None;e8afb210542483f4ea5d0a352fca0cc8;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;50;-1292.113,2519.837;Inherit;False;Property;_FlowRimScale;FlowRimScale;5;0;Create;True;0;0;False;0;False;1;0.21;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;14;-1337.603,879.4544;Inherit;False;Property;_RimPower;RimPower;2;0;Create;True;0;0;False;0;False;5;1.93;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;35;-160.9556,1749.143;Inherit;False;FlowLight;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;16;-1154.134,925.5399;Inherit;False;Property;_RimScale;RimScale;4;0;Create;True;0;0;False;0;False;1;2.42;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;46;-1106.413,2563.837;Inherit;False;Property;_FlowRimBais;FlowRimBais;7;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;13;-1154.003,808.4542;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;87;28.37248,471.9468;Inherit;False;955.7791;448.4589;CloudStarColor;8;79;82;80;81;83;85;84;86;CloudStarColor;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;47;-1119.212,2426.237;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;68;-276.4521,3029.794;Inherit;False;CloudColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;80;90.13921,521.9468;Inherit;False;68;CloudColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;82;102.7559,621.2126;Inherit;False;Property;_CloudPower;CloudPower;14;0;Create;True;0;0;False;0;False;0;3.98;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;79;78.37248,721.4784;Inherit;False;35;FlowLight;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;15;-948.7334,811.1397;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;41;-1774.604,2265.533;Inherit;False;35;FlowLight;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;18;-943.5337,954.14;Inherit;False;Property;_RimBais;RimBais;6;0;Create;True;0;0;False;0;False;0;0.08;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;54;-938.5118,2444.438;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;20;-804.4334,638.2396;Inherit;False;Property;_RimColor;RimColor;1;0;Create;True;0;0;False;0;False;0,0,0,0;1,0.7490196,0.482353,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PowerNode;81;307.7559,554.2126;Inherit;False;True;2;0;COLOR;0,0,0,0;False;1;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;85;308.4418,805.0057;Inherit;False;Property;_CloudStarIntensity;CloudStarIntensity;15;0;Create;True;0;0;False;0;False;0;5.29;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;42;-730.2387,2448.174;Inherit;False;Property;_FlowLightColor;FlowLightColor;10;0;Create;True;0;0;False;0;False;0,0,0,0;1,0.7215686,0.3411765,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;17;-731.6335,816.3402;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;43;-784.1671,2287.438;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;83;318.7559,708.2126;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;19;-517.1333,765.6395;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;55;-445.4626,2321.452;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;84;532.7559,654.2126;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;86;759.3516,657.3952;Inherit;False;CloudStar;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;21;-307.5686,768.689;Inherit;False;RimColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;44;-203.8118,2323.635;Inherit;False;FlowLightColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;77;-388.2926,299.4945;Inherit;False;35;FlowLight;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;74;-365.5258,164.9628;Inherit;False;68;CloudColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;78;-162.2926,231.4945;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;37;-331.5714,54.96921;Inherit;False;44;FlowLightColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;88;-171.9975,335.3473;Inherit;False;86;CloudStar;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;23;-297.5862,-77.64865;Inherit;False;21;RimColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;56;133.0761,11.86044;Inherit;False;4;4;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;413.1647,-28.81513;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;Nyx_body;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;2;0;1;0
WireConnection;3;0;2;0
WireConnection;7;0;6;0
WireConnection;7;1;5;0
WireConnection;8;0;7;0
WireConnection;58;0;57;0
WireConnection;89;0;58;0
WireConnection;89;1;66;0
WireConnection;26;0;24;0
WireConnection;26;1;25;0
WireConnection;27;0;26;0
WireConnection;59;0;89;0
WireConnection;62;0;60;0
WireConnection;39;0;38;0
WireConnection;40;0;39;0
WireConnection;40;1;27;0
WireConnection;31;0;29;0
WireConnection;70;0;69;0
WireConnection;61;0;59;0
WireConnection;61;1;62;0
WireConnection;64;0;60;0
WireConnection;28;0;40;0
WireConnection;28;1;31;0
WireConnection;63;0;61;0
WireConnection;63;1;64;0
WireConnection;75;0;70;0
WireConnection;75;1;71;0
WireConnection;53;0;48;0
WireConnection;32;0;29;0
WireConnection;51;0;53;0
WireConnection;11;0;10;0
WireConnection;73;0;63;0
WireConnection;73;1;75;0
WireConnection;33;0;28;0
WireConnection;33;2;32;0
WireConnection;65;1;73;0
WireConnection;49;0;51;0
WireConnection;49;1;52;0
WireConnection;12;0;11;0
WireConnection;34;1;33;0
WireConnection;35;0;34;1
WireConnection;13;0;12;0
WireConnection;13;1;14;0
WireConnection;47;0;49;0
WireConnection;47;1;50;0
WireConnection;68;0;65;0
WireConnection;15;0;13;0
WireConnection;15;1;16;0
WireConnection;54;0;47;0
WireConnection;54;1;46;0
WireConnection;81;0;80;0
WireConnection;81;1;82;0
WireConnection;17;0;15;0
WireConnection;17;1;18;0
WireConnection;43;0;41;0
WireConnection;43;1;54;0
WireConnection;83;0;79;0
WireConnection;19;0;20;0
WireConnection;19;1;17;0
WireConnection;55;0;43;0
WireConnection;55;1;42;0
WireConnection;84;0;81;0
WireConnection;84;1;83;0
WireConnection;84;2;85;0
WireConnection;86;0;84;0
WireConnection;21;0;19;0
WireConnection;44;0;55;0
WireConnection;78;0;74;0
WireConnection;78;1;77;0
WireConnection;56;0;23;0
WireConnection;56;1;37;0
WireConnection;56;2;78;0
WireConnection;56;3;88;0
WireConnection;0;2;56;0
ASEEND*/
//CHKSM=A1F4D8295E97B5BFCA0FF7EA2F1EAEF7708BD80D