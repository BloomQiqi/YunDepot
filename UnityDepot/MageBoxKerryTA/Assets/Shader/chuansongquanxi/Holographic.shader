// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Holographic"
{
	Properties
	{
		_MainColor("MainColor", Color) = (0,0,0,0)
		_MainColorIntensity("MainColorIntensity", Float) = 1
		_FlickingControl("FlickingControl", Float) = 0
		_FlickingSpeed("FlickingSpeed", Float) = 0
		_NoiseTiling("NoiseTiling", Vector) = (0,0.02,0,0)
		[Toggle]_ZWriteMode("ZWriteMode", Float) = 0
		_RimBias("RimBias", Float) = 0
		_RimScale("RimScale", Float) = 1
		_RimPower("RimPower", Float) = 5
		_NormalMap("NormalMap", 2D) = "bump" {}
		_WireFrame("WireFrame", 2D) = "white" {}
		_WireFrameIntensity("WireFrameIntensity", Float) = 0
		_Alpha("Alpha", Range( 0 , 1)) = 0.3
		_Texture0("Texture 0", 2D) = "white" {}
		_Scanline1("Scanline 1", 2D) = "white" {}
		[HDR]_Line1Color("Line 1 Color", Color) = (0,0,0,0)
		_Line1Speed("Line 1 Speed", Float) = 0
		_Line1Freq("Line 1 Freq", Float) = 1
		_Line1Width("Line 1 Width", Float) = 0
		_Line1Alpha("Line 1 Alpha", Float) = 1
		_RandomGlitchTiling("RandomGlitchTiling", Float) = 2
		_RandomGlitchVertexOffset("RandomGlitchVertexOffset", Vector) = (0,0,0,0)
		_GlitchSpeed("Glitch Speed", Float) = 0
		_GlitchFreq("Glitch Freq", Float) = 1
		_GlitchWidth("Glitch Width", Float) = 0
		_GlitchVertexOffset("GlitchVertexOffset", Vector) = (0,0,0,0)
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IsEmissive" = "true"  }
		Cull Back
		ZWrite [_ZWriteMode]
		Blend SrcAlpha OneMinusSrcAlpha
		
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
			float3 worldPos;
			float2 uv_texcoord;
			float3 worldNormal;
			INTERNAL_DATA
		};

		uniform float _ZWriteMode;
		uniform float3 _RandomGlitchVertexOffset;
		uniform float _RandomGlitchTiling;
		uniform float3 _GlitchVertexOffset;
		uniform sampler2D _Texture0;
		uniform float _GlitchFreq;
		uniform float _GlitchSpeed;
		uniform float _GlitchWidth;
		uniform float2 _NoiseTiling;
		uniform float _FlickingSpeed;
		uniform float _FlickingControl;
		uniform float _MainColorIntensity;
		uniform float4 _MainColor;
		uniform sampler2D _NormalMap;
		uniform float4 _NormalMap_ST;
		uniform float _RimBias;
		uniform float _RimScale;
		uniform float _RimPower;
		uniform sampler2D _Scanline1;
		uniform float _Line1Freq;
		uniform float _Line1Speed;
		uniform float _Line1Width;
		uniform float4 _Line1Color;
		uniform float _Line1Alpha;
		uniform sampler2D _WireFrame;
		SamplerState sampler_WireFrame;
		uniform float4 _WireFrame_ST;
		uniform float _WireFrameIntensity;
		uniform float _Alpha;


		float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }

		float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }

		float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }

		float snoise( float2 v )
		{
			const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
			float2 i = floor( v + dot( v, C.yy ) );
			float2 x0 = v - i + dot( i, C.xx );
			float2 i1;
			i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
			float4 x12 = x0.xyxy + C.xxzz;
			x12.xy -= i1;
			i = mod2D289( i );
			float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
			float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
			m = m * m;
			m = m * m;
			float3 x = 2.0 * frac( p * C.www ) - 1.0;
			float3 h = abs( x ) - 0.5;
			float3 ox = floor( x + 0.5 );
			float3 a0 = x - ox;
			m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
			float3 g;
			g.x = a0.x * x0.x + h.x * x0.y;
			g.yz = a0.yz * x12.xz + h.yz * x12.yw;
			return 130.0 * dot( m, g );
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float3 viewToObj95 = mul( unity_WorldToObject, mul( UNITY_MATRIX_I_V , float4( _RandomGlitchVertexOffset, 1 ) ) ).xyz;
			float3 ase_worldPos = mul( unity_ObjectToWorld, v.vertex );
			float mulTime87 = _Time.y * 1.69;
			float2 appendResult88 = (float2((ase_worldPos.y*_RandomGlitchTiling + mulTime87) , _Time.y));
			float simplePerlin2D90 = snoise( appendResult88 );
			simplePerlin2D90 = simplePerlin2D90*0.5 + 0.5;
			float clampResult110 = clamp( (simplePerlin2D90*2.0 + -1.0) , 0.0 , 1.0 );
			float2 uv_TexCoord104 = v.texcoord.xy * float2( 0,0.001 );
			float mulTime100 = _Time.y * 2.0;
			float simplePerlin2D106 = snoise( ( uv_TexCoord104 + ( mulTime100 * 0.28 ) )*5.0 );
			simplePerlin2D106 = simplePerlin2D106*0.5 + 0.5;
			float clampResult108 = clamp( (simplePerlin2D106*2.0 + -1.0) , 0.0 , 1.0 );
			float3 GlitchVertexOffset92 = ( ( viewToObj95 * 0.01 ) * ( clampResult110 * clampResult108 ) );
			float3 viewToObj123 = mul( unity_WorldToObject, mul( UNITY_MATRIX_I_V , float4( _GlitchVertexOffset, 1 ) ) ).xyz;
			float3 objToWorld2_g2 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float mulTime7_g2 = _Time.y * _GlitchSpeed;
			float2 appendResult9_g2 = (float2(0.5 , (( ase_worldPos.y - objToWorld2_g2.y )*_GlitchFreq + mulTime7_g2)));
			float clampResult23_g2 = clamp( ( ( tex2Dlod( _Texture0, float4( appendResult9_g2, 0, 0.0) ).r - _GlitchWidth ) * 1.0 ) , 0.0 , 1.0 );
			float3 ScanlineGlitch125 = ( ( viewToObj123 * 0.01 ) * clampResult23_g2 );
			v.vertex.xyz += ( GlitchVertexOffset92 + ScanlineGlitch125 );
			v.vertex.w = 1;
		}

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			o.Normal = float3(0,0,1);
			float2 uv_TexCoord3 = i.uv_texcoord * _NoiseTiling;
			float simplePerlin2D14 = snoise( ( uv_TexCoord3 + ( _Time.y * _FlickingSpeed ) )*10.0 );
			simplePerlin2D14 = simplePerlin2D14*0.5 + 0.5;
			float clampResult13 = clamp( (-0.5 + (simplePerlin2D14 - 0.0) * (1.0 - -0.5) / (1.0 - 0.0)) , 0.0 , 1.0 );
			float lerpResult44 = lerp( 1.0 , clampResult13 , _FlickingControl);
			float Flicking10 = lerpResult44;
			float4 temp_output_41_0 = ( _MainColorIntensity * _MainColor );
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float2 uv_NormalMap = i.uv_texcoord * _NormalMap_ST.xy + _NormalMap_ST.zw;
			float fresnelNdotV18 = dot( normalize( (WorldNormalVector( i , UnpackNormal( tex2D( _NormalMap, uv_NormalMap ) ) )) ), ase_worldViewDir );
			float fresnelNode18 = ( _RimBias + _RimScale * pow( max( 1.0 - fresnelNdotV18 , 0.0001 ), _RimPower ) );
			float FresnelFactor26 = max( fresnelNode18 , 0.0 );
			float3 objToWorld2_g1 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float mulTime7_g1 = _Time.y * _Line1Speed;
			float2 appendResult9_g1 = (float2(0.5 , (( ase_worldPos.y - objToWorld2_g1.y )*_Line1Freq + mulTime7_g1)));
			float clampResult23_g1 = clamp( ( ( tex2D( _Scanline1, appendResult9_g1 ).r - _Line1Width ) * 1.0 ) , 0.0 , 1.0 );
			float temp_output_69_0 = clampResult23_g1;
			float4 ScanlineColor58 = max( ( temp_output_69_0 * _Line1Color ) , float4( 0,0,0,0 ) );
			o.Emission = ( Flicking10 * ( temp_output_41_0 + ( temp_output_41_0 * FresnelFactor26 ) + ScanlineColor58 ) ).rgb;
			float ScanlineAlpha78 = ( temp_output_69_0 * _Line1Alpha );
			float clampResult38 = clamp( ( _MainColor.a + FresnelFactor26 + ScanlineAlpha78 ) , 0.0 , 1.0 );
			float2 uv_WireFrame = i.uv_texcoord * _WireFrame_ST.xy + _WireFrame_ST.zw;
			float WireFrame31 = ( tex2D( _WireFrame, uv_WireFrame ).r * _WireFrameIntensity );
			o.Alpha = ( clampResult38 * WireFrame31 * _Alpha );
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Unlit keepalpha fullforwardshadows vertex:vertexDataFunc 

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
			sampler3D _DitherMaskLOD;
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
				vertexDataFunc( v, customInputData );
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
-105.6;275.2;1523;790;338.1953;-2139.201;1;True;False
Node;AmplifyShaderEditor.CommentaryNode;112;-11.6001,1043.037;Inherit;False;2436.465;1057.223;RandomGlitch;25;86;87;101;102;84;100;104;89;85;103;88;105;106;90;107;93;91;99;95;108;110;109;98;96;92;RandomGlitch;0.6747429,0.8396226,0.5742702,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;9;-1929.575,-384.4764;Inherit;False;1598.03;492.0575;Flicking;12;14;5;13;3;7;15;12;8;10;4;44;45;Flicking;0.9811321,0.754361,0.754361,1;0;0
Node;AmplifyShaderEditor.SimpleTimeNode;100;450.6245,1866.454;Inherit;False;1;0;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;84;38.3999,1224.465;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector2Node;102;335.8911,1730.142;Inherit;False;Constant;_Vector0;Vector 0;5;0;Create;True;0;0;False;0;False;0,0.001;0,0.02;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;101;442.2988,1984.86;Inherit;False;Constant;_Float1;Float 1;4;0;Create;True;0;0;False;0;False;0.28;0.36;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;87;49.25702,1482.73;Inherit;False;1;0;FLOAT;1.69;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;86;59.25702,1387.73;Inherit;False;Property;_RandomGlitchTiling;RandomGlitchTiling;21;0;Create;True;0;0;False;0;False;2;3.45;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;15;-1896.143,-320.5605;Inherit;False;Property;_NoiseTiling;NoiseTiling;5;0;Create;True;0;0;False;0;False;0,0.02;0,0.02;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.ScaleAndOffsetNode;85;373.257,1299.73;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;103;638.3877,1932.86;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;8;-1705.91,-63.66468;Inherit;False;Property;_FlickingSpeed;FlickingSpeed;4;0;Create;True;0;0;False;0;False;0;0.29;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;27;-1930.726,141.7518;Inherit;False;1511.507;630.2799;Fresnel;9;20;21;22;23;19;24;18;25;26;Fresnel;0.7351531,0.3152367,0.8679245,1;0;0
Node;AmplifyShaderEditor.SimpleTimeNode;89;551.2571,1545.929;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;4;-1698.673,-180.9825;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;104;511.9562,1727.618;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;24;-1880.726,191.7518;Inherit;True;Property;_NormalMap;NormalMap;10;0;Create;True;0;0;False;0;False;-1;None;8328eb67463c40040a0b54e189bb516b;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;105;774.3613,1780.72;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;88;722.257,1355.73;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;3;-1720.078,-323.0838;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;83;-1918.202,1332.912;Inherit;False;1591.963;606.4;Scanline;13;70;72;63;71;64;69;76;77;78;74;82;58;75;Scanline;0.8301887,0.4816661,0.4816661,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;7;-1510.91,-115.6646;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;22;-1511.515,581.6317;Inherit;False;Property;_RimScale;RimScale;8;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;21;-1508.515,504.6318;Inherit;False;Property;_RimBias;RimBias;7;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;128;198.0984,2196.601;Inherit;False;1566.983;726.9351;ScanlineGlitch;12;121;123;114;113;116;117;122;115;118;119;120;125;ScanlineGlitch;0.6185708,0.8867924,0.4726771,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;72;-1860.202,1823.912;Inherit;False;Constant;_Line1Hardness;Line 1 Hardness;20;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;71;-1856.202,1742.912;Inherit;False;Property;_Line1Width;Line 1 Width;19;0;Create;True;0;0;False;0;False;0;-0.06;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;20;-1521.515,350.6318;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldNormalVector;19;-1523.515,200.6317;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NoiseGeneratorNode;90;951.257,1376.73;Inherit;True;Simplex2D;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;70;-1868.202,1382.912;Inherit;True;Property;_Scanline1;Scanline 1;15;0;Create;True;0;0;False;0;False;None;afb16754b93daf04187b10b438f7a250;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RangedFloatNode;64;-1860.894,1654.565;Inherit;False;Property;_Line1Speed;Line 1 Speed;17;0;Create;True;0;0;False;0;False;0;-0.39;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;106;960.3155,1764.835;Inherit;True;Simplex2D;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;23;-1508.515,656.6317;Inherit;False;Property;_RimPower;RimPower;9;0;Create;True;0;0;False;0;False;5;4.51;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;63;-1850.606,1576.486;Inherit;False;Property;_Line1Freq;Line 1 Freq;18;0;Create;True;0;0;False;0;False;1;1.11;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;5;-1457.673,-269.9825;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FresnelNode;18;-1148.276,228.8653;Inherit;True;Standard;WorldNormal;ViewDir;True;True;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;76;-1386.185,1822.031;Inherit;False;Property;_Line1Alpha;Line 1 Alpha;20;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;75;-1202.628,1563.981;Inherit;False;Property;_Line1Color;Line 1 Color;16;1;[HDR];Create;True;0;0;False;0;False;0,0,0,0;0,13.58203,49.17633,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NoiseGeneratorNode;14;-1272.473,-277.304;Inherit;True;Simplex2D;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;10;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;93;989.4844,1093.037;Inherit;False;Property;_RandomGlitchVertexOffset;RandomGlitchVertexOffset;22;0;Create;True;0;0;False;0;False;0,0,0;-2,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ScaleAndOffsetNode;91;1272.781,1395.952;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;69;-1566.523,1506.351;Inherit;True;Scanline;-1;;1;02cdefd12e767d2439074263faf7ee37;0;6;20;SAMPLER2D;0;False;16;FLOAT;0;False;18;FLOAT;2;False;19;FLOAT;1;False;21;FLOAT;0;False;22;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;107;1250.985,1785.906;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;121;610.7805,2246.601;Inherit;False;Property;_GlitchVertexOffset;GlitchVertexOffset;26;0;Create;True;0;0;False;0;False;0,0,0;-1.41,1.41,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformPositionNode;123;878.7471,2283.123;Inherit;False;View;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;115;256.0984,2808.136;Inherit;False;Constant;_GlitchHardness;Glitch Hardness;20;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;122;932.0867,2440.181;Inherit;False;Constant;_Float2;Float 2;22;0;Create;True;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;117;248.0984,2367.136;Inherit;True;Property;_Texture0;Texture 0;14;0;Create;True;0;0;False;0;False;None;afb16754b93daf04187b10b438f7a250;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RangedFloatNode;116;260.0984,2727.136;Inherit;False;Property;_GlitchWidth;Glitch Width;25;0;Create;True;0;0;False;0;False;0;0.17;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;113;255.4064,2638.789;Inherit;False;Property;_GlitchSpeed;Glitch Speed;23;0;Create;True;0;0;False;0;False;0;-0.19;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;114;265.6945,2560.71;Inherit;False;Property;_GlitchFreq;Glitch Freq;24;0;Create;True;0;0;False;0;False;1;0.19;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;74;-986.344,1502.14;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TFHCRemapNode;12;-1013.275,-287.5143;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;-0.5;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;99;1310.791,1286.617;Inherit;False;Constant;_Float0;Float 0;22;0;Create;True;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;110;1557.909,1471.605;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;25;-819.0189,251.1808;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;32;-1905.689,861.0178;Inherit;False;809.9401;378.3524;WireFrame;4;28;29;30;31;WireFrame;0.6804215,0.8962264,0.5453453,1;0;0
Node;AmplifyShaderEditor.ClampOpNode;108;1469.007,1789.123;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;95;1257.451,1129.559;Inherit;False;View;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;77;-1158.427,1757.572;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;118;549.7775,2490.575;Inherit;True;Scanline;-1;;2;02cdefd12e767d2439074263faf7ee37;0;6;20;SAMPLER2D;0;False;16;FLOAT;0;False;18;FLOAT;2;False;19;FLOAT;1;False;21;FLOAT;0;False;22;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;119;1099.199,2336.078;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;78;-937.1152,1751.125;Inherit;False;ScanlineAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;28;-1855.689,911.0178;Inherit;True;Property;_WireFrame;WireFrame;11;0;Create;True;0;0;False;0;False;-1;None;668fcaed21c1ad143a5b2782b04ad025;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;109;1687.258,1626.999;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;13;-829.4872,-285.9404;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;29;-1769.389,1123.97;Inherit;False;Property;_WireFrameIntensity;WireFrameIntensity;12;0;Create;True;0;0;False;0;False;0;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;26;-644.0187,261.1808;Inherit;False;FresnelFactor;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;45;-875.7566,-98.37643;Inherit;False;Property;_FlickingControl;FlickingControl;3;0;Create;True;0;0;False;0;False;0;0.65;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;42;-210.7626,-85.49124;Inherit;False;Property;_MainColorIntensity;MainColorIntensity;2;0;Create;True;0;0;False;0;False;1;2.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;1;-328.9506,1.680561;Inherit;False;Property;_MainColor;MainColor;1;0;Create;True;0;0;False;0;False;0,0,0,0;0.02936989,0.4675427,0.5660378,0.07843138;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMaxOpNode;82;-688.3029,1552.242;Inherit;False;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;98;1459.703,1181.214;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;33;-174.4916,205.2389;Inherit;False;26;FresnelFactor;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;30;-1520.389,1011.97;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;81;-181.8203,305.4254;Inherit;False;78;ScanlineAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;120;1245.812,2432.386;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;13.23737,-50.49124;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;96;1814.316,1267.123;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;58;-551.0393,1484.004;Inherit;False;ScanlineColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;44;-669.2938,-249.4012;Inherit;False;3;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;125;1540.281,2430.149;Inherit;False;ScanlineGlitch;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;92;2176.865,1260.788;Inherit;False;GlitchVertexOffset;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;80;180.7445,108.2405;Inherit;False;58;ScanlineColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;36;100.1351,191.1726;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;34;184.9433,14.99133;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;10;-501.953,-272.045;Inherit;True;Flicking;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;31;-1320.549,1007.522;Inherit;False;WireFrame;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;97;619.9464,289.8709;Inherit;False;92;GlitchVertexOffset;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ClampOpNode;38;250.2879,208.1646;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;35;372.0432,-42.40867;Inherit;True;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;46;96.88417,438.9295;Inherit;False;Property;_Alpha;Alpha;13;0;Create;True;0;0;False;0;False;0.3;0.536;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;39;205.5706,356.4446;Inherit;False;31;WireFrame;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;17;-58.81353,-402.8938;Inherit;False;239.6;165.4;Properties;1;16;Properties;1,0.6650944,0.6650944,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;126;634.3155,446.2049;Inherit;False;125;ScanlineGlitch;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;40;319.2388,-215.0639;Inherit;False;10;Flicking;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;6;645.5637,-172.1055;Inherit;True;2;2;0;FLOAT;1;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;37;447.2271,221.1942;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;127;862.8043,404.8453;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;16;-8.813534,-352.8938;Inherit;False;Property;_ZWriteMode;ZWriteMode;6;1;[Toggle];Create;True;0;0;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;932.1887,-102.0839;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;Holographic;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;True;16;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;True;0;True;Transparent;;Transparent;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;2;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;0;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;85;0;84;2
WireConnection;85;1;86;0
WireConnection;85;2;87;0
WireConnection;103;0;100;0
WireConnection;103;1;101;0
WireConnection;104;0;102;0
WireConnection;105;0;104;0
WireConnection;105;1;103;0
WireConnection;88;0;85;0
WireConnection;88;1;89;0
WireConnection;3;0;15;0
WireConnection;7;0;4;0
WireConnection;7;1;8;0
WireConnection;19;0;24;0
WireConnection;90;0;88;0
WireConnection;106;0;105;0
WireConnection;5;0;3;0
WireConnection;5;1;7;0
WireConnection;18;0;19;0
WireConnection;18;4;20;0
WireConnection;18;1;21;0
WireConnection;18;2;22;0
WireConnection;18;3;23;0
WireConnection;14;0;5;0
WireConnection;91;0;90;0
WireConnection;69;20;70;0
WireConnection;69;18;63;0
WireConnection;69;19;64;0
WireConnection;69;21;71;0
WireConnection;69;22;72;0
WireConnection;107;0;106;0
WireConnection;123;0;121;0
WireConnection;74;0;69;0
WireConnection;74;1;75;0
WireConnection;12;0;14;0
WireConnection;110;0;91;0
WireConnection;25;0;18;0
WireConnection;108;0;107;0
WireConnection;95;0;93;0
WireConnection;77;0;69;0
WireConnection;77;1;76;0
WireConnection;118;20;117;0
WireConnection;118;18;114;0
WireConnection;118;19;113;0
WireConnection;118;21;116;0
WireConnection;118;22;115;0
WireConnection;119;0;123;0
WireConnection;119;1;122;0
WireConnection;78;0;77;0
WireConnection;109;0;110;0
WireConnection;109;1;108;0
WireConnection;13;0;12;0
WireConnection;26;0;25;0
WireConnection;82;0;74;0
WireConnection;98;0;95;0
WireConnection;98;1;99;0
WireConnection;30;0;28;1
WireConnection;30;1;29;0
WireConnection;120;0;119;0
WireConnection;120;1;118;0
WireConnection;41;0;42;0
WireConnection;41;1;1;0
WireConnection;96;0;98;0
WireConnection;96;1;109;0
WireConnection;58;0;82;0
WireConnection;44;1;13;0
WireConnection;44;2;45;0
WireConnection;125;0;120;0
WireConnection;92;0;96;0
WireConnection;36;0;1;4
WireConnection;36;1;33;0
WireConnection;36;2;81;0
WireConnection;34;0;41;0
WireConnection;34;1;33;0
WireConnection;10;0;44;0
WireConnection;31;0;30;0
WireConnection;38;0;36;0
WireConnection;35;0;41;0
WireConnection;35;1;34;0
WireConnection;35;2;80;0
WireConnection;6;0;40;0
WireConnection;6;1;35;0
WireConnection;37;0;38;0
WireConnection;37;1;39;0
WireConnection;37;2;46;0
WireConnection;127;0;97;0
WireConnection;127;1;126;0
WireConnection;0;2;6;0
WireConnection;0;9;37;0
WireConnection;0;11;127;0
ASEEND*/
//CHKSM=7E44965A0C7A4B29BBEDDD7CAFBE98024168234C