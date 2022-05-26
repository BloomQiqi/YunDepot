// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Teleport"
{
	Properties
	{
		_Cutoff( "Mask Clip Value", Float ) = 0.1
		_BaseMap("BaseMap", 2D) = "white" {}
		_NormalMap("NormalMap", 2D) = "bump" {}
		_CompMask("CompMask", 2D) = "white" {}
		_MetallicAdjust("MetallicAdjust", Range( -1 , 1)) = 0
		_SmoothnessAdjust("SmoothnessAdjust", Range( -1 , 1)) = 0
		_DissolveAmount("DissolveAmount", Float) = 0
		_DissolveOffset("DissolveOffset", Float) = 0
		_DissolveSpread("DissolveSpread", Float) = 1
		_NoiseScale("NoiseScale", Vector) = (0,0,0,0)
		[Gamma]_EdgeColor("EdgeColor", Color) = (0,0,0,0)
		_EdgeOffset("EdgeOffset", Float) = 0
		_EdgeColorIntensity("EdgeColorIntensity", Float) = 1
		_EdgeSpread("EdgeSpread", Float) = 2
		_VertexOffset("VertexOffset", Float) = 0
		_VertexSpread("VertexSpread", Float) = 1
		_VertexOffsetIntensity("VertexOffsetIntensity", Float) = 1
		_RimControl("RimControl", Range( 0 , 1)) = 0
		_RimIntensity("RimIntensity", Float) = 1
		_EmissTex("EmissTex", 2D) = "black" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "AlphaTest+0" }
		Cull Back
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "UnityCG.cginc"
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
			float3 worldNormal;
			INTERNAL_DATA
			float2 uv_texcoord;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		uniform float _DissolveAmount;
		uniform float _VertexOffset;
		uniform float _VertexSpread;
		uniform float _VertexOffsetIntensity;
		uniform float _DissolveOffset;
		uniform float _DissolveSpread;
		uniform float3 _NoiseScale;
		uniform sampler2D _BaseMap;
		uniform float4 _BaseMap_ST;
		uniform sampler2D _NormalMap;
		uniform float4 _NormalMap_ST;
		uniform float _MetallicAdjust;
		uniform sampler2D _CompMask;
		SamplerState sampler_CompMask;
		uniform float4 _CompMask_ST;
		uniform float _SmoothnessAdjust;
		uniform float _RimControl;
		uniform float _EdgeOffset;
		uniform float _EdgeSpread;
		uniform float4 _EdgeColor;
		uniform float _EdgeColorIntensity;
		uniform float _RimIntensity;
		uniform sampler2D _EmissTex;
		uniform float4 _EmissTex_ST;
		uniform float _Cutoff = 0.1;


		float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }

		float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }

		float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }

		float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }

		float snoise( float3 v )
		{
			const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
			float3 i = floor( v + dot( v, C.yyy ) );
			float3 x0 = v - i + dot( i, C.xxx );
			float3 g = step( x0.yzx, x0.xyz );
			float3 l = 1.0 - g;
			float3 i1 = min( g.xyz, l.zxy );
			float3 i2 = max( g.xyz, l.zxy );
			float3 x1 = x0 - i1 + C.xxx;
			float3 x2 = x0 - i2 + C.yyy;
			float3 x3 = x0 - 0.5;
			i = mod3D289( i);
			float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
			float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
			float4 x_ = floor( j / 7.0 );
			float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
			float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
			float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
			float4 h = 1.0 - abs( x ) - abs( y );
			float4 b0 = float4( x.xy, y.xy );
			float4 b1 = float4( x.zw, y.zw );
			float4 s0 = floor( b0 ) * 2.0 + 1.0;
			float4 s1 = floor( b1 ) * 2.0 + 1.0;
			float4 sh = -step( h, 0.0 );
			float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
			float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
			float3 g0 = float3( a0.xy, h.x );
			float3 g1 = float3( a0.zw, h.y );
			float3 g2 = float3( a1.xy, h.z );
			float3 g3 = float3( a1.zw, h.w );
			float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
			g0 *= norm.x;
			g1 *= norm.y;
			g2 *= norm.z;
			g3 *= norm.w;
			float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
			m = m* m;
			m = m* m;
			float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
			return 42.0 * dot( m, px);
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float3 ase_worldPos = mul( unity_ObjectToWorld, v.vertex );
			float3 objToWorld18 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float temp_output_19_0 = ( ase_worldPos.y - objToWorld18.y );
			float simplePerlin3D91 = snoise( ( ase_worldPos * float3(10,10,10) ) );
			simplePerlin3D91 = simplePerlin3D91*0.5 + 0.5;
			float3 worldToObj82 = mul( unity_WorldToObject, float4( ( ( max( ( ( ( temp_output_19_0 + _DissolveAmount ) - _VertexOffset ) / _VertexSpread ) , 0.0 ) * float3(0,1,0) * _VertexOffsetIntensity * simplePerlin3D91 ) + ase_worldPos ), 1 ) ).xyz;
			float3 ase_vertex3Pos = v.vertex.xyz;
			float3 VertexOffset83 = ( worldToObj82 - ase_vertex3Pos );
			v.vertex.xyz += VertexOffset83;
			v.vertex.w = 1;
		}

		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			float3 ase_worldPos = i.worldPos;
			float3 objToWorld18 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float temp_output_19_0 = ( ase_worldPos.y - objToWorld18.y );
			float temp_output_24_0 = ( ( ( ( 1.0 - temp_output_19_0 ) - _DissolveAmount ) - _DissolveOffset ) / _DissolveSpread );
			float smoothstepResult59 = smoothstep( 0.8 , 1.0 , temp_output_24_0);
			float simplePerlin3D30 = snoise( ( ase_worldPos * _NoiseScale ) );
			simplePerlin3D30 = simplePerlin3D30*0.5 + 0.5;
			float clampResult58 = clamp( ( smoothstepResult59 + ( temp_output_24_0 - simplePerlin3D30 ) ) , 0.0 , 1.0 );
			float DissolveValue37 = clampResult58;
			SurfaceOutputStandard s1 = (SurfaceOutputStandard ) 0;
			float2 uv_BaseMap = i.uv_texcoord * _BaseMap_ST.xy + _BaseMap_ST.zw;
			float3 gammaToLinear12 = GammaToLinearSpace( tex2D( _BaseMap, uv_BaseMap ).rgb );
			s1.Albedo = gammaToLinear12;
			float2 uv_NormalMap = i.uv_texcoord * _NormalMap_ST.xy + _NormalMap_ST.zw;
			float3 TangentNormal106 = UnpackNormal( tex2D( _NormalMap, uv_NormalMap ) );
			s1.Normal = WorldNormalVector( i , TangentNormal106 );
			s1.Emission = float3( 0,0,0 );
			float2 uv_CompMask = i.uv_texcoord * _CompMask_ST.xy + _CompMask_ST.zw;
			float4 tex2DNode4 = tex2D( _CompMask, uv_CompMask );
			float clampResult10 = clamp( ( _MetallicAdjust + tex2DNode4.r ) , 0.0 , 1.0 );
			s1.Metallic = clampResult10;
			float clampResult11 = clamp( ( ( 1.0 - tex2DNode4.g ) + _SmoothnessAdjust ) , 0.0 , 1.0 );
			s1.Smoothness = clampResult11;
			s1.Occlusion = 1.0;

			data.light = gi.light;

			UnityGI gi1 = gi;
			#ifdef UNITY_PASS_FORWARDBASE
			Unity_GlossyEnvironmentData g1 = UnityGlossyEnvironmentSetup( s1.Smoothness, data.worldViewDir, s1.Normal, float3(0,0,0));
			gi1 = UnityGlobalIllumination( data, s1.Occlusion, s1.Normal, g1 );
			#endif

			float3 surfResult1 = LightingStandard ( s1, viewDir, gi1 ).rgb;
			surfResult1 += s1.Emission;

			#ifdef UNITY_PASS_FORWARDADD//1
			surfResult1 -= s1.Emission;
			#endif//1
			float3 linearToGamma62 = LinearToGammaSpace( surfResult1 );
			float RimControl115 = _RimControl;
			float3 PBRLighting15 = ( linearToGamma62 * RimControl115 );
			float smoothstepResult56 = smoothstep( 0.0 , 1.0 , ( pow( ( 1.0 - distance( temp_output_24_0 , _EdgeOffset ) ) , _EdgeSpread ) - simplePerlin3D30 ));
			float4 DissolveEdgeColor52 = ( smoothstepResult56 * ( _EdgeColor * _EdgeColorIntensity ) );
			float DissolveEdge67 = smoothstepResult56;
			float4 lerpResult65 = lerp( float4( PBRLighting15 , 0.0 ) , DissolveEdgeColor52 , DissolveEdge67);
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float dotResult95 = dot( (WorldNormalVector( i , TangentNormal106 )) , ase_worldViewDir );
			float clampResult98 = clamp( ( ( 1.0 - dotResult95 ) - (RimControl115*2.0 + -1.0) ) , 0.0 , 1.0 );
			float2 uv_EmissTex = i.uv_texcoord * _EmissTex_ST.xy + _EmissTex_ST.zw;
			float4 color102 = IsGammaSpace() ? float4(0,1,1,1) : float4(0,1,1,1);
			float4 RimEmiss103 = ( _RimIntensity * ( clampResult98 + ( clampResult98 * tex2D( _EmissTex, uv_EmissTex ) ) ) * color102 );
			c.rgb = ( lerpResult65 + RimEmiss103 ).rgb;
			c.a = 1;
			clip( DissolveValue37 - _Cutoff );
			return c;
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			o.Normal = float3(0,0,1);
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows vertex:vertexDataFunc 

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
				SurfaceOutputCustomLightingCustom o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputCustomLightingCustom, o )
				surf( surfIN, o );
				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT( UnityGI, gi );
				o.Alpha = LightingStandardCustomLighting( o, worldViewDir, gi ).a;
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
19.2;344;1523;757;-633.5073;-2118.921;1.393094;True;False
Node;AmplifyShaderEditor.WorldPosInputsNode;17;-2142.1,962.5014;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformPositionNode;18;-2165.101,1141.501;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleSubtractOpNode;19;-1905.102,1055.501;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;69;-1595.138,893.1561;Inherit;False;3486.469;1097.677;Dissolve;28;20;23;22;47;43;46;42;44;63;51;57;64;58;37;41;24;25;60;59;30;29;56;49;52;67;48;55;66;Disslove;0.2783019,0.8947987,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;14;-1455.059,-217.0928;Inherit;False;1836.425;848.717;PBRLighting;17;15;117;62;116;1;11;10;12;7;5;2;9;6;8;4;106;3;PBRLighting;0.764151,0.5442774,0.5442774,1;0;0
Node;AmplifyShaderEditor.SamplerNode;3;-1404.307,38.3811;Inherit;True;Property;_NormalMap;NormalMap;2;0;Create;True;0;0;False;0;False;-1;None;77b91526e481d164aa4fee6e8b5fc94c;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;21;-1931.792,1381.982;Inherit;False;Property;_DissolveAmount;DissolveAmount;6;0;Create;True;0;0;False;0;False;0;0.34;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;41;-1395.112,1068.182;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;23;-979.694,1192.065;Inherit;False;Property;_DissolveOffset;DissolveOffset;7;0;Create;True;0;0;False;0;False;0;-0.4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;20;-1137.963,1067.324;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;118;894.835,2159.692;Inherit;False;2101.88;591.0061;RimEmiss;17;107;109;93;115;95;97;114;108;111;98;112;110;102;100;99;103;96;RimEmiss;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;106;-1015.38,67.35309;Inherit;False;TangentNormal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;107;944.835,2224.5;Inherit;False;106;TangentNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;25;-759.8407,1194.24;Inherit;False;Property;_DissolveSpread;DissolveSpread;8;0;Create;True;0;0;False;0;False;1;1.29;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;22;-824.5535,1065.936;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;93;1201.009,2220.797;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;109;984.2804,2572.916;Inherit;False;Property;_RimControl;RimControl;17;0;Create;True;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;96;1217.951,2359.384;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;4;-1403.538,254.9519;Inherit;True;Property;_CompMask;CompMask;3;0;Create;True;0;0;False;0;False;-1;None;a7f745220fb33f946a159d308f6c7308;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;24;-550.6815,1068.851;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;47;-14.42097,1433.488;Inherit;False;Property;_EdgeOffset;EdgeOffset;11;0;Create;True;0;0;False;0;False;0;0.33;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;92;-1570.941,2217.33;Inherit;False;2338.266;780.0439;VertexOffset;19;71;70;90;73;88;72;74;89;76;79;78;91;77;80;82;87;84;83;81;VertexOffset;0.4352388,0.4009434,1,1;0;0
Node;AmplifyShaderEditor.Vector3Node;43;-900.447,1568.73;Inherit;False;Property;_NoiseScale;NoiseScale;9;0;Create;True;0;0;False;0;False;0,0,0;334.74,1,1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DistanceOpNode;46;216.8171,1347.452;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;70;-1520.941,2267.33;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;42;-908.447,1394.73;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.OneMinusNode;8;-1049.279,396.5533;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;115;1279.247,2573.381;Inherit;False;RimControl;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;71;-1293.957,2391.112;Inherit;False;Property;_VertexOffset;VertexOffset;14;0;Create;True;0;0;False;0;False;0;0.38;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;95;1502.951,2328.384;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;9;-1103.121,480.169;Inherit;False;Property;_SmoothnessAdjust;SmoothnessAdjust;5;0;Create;True;0;0;False;0;False;0;0.55;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;6;-1114.079,206.1481;Inherit;False;Property;_MetallicAdjust;MetallicAdjust;4;0;Create;True;0;0;False;0;False;0;0.45;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;48;432.6525,1371.275;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;90;-1412.535,2811.774;Inherit;False;Constant;_VertexOffsetNoise;VertexOffsetNoise;17;0;Create;True;0;0;False;0;False;10,10,10;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;66;389.6096,1460.99;Inherit;False;Property;_EdgeSpread;EdgeSpread;13;0;Create;True;0;0;False;0;False;2;0.68;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;72;-1065.504,2397.688;Inherit;False;Property;_VertexSpread;VertexSpread;15;0;Create;True;0;0;False;0;False;1;1.45;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;88;-1361.52,2656.115;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;44;-700.991,1461.659;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;7;-823.3575,419.7919;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;2;-1405.059,-167.0928;Inherit;True;Property;_BaseMap;BaseMap;1;0;Create;True;0;0;False;0;False;-1;None;f7549f6cf82871c439168b7599da3968;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;114;1509.347,2564.284;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;97;1649.951,2328.384;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;73;-1119.617,2271.384;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;5;-842.2925,263.3864;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;55;638.6833,1422.638;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;3.46;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;30;-524.9812,1448.578;Inherit;False;Simplex3D;True;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;89;-1118.22,2741.138;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GammaToLinearNode;12;-924.3723,-136.927;Inherit;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;74;-845.7445,2272.698;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;11;-661.931,416.1423;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;10;-680.931,249.1423;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;108;1826.303,2335.551;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;57;901.1763,1518.466;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;51;815.0804,1665.03;Inherit;False;Property;_EdgeColor;EdgeColor;10;1;[Gamma];Create;True;0;0;False;0;False;0,0,0,0;0,0.6882107,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NoiseGeneratorNode;91;-921.2449,2743.753;Inherit;False;Simplex3D;True;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomStandardSurface;1;-613.4136,-61.32878;Inherit;False;Metallic;Tangent;6;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,1;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector3Node;78;-747.6573,2393.261;Inherit;False;Constant;_Vector0;Vector 0;16;0;Create;True;0;0;False;0;False;0,1,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMaxOpNode;76;-670.3888,2298.431;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;111;1828.387,2520.698;Inherit;True;Property;_EmissTex;EmissTex;19;0;Create;True;0;0;False;0;False;-1;None;668fcaed21c1ad143a5b2782b04ad025;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ClampOpNode;98;2023.323,2346.158;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;63;835.4261,1856.433;Inherit;False;Property;_EdgeColorIntensity;EdgeColorIntensity;12;0;Create;True;0;0;False;0;False;1;1.66;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;79;-861.1942,2544.547;Inherit;False;Property;_VertexOffsetIntensity;VertexOffsetIntensity;16;0;Create;True;0;0;False;0;False;1;7.28;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;116;-279.8917,99.38632;Inherit;False;115;RimControl;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;56;1053.822,1473.767;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;64;1101.426,1737.433;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LinearToGammaNode;62;-207.6645,-69.27452;Inherit;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;112;2161.244,2420.091;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldPosInputsNode;81;-329.9426,2574.146;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;77;-494.476,2361.238;Inherit;True;4;4;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;49;1309.58,1484.092;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SmoothstepOpNode;59;-260.634,943.1561;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.8;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;80;-120.4896,2447.911;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;29;-201.8605,1074.663;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;100;2283.096,2209.692;Inherit;False;Property;_RimIntensity;RimIntensity;18;0;Create;True;0;0;False;0;False;1;0.48;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;102;2252.619,2515.411;Inherit;False;Constant;_RimColor;RimColor;17;2;[HDR];[Gamma];Create;True;0;0;False;0;False;0,1,1,1;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;110;2292.936,2355.361;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;117;-21.05066,28.31002;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;67;1221.274,1358.668;Inherit;False;DissolveEdge;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;82;43.78841,2458.915;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;15;140.1415,-40.46383;Inherit;False;PBRLighting;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PosVertexDataNode;87;74.26052,2645.068;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;60;-37.80181,975.596;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;52;1640.131,1495.953;Inherit;False;DissolveEdgeColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;99;2505.865,2351.309;Inherit;False;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;84;349.0608,2535.173;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;54;865.395,459.2533;Inherit;False;52;DissolveEdgeColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;103;2771.915,2363.766;Inherit;False;RimEmiss;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;58;136.4434,1119.01;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;16;896.9975,366.421;Inherit;False;15;PBRLighting;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;68;981.668,543.9243;Inherit;False;67;DissolveEdge;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;65;1188.09,390.211;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;83;542.5249,2459.718;Inherit;False;VertexOffset;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;104;1027.247,635.5247;Inherit;False;103;RimEmiss;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;37;465.2183,1158.398;Inherit;False;DissolveValue;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;86;1536.585,526.6863;Inherit;False;83;VertexOffset;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;105;1362.247,484.5247;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;38;895.7416,268.7172;Inherit;False;37;DissolveValue;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1834.681,80.22494;Float;False;True;-1;2;ASEMaterialInspector;0;0;CustomLighting;Teleport;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.1;True;True;0;True;Transparent;;AlphaTest;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;0;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;19;0;17;2
WireConnection;19;1;18;2
WireConnection;41;0;19;0
WireConnection;20;0;41;0
WireConnection;20;1;21;0
WireConnection;106;0;3;0
WireConnection;22;0;20;0
WireConnection;22;1;23;0
WireConnection;93;0;107;0
WireConnection;24;0;22;0
WireConnection;24;1;25;0
WireConnection;46;0;24;0
WireConnection;46;1;47;0
WireConnection;70;0;19;0
WireConnection;70;1;21;0
WireConnection;8;0;4;2
WireConnection;115;0;109;0
WireConnection;95;0;93;0
WireConnection;95;1;96;0
WireConnection;48;0;46;0
WireConnection;44;0;42;0
WireConnection;44;1;43;0
WireConnection;7;0;8;0
WireConnection;7;1;9;0
WireConnection;114;0;115;0
WireConnection;97;0;95;0
WireConnection;73;0;70;0
WireConnection;73;1;71;0
WireConnection;5;0;6;0
WireConnection;5;1;4;1
WireConnection;55;0;48;0
WireConnection;55;1;66;0
WireConnection;30;0;44;0
WireConnection;89;0;88;0
WireConnection;89;1;90;0
WireConnection;12;0;2;0
WireConnection;74;0;73;0
WireConnection;74;1;72;0
WireConnection;11;0;7;0
WireConnection;10;0;5;0
WireConnection;108;0;97;0
WireConnection;108;1;114;0
WireConnection;57;0;55;0
WireConnection;57;1;30;0
WireConnection;91;0;89;0
WireConnection;1;0;12;0
WireConnection;1;1;106;0
WireConnection;1;3;10;0
WireConnection;1;4;11;0
WireConnection;76;0;74;0
WireConnection;98;0;108;0
WireConnection;56;0;57;0
WireConnection;64;0;51;0
WireConnection;64;1;63;0
WireConnection;62;0;1;0
WireConnection;112;0;98;0
WireConnection;112;1;111;0
WireConnection;77;0;76;0
WireConnection;77;1;78;0
WireConnection;77;2;79;0
WireConnection;77;3;91;0
WireConnection;49;0;56;0
WireConnection;49;1;64;0
WireConnection;59;0;24;0
WireConnection;80;0;77;0
WireConnection;80;1;81;0
WireConnection;29;0;24;0
WireConnection;29;1;30;0
WireConnection;110;0;98;0
WireConnection;110;1;112;0
WireConnection;117;0;62;0
WireConnection;117;1;116;0
WireConnection;67;0;56;0
WireConnection;82;0;80;0
WireConnection;15;0;117;0
WireConnection;60;0;59;0
WireConnection;60;1;29;0
WireConnection;52;0;49;0
WireConnection;99;0;100;0
WireConnection;99;1;110;0
WireConnection;99;2;102;0
WireConnection;84;0;82;0
WireConnection;84;1;87;0
WireConnection;103;0;99;0
WireConnection;58;0;60;0
WireConnection;65;0;16;0
WireConnection;65;1;54;0
WireConnection;65;2;68;0
WireConnection;83;0;84;0
WireConnection;37;0;58;0
WireConnection;105;0;65;0
WireConnection;105;1;104;0
WireConnection;0;10;38;0
WireConnection;0;13;105;0
WireConnection;0;11;86;0
ASEEND*/
//CHKSM=B52979394BB0964A8AECF6E14E76F451ECA4FB44