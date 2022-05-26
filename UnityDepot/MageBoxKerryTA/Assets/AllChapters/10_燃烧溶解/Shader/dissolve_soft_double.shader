// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "dissolve_soft"
{
	Properties
	{
		_Maintex("Maintex", 2D) = "white" {}
		_Gradient("Gradient", 2D) = "white" {}
		_ChangeAmount("ChangeAmount", Range( 0 , 1)) = 0
		_Edgewidth("Edgewidth", Range( 0 , 2)) = 0.4699722
		_EdgeColor("EdgeColor", Color) = (0,0,0,0)
		_EdgeColorIntensity("EdgeColorIntensity", Float) = 1
		[Toggle(_TIMEFLOW_ON)] _TIMEFLOW("TIMEFLOW", Float) = 1
		_Softness("Softness", Range( 0 , 0.5)) = 0.4214626
		_Spread("Spread", Range( 0 , 1)) = 0.5395431
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#pragma shader_feature_local _TIMEFLOW_ON
		struct Input
		{
			float2 uv_texcoord;
		};

		uniform sampler2D _Maintex;
		uniform float4 _Maintex_ST;
		uniform float4 _EdgeColor;
		uniform float _EdgeColorIntensity;
		uniform sampler2D _Gradient;
		SamplerState sampler_Gradient;
		uniform float4 _Gradient_ST;
		uniform float _ChangeAmount;
		uniform float _Spread;
		uniform float _Softness;
		uniform float _Edgewidth;
		SamplerState sampler_Maintex;

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float2 uv_Maintex = i.uv_texcoord * _Maintex_ST.xy + _Maintex_ST.zw;
			float4 tex2DNode1 = tex2D( _Maintex, uv_Maintex );
			float2 uv_Gradient = i.uv_texcoord * _Gradient_ST.xy + _Gradient_ST.zw;
			float mulTime26 = _Time.y * 0.5;
			#ifdef _TIMEFLOW_ON
				float staticSwitch28 = frac( mulTime26 );
			#else
				float staticSwitch28 = _ChangeAmount;
			#endif
			float Gradient23 = ( ( tex2D( _Gradient, uv_Gradient ).r - (-_Spread + (staticSwitch28 - 0.0) * (1.0 - -_Spread) / (1.0 - 0.0)) ) / _Spread );
			float clampResult17 = clamp( ( 1.0 - ( distance( Gradient23 , _Softness ) / _Edgewidth ) ) , 0.0 , 1.0 );
			float4 lerpResult21 = lerp( tex2DNode1 , ( _EdgeColor * _EdgeColorIntensity * tex2DNode1 ) , clampResult17);
			o.Emission = lerpResult21.rgb;
			float smoothstepResult29 = smoothstep( _Softness , 0.5 , Gradient23);
			o.Alpha = ( tex2DNode1.a * smoothstepResult29 );
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Unlit alpha:fade keepalpha fullforwardshadows 

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
				float3 worldPos : TEXCOORD2;
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
0;28;1536;775;2649.68;-59.68701;1.710129;True;False
Node;AmplifyShaderEditor.CommentaryNode;22;-2144.309,354.9184;Inherit;False;930.912;474.0438;Gradient;8;23;7;6;4;28;31;33;34;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleTimeNode;26;-2249.425,761.469;Inherit;False;1;0;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;6;-2156.658,612.3035;Inherit;False;Property;_ChangeAmount;ChangeAmount;2;0;Create;True;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;32;-1926.539,879.8863;Inherit;False;Property;_Spread;Spread;8;0;Create;True;0;0;False;0;False;0.5395431;0.1937922;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.FractNode;27;-2079.135,722.4024;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;28;-1843.729,596.4572;Inherit;False;Property;_TIMEFLOW;TIMEFLOW;6;0;Create;True;0;0;False;0;False;0;1;1;True;;Toggle;2;Key0;Key1;Create;True;True;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;34;-1774.902,756.6771;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;4;-2020.167,392.5289;Inherit;True;Property;_Gradient;Gradient;1;0;Create;True;0;0;False;0;False;-1;1a52ef923eabcb84cbe56f5e2a1ae548;91a691479f12f574e9bfedfb2dc5f90a;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;31;-1634.988,668.0435;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;7;-1533.894,432.8253;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;33;-1343.876,707.0746;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;23;-1319.177,452.2116;Inherit;False;Gradient;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;25;-900.7517,670.4593;Inherit;False;1036.148;427.1341;EdgeColor;5;15;13;12;16;17;;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;24;-1057.826,462.076;Inherit;True;23;Gradient;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;30;-1078.038,724.0995;Inherit;False;Property;_Softness;Softness;7;0;Create;True;0;0;False;0;False;0.4214626;0.374549;0;0.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;13;-662.4525,710.342;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;15;-732.6877,953.3935;Inherit;False;Property;_Edgewidth;Edgewidth;3;0;Create;True;0;0;False;0;False;0.4699722;0.18;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;12;-414.1752,748.007;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;19;-602.3308,141.9628;Inherit;False;Property;_EdgeColorIntensity;EdgeColorIntensity;5;0;Create;True;0;0;False;0;False;1;20.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;1;-996.6288,41.19707;Inherit;True;Property;_Maintex;Maintex;0;0;Create;True;0;0;False;0;False;-1;22f6b69afffc98441a907e29171dacff;22f6b69afffc98441a907e29171dacff;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;16;-207.8027,751.8465;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;18;-643.9126,-113.6765;Inherit;False;Property;_EdgeColor;EdgeColor;4;0;Create;True;0;0;False;0;False;0,0,0,0;1,0.4039216,0.07843138,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ClampOpNode;17;-35.40369,775.7458;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;29;-634.9118,367.9525;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-380.3728,-23.28788;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;5;-399.8513,256.8398;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;21;-190.5726,44.3121;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;3;89.19998,-20.2;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;dissolve_soft;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Transparent;0.5;True;True;0;False;Transparent;;Transparent;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;2;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;27;0;26;0
WireConnection;28;1;6;0
WireConnection;28;0;27;0
WireConnection;34;0;32;0
WireConnection;31;0;28;0
WireConnection;31;3;34;0
WireConnection;7;0;4;1
WireConnection;7;1;31;0
WireConnection;33;0;7;0
WireConnection;33;1;32;0
WireConnection;23;0;33;0
WireConnection;13;0;24;0
WireConnection;13;1;30;0
WireConnection;12;0;13;0
WireConnection;12;1;15;0
WireConnection;16;0;12;0
WireConnection;17;0;16;0
WireConnection;29;0;24;0
WireConnection;29;1;30;0
WireConnection;20;0;18;0
WireConnection;20;1;19;0
WireConnection;20;2;1;0
WireConnection;5;0;1;4
WireConnection;5;1;29;0
WireConnection;21;0;1;0
WireConnection;21;1;20;0
WireConnection;21;2;17;0
WireConnection;3;2;21;0
WireConnection;3;9;5;0
ASEEND*/
//CHKSM=ED759BCCEB94E440A2D4EA2066E8D950DF4780C7