// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "glass"
{
	Properties
	{
		_EdgeLength ( "Edge length", Range( 2, 50 ) ) = 17.4
		_MatCap("MatCap", 2D) = "white" {}
		_RefractMatCap("RefractMatCap", 2D) = "black" {}
		_RefractIntensity("RefractIntensity", Float) = 1
		_RefractColor("RefractColor", Color) = (0,0,0,0)
		_RefractColorIntensity("RefractColorIntensity", Float) = 0.5
		_DirtyMask("DirtyMask", 2D) = "black" {}
		_DecalMask("DecalMask", 2D) = "black" {}
		_ObjectPivotOffset("ObjectPivotOffset", Float) = 0
		_ObjectHeight("ObjectHeight", Float) = 1
		_ThickMap("ThickMap", 2D) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "Tessellation.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 4.6
		struct Input
		{
			float3 worldPos;
			float3 worldNormal;
			float2 uv_texcoord;
		};

		uniform sampler2D _MatCap;
		uniform float4 _RefractColor;
		uniform float _RefractColorIntensity;
		uniform sampler2D _RefractMatCap;
		uniform sampler2D _ThickMap;
		SamplerState sampler_ThickMap;
		uniform float _ObjectPivotOffset;
		uniform float _ObjectHeight;
		uniform sampler2D _DirtyMask;
		SamplerState sampler_DirtyMask;
		uniform float4 _DirtyMask_ST;
		uniform float _RefractIntensity;
		uniform sampler2D _DecalMask;
		uniform float4 _DecalMask_ST;
		SamplerState sampler_DecalMask;
		SamplerState sampler_MatCap;
		uniform float _EdgeLength;

		float4 tessFunction( appdata_full v0, appdata_full v1, appdata_full v2 )
		{
			return UnityEdgeLengthBasedTess (v0.vertex, v1.vertex, v2.vertex, _EdgeLength);
		}

		void vertexDataFunc( inout appdata_full v )
		{
		}

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldViewDir = Unity_SafeNormalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float3 ase_worldNormal = i.worldNormal;
			float3 ase_normWorldNormal = normalize( ase_worldNormal );
			float3 normalizeResult75 = normalize( mul( UNITY_MATRIX_V, float4( reflect( -ase_worldViewDir , ase_normWorldNormal ) , 0.0 ) ).xyz );
			float temp_output_78_0 = (normalizeResult75).x;
			float temp_output_79_0 = (normalizeResult75).y;
			float temp_output_81_0 = ( (normalizeResult75).z + 1.0 );
			float2 MatCapUV393 = ( ( (normalizeResult75).xy / ( sqrt( ( ( temp_output_78_0 * temp_output_78_0 ) + ( temp_output_79_0 * temp_output_79_0 ) + ( temp_output_81_0 * temp_output_81_0 ) ) ) * 2.0 ) ) + 0.5 );
			float4 tex2DNode1 = tex2D( _MatCap, MatCapUV393 );
			float dotResult30 = dot( ase_normWorldNormal , ase_worldViewDir );
			float smoothstepResult31 = smoothstep( 0.0 , 1.0 , dotResult30);
			float3 objToWorld48 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float2 appendResult58 = (float2(0.5 , ( ( ( ase_worldPos.y - objToWorld48.y ) - _ObjectPivotOffset ) / _ObjectHeight )));
			float2 uv_DirtyMask = i.uv_texcoord * _DirtyMask_ST.xy + _DirtyMask_ST.zw;
			float clampResult64 = clamp( ( ( 1.0 - smoothstepResult31 ) + tex2D( _ThickMap, appendResult58 ).r + tex2D( _DirtyMask, uv_DirtyMask ).a ) , 0.0 , 1.0 );
			float Thickness39 = clampResult64;
			float temp_output_33_0 = ( Thickness39 * _RefractIntensity );
			float4 lerpResult43 = lerp( ( _RefractColor * _RefractColorIntensity ) , ( _RefractColor * tex2D( _RefractMatCap, ( MatCapUV393 + temp_output_33_0 ) ) ) , temp_output_33_0);
			float2 uv_DecalMask = i.uv_texcoord * _DecalMask_ST.xy + _DecalMask_ST.zw;
			float4 tex2DNode65 = tex2D( _DecalMask, uv_DecalMask );
			float4 lerpResult66 = lerp( ( tex2DNode1 + lerpResult43 ) , tex2DNode65 , tex2DNode65.a);
			o.Emission = lerpResult66.rgb;
			float clampResult62 = clamp( ( tex2DNode65.a + ( tex2DNode1.r * Thickness39 ) ) , 0.0 , 1.0 );
			o.Alpha = clampResult62;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Unlit alpha:fade keepalpha fullforwardshadows vertex:vertexDataFunc tessellate:tessFunction 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 4.6
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
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float3 worldNormal : TEXCOORD3;
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
				vertexDataFunc( v );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				o.worldNormal = worldNormal;
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.worldPos = worldPos;
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
				float3 worldPos = IN.worldPos;
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = IN.worldNormal;
				SurfaceOutput o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutput, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				half alphaRef = tex3D( _DitherMaskLOD, float3( vpos.xy * 0.25, o.Alpha * 0.9375 ) ).a;
				clip( alphaRef - 0.01 );
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
475.2;166.4;1436;576;465.3322;-319.5099;1;True;False
Node;AmplifyShaderEditor.CommentaryNode;94;-3934.093,1520.176;Inherit;False;2499.48;672.1476;MatCapUV3;24;68;70;71;72;74;75;73;76;78;79;80;82;81;84;83;85;86;87;88;89;90;91;92;93;;1,1,1,1;0;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;68;-3862.802,1599.058;Inherit;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NegateNode;71;-3654.768,1604.341;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldNormalVector;70;-3884.093,1761.512;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ReflectOpNode;72;-3507.196,1680.368;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ViewMatrixNode;73;-3455.865,1570.176;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.CommentaryNode;38;-1076.148,1165.352;Inherit;False;1920.019;1092.357;Thickness;18;39;59;32;54;58;31;52;30;53;28;29;50;51;49;47;48;63;64;Thickness;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;74;-3322.282,1602.944;Inherit;False;2;2;0;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldPosInputsNode;47;-1007.884,1629.788;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NormalizeNode;75;-3163.058,1602.944;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TransformPositionNode;48;-1032.884,1807.788;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;51;-764.8837,1838.788;Inherit;False;Property;_ObjectPivotOffset;ObjectPivotOffset;12;0;Create;True;0;0;False;0;False;0;-0.005;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;49;-745.8837,1707.788;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;82;-3039.948,2076.923;Inherit;False;Constant;_Float0;Float 0;11;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;80;-3016.441,1918.365;Inherit;False;FLOAT;2;1;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;81;-2859.008,2005.84;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;50;-519.8837,1738.788;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;79;-2909.808,1820.442;Inherit;False;FLOAT;1;1;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;53;-538.8837,1868.788;Inherit;False;Property;_ObjectHeight;ObjectHeight;13;0;Create;True;0;0;False;0;False;1;0.35;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;29;-1019.148,1391.351;Inherit;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SwizzleNode;78;-2882.609,1712.35;Inherit;False;FLOAT;0;1;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;28;-1026.148,1215.351;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleDivideOpNode;52;-303.8837,1805.788;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;83;-2703.206,1997.547;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;85;-2700.578,1851.796;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;84;-2683.577,1708.395;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;30;-796.147,1315.351;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;86;-2473.836,1849.507;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;58;-125.9932,1716.002;Inherit;False;FLOAT2;4;0;FLOAT;0.5;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SmoothstepOpNode;31;-637.1469,1311.351;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;63;1.885219,1986.734;Inherit;True;Property;_DirtyMask;DirtyMask;10;0;Create;True;0;0;False;0;False;-1;None;fcb178a2380cb4b4ba0cd716b102c34c;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;32;-465.6524,1310.723;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SqrtOpNode;87;-2311.336,1865.108;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;54;26.64973,1669.609;Inherit;True;Property;_ThickMap;ThickMap;14;0;Create;True;0;0;False;0;False;-1;None;da32631fad541bc468a6a0ead8f2044a;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;89;-2365.937,1993.808;Inherit;False;Constant;_Float1;Float 1;11;0;Create;True;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;59;369.5571,1321.16;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;88;-2148.835,1872.908;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;76;-2860.854,1594.276;Inherit;False;FLOAT2;0;1;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;92;-1954.55,1898.69;Inherit;False;Constant;_Float2;Float 2;11;0;Create;True;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;90;-2046.924,1597.306;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ClampOpNode;64;539.552,1380.476;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;91;-1790.961,1755.831;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;39;675.759,1287.511;Inherit;False;Thickness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;34;-907.1332,802.5731;Inherit;False;Property;_RefractIntensity;RefractIntensity;7;0;Create;True;0;0;False;0;False;1;1.66;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;40;-891.5201,677.6223;Inherit;False;39;Thickness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;93;-1659.413,1751.755;Inherit;False;MatCapUV3;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;33;-688.7318,697.3783;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;25;-840.9145,526.0118;Inherit;False;93;MatCapUV3;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;27;-574.3319,533.1397;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;26;-320.8496,535.8947;Inherit;True;Property;_RefractMatCap;RefractMatCap;6;0;Create;True;0;0;False;0;False;-1;None;343de976318f7fd49af8a17830e8be4b;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;45;-117.638,423.886;Inherit;False;Property;_RefractColorIntensity;RefractColorIntensity;9;0;Create;True;0;0;False;0;False;0.5;-0.46;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;9;-633.2051,142.5215;Inherit;False;93;MatCapUV3;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ColorNode;41;-393.5131,341.6978;Inherit;False;Property;_RefractColor;RefractColor;8;0;Create;True;0;0;False;0;False;0,0,0,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;61;55.70631,270.4005;Inherit;False;39;Thickness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;46;57.10169,509.7708;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;44;135.1018,370.671;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;1;-411.6157,114.4021;Inherit;True;Property;_MatCap;MatCap;5;0;Create;True;0;0;False;0;False;-1;None;56e1722792e56fd4bb3ce41b23644f2e;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;60;295.3639,226.9623;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;65;697.0586,165.2428;Inherit;True;Property;_DecalMask;DecalMask;11;0;Create;True;0;0;False;0;False;-1;None;87a4dbcac0983364cb2a95568822e4db;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;43;310.6004,517.7715;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;24;-3267.295,883.8453;Inherit;False;2011.044;553.2855;MatCapUV2;12;14;12;15;11;16;13;17;18;21;20;22;23;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;35;555.3228,112.14;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;10;-2708.265,340.9633;Inherit;False;1010.523;322.4;MatCapUV;6;2;3;4;5;6;8;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;67;1004.587,359.8501;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;5;-2270.438,460.364;Inherit;False;FLOAT2;0;1;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PosVertexDataNode;14;-3217.295,933.8453;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;20;-1888.664,1178.969;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CrossProductOpNode;17;-2551.186,1176.273;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ClampOpNode;62;1216.977,309.6644;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;15;-2963.768,994.4445;Inherit;False;Object;View;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ViewMatrixNode;12;-3177.55,1326.732;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.NormalizeNode;16;-2705.298,1073.594;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;13;-2986.55,1237.732;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;22;-1718.77,1167.221;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;0.5;False;2;FLOAT;0.5;False;1;FLOAT2;0
Node;AmplifyShaderEditor.NegateNode;21;-2057.541,1204.846;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;11;-3213.55,1164.732;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;4;-2431.264,463.9633;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldNormalVector;2;-2658.265,390.9633;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;8;-1922.538,513.4221;Inherit;False;matcapuv;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ViewMatrixNode;3;-2622.265,552.9633;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.LerpOp;66;990.172,88.36084;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;6;-2117.324,493.5005;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;0.5;False;2;FLOAT;0.5;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;23;-1481.053,1165.5;Inherit;False;MatCapUV2;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BreakToComponentsNode;18;-2326.277,1178.63;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1533.91,66.03294;Float;False;True;-1;6;ASEMaterialInspector;0;0;Unlit;glass;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Transparent;0.5;True;True;0;False;Transparent;;Transparent;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;True;2;17.4;10;25;False;0.5;True;2;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;0;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;71;0;68;0
WireConnection;72;0;71;0
WireConnection;72;1;70;0
WireConnection;74;0;73;0
WireConnection;74;1;72;0
WireConnection;75;0;74;0
WireConnection;49;0;47;2
WireConnection;49;1;48;2
WireConnection;80;0;75;0
WireConnection;81;0;80;0
WireConnection;81;1;82;0
WireConnection;50;0;49;0
WireConnection;50;1;51;0
WireConnection;79;0;75;0
WireConnection;78;0;75;0
WireConnection;52;0;50;0
WireConnection;52;1;53;0
WireConnection;83;0;81;0
WireConnection;83;1;81;0
WireConnection;85;0;79;0
WireConnection;85;1;79;0
WireConnection;84;0;78;0
WireConnection;84;1;78;0
WireConnection;30;0;28;0
WireConnection;30;1;29;0
WireConnection;86;0;84;0
WireConnection;86;1;85;0
WireConnection;86;2;83;0
WireConnection;58;1;52;0
WireConnection;31;0;30;0
WireConnection;32;0;31;0
WireConnection;87;0;86;0
WireConnection;54;1;58;0
WireConnection;59;0;32;0
WireConnection;59;1;54;1
WireConnection;59;2;63;4
WireConnection;88;0;87;0
WireConnection;88;1;89;0
WireConnection;76;0;75;0
WireConnection;90;0;76;0
WireConnection;90;1;88;0
WireConnection;64;0;59;0
WireConnection;91;0;90;0
WireConnection;91;1;92;0
WireConnection;39;0;64;0
WireConnection;93;0;91;0
WireConnection;33;0;40;0
WireConnection;33;1;34;0
WireConnection;27;0;25;0
WireConnection;27;1;33;0
WireConnection;26;1;27;0
WireConnection;46;0;41;0
WireConnection;46;1;26;0
WireConnection;44;0;41;0
WireConnection;44;1;45;0
WireConnection;1;1;9;0
WireConnection;60;0;1;1
WireConnection;60;1;61;0
WireConnection;43;0;44;0
WireConnection;43;1;46;0
WireConnection;43;2;33;0
WireConnection;35;0;1;0
WireConnection;35;1;43;0
WireConnection;67;0;65;4
WireConnection;67;1;60;0
WireConnection;5;0;4;0
WireConnection;20;0;21;0
WireConnection;20;1;18;0
WireConnection;17;0;16;0
WireConnection;17;1;13;0
WireConnection;62;0;67;0
WireConnection;15;0;14;0
WireConnection;16;0;15;0
WireConnection;13;0;11;0
WireConnection;13;1;12;0
WireConnection;22;0;20;0
WireConnection;21;0;18;1
WireConnection;4;0;2;0
WireConnection;4;1;3;0
WireConnection;8;0;6;0
WireConnection;66;0;35;0
WireConnection;66;1;65;0
WireConnection;66;2;65;4
WireConnection;6;0;5;0
WireConnection;23;0;22;0
WireConnection;18;0;17;0
WireConnection;0;2;66;0
WireConnection;0;9;62;0
ASEEND*/
//CHKSM=C3543117F3663FBF5EF3B89F5C7A19291912D55D