// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ForceField_FW"
{
	Properties
	{
		_DepthFade1("DepthFade", Float) = 0
		_RimBias("RimBias", Float) = 0
		_Noise1("Noise", 2D) = "white" {}
		_RimScale("RimScale", Float) = 1
		_NoiseTiling1("NoiseTiling", Vector) = (1,1,1,0)
		_NoiseIntensity1("NoiseIntensity", Float) = 1
		_Ramp1("Ramp", 2D) = "white" {}
		_RimPower("RimPower", Float) = 5
		_HitMaxSize1("HitMaxSize", Float) = 0
		_HitSpread1("HitSpread", Float) = 1
		_RimColor("RimColor", Color) = (0.3378426,0.7604657,0.9811321,0)
		_HitFadePower1("HitFadePower", Float) = 1
		_RimIntensity("RimIntensity", Float) = 1
		_HitFadeSpread1("HitFadeSpread", Float) = 1
		_HitFadeStart1("HitFadeStart", Range( 0 , 1)) = 0
		_LineHexagon("LineHexagon", 2D) = "white" {}
		_LineHexagonIntensity("LineHexagonIntensity", Float) = 1
		_LineEmissMask("LineEmissMask", 2D) = "white" {}
		_LineEmissSpeed("LineEmissSpeed", Vector) = (0.1,0.1,0,0)
		_LineEmissIntensity("LineEmissIntensity", Float) = 1
		_AuraTex("AuraTex", 2D) = "white" {}
		_AuraSpeed("AuraSpeed", Vector) = (0.1,0.1,0,0)
		_AuraIntensity("AuraIntensity", Float) = 1
		_AuraTexMask("AuraTexMask", 2D) = "white" {}
		_AuraTexMaskIntensity("AuraTexMaskIntensity", Float) = 0.5
		_HitWaveIntensity("HitWaveIntensity", Float) = 0
		_HitWaveOffset("HitWaveOffset", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] _texcoord2( "", 2D ) = "white" {}
		[HideInInspector] _texcoord4( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#include "UnityShaderVariables.cginc"
		#include "UnityCG.cginc"
		#pragma target 4.0
		#pragma surface surf Unlit alpha:fade keepalpha noshadow vertex:vertexDataFunc 
		struct Input
		{
			float3 worldPos;
			float3 worldNormal;
			INTERNAL_DATA
			half ASEVFace : VFACE;
			float2 uv_texcoord;
			float2 uv2_texcoord2;
			float2 uv4_texcoord4;
			float4 screenPos;
		};

		uniform float4 HitPosition[20];
		uniform float HitSize[20];
		uniform float _HitMaxSize1;
		uniform sampler2D _Noise1;
		uniform float3 _NoiseTiling1;
		uniform float _NoiseIntensity1;
		uniform float _HitSpread1;
		uniform sampler2D _Ramp1;
		uniform float _HitFadeStart1;
		uniform float _HitFadeSpread1;
		uniform float _HitFadePower1;
		uniform float _HitWaveOffset;
		uniform float4 _RimColor;
		uniform float _RimIntensity;
		uniform float _RimBias;
		uniform float _RimScale;
		uniform float _RimPower;
		uniform sampler2D _LineHexagon;
		SamplerState sampler_LineHexagon;
		uniform float4 _LineHexagon_ST;
		uniform float _LineHexagonIntensity;
		uniform sampler2D _LineEmissMask;
		SamplerState sampler_LineEmissMask;
		uniform float2 _LineEmissSpeed;
		uniform float4 _LineEmissMask_ST;
		uniform float _LineEmissIntensity;
		uniform sampler2D _AuraTex;
		SamplerState sampler_AuraTex;
		uniform float2 _AuraSpeed;
		uniform float4 _AuraTex_ST;
		uniform float _AuraIntensity;
		uniform sampler2D _AuraTexMask;
		SamplerState sampler_AuraTexMask;
		uniform float4 _AuraTexMask_ST;
		uniform float _AuraTexMaskIntensity;
		uniform float _HitWaveIntensity;
		UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
		uniform float4 _CameraDepthTexture_TexelSize;
		uniform float _DepthFade1;


		inline float4 TriplanarSampling105( sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			half4 xNorm; half4 yNorm; half4 zNorm;
			xNorm = tex2Dlod( topTexMap, float4(tiling * worldPos.zy * float2(  nsign.x, 1.0 ), 0, 0) );
			yNorm = tex2Dlod( topTexMap, float4(tiling * worldPos.xz * float2(  nsign.y, 1.0 ), 0, 0) );
			zNorm = tex2Dlod( topTexMap, float4(tiling * worldPos.xy * float2( -nsign.z, 1.0 ), 0, 0) );
			return xNorm * projNormal.x + yNorm * projNormal.y + zNorm * projNormal.z;
		}


		float HitExpression_VS130( float HitMaxSize, int AffectorAmount, float3 WorldPos, int MakeZeroConst, float HitNoise, float HitSpread, sampler2D RampTex, float HitFadeStart, float HitFadeSpread, float HitFadePower )
		{
			float hit_result = 0;
			for(int j = 0; j < AffectorAmount; j++)
			{
			    float distance_mask = 1 - distance(HitPosition[j].xyz, WorldPos) - MakeZeroConst;
			    float hit_range =  saturate((distance_mask + HitSize[j] - HitNoise) / (HitSpread + 0.00001));
			    float2 ramp_uv = float2(hit_range, 0.5);
			    float hit_wave = tex2Dlod(RampTex, float4(ramp_uv,0,0)).r;
			    float hit_fade = saturate(pow( max( ( distance_mask + HitFadeStart * HitMaxSize) / (HitFadeSpread + 0.00001), 0.00001), HitFadePower));
			    hit_result = hit_result + hit_fade * hit_wave;
			}
			return saturate(hit_result);
		}


		float HitExpression118( float HitMaxSize, int AffectorAmount, float3 WorldPos, int MakeZeroConst, float HitNoise, float HitSpread, sampler2D RampTex, float HitFadeStart, float HitFadeSpread, float HitFadePower )
		{
			float hit_result = 0;
			for(int j = 0; j < AffectorAmount; j++)
			{
			    float distance_mask = 1 - distance(HitPosition[j].xyz, WorldPos) - MakeZeroConst;
			    float hit_range =  saturate((distance_mask + HitSize[j] - HitNoise) / (HitSpread + 0.00001));
			    float2 ramp_uv = float2(hit_range, 0.5);
			    float hit_wave = tex2D(RampTex, ramp_uv).r;
			    float hit_fade = saturate(pow( max( ( distance_mask + HitFadeStart * HitMaxSize) / (HitFadeSpread + 0.00001), 0.00001), HitFadePower));
			    hit_result = hit_result + hit_fade * hit_wave;
			}
			return saturate(hit_result);
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float HitMaxSize130 = _HitMaxSize1;
			int AffectorAmount130 = (int)20.0;
			float3 ase_worldPos = mul( unity_ObjectToWorld, v.vertex );
			float3 objToWorld145 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float3 temp_output_3_0_g1 = ( ase_worldPos - objToWorld145 );
			float3 ase_worldNormal = UnityObjectToWorldNormal( v.normal );
			float3 temp_output_6_0_g2 = ase_worldNormal;
			float dotResult1_g2 = dot( temp_output_3_0_g1 , temp_output_6_0_g2 );
			float dotResult2_g2 = dot( temp_output_6_0_g2 , temp_output_6_0_g2 );
			float3 PointToCenterDir148 = -( temp_output_3_0_g1 - ( ( dotResult1_g2 / dotResult2_g2 ) * temp_output_6_0_g2 ) );
			float3 HexagonCenter153 = ( ase_worldPos + PointToCenterDir148 );
			float3 WorldPos130 = HexagonCenter153;
			int MakeZeroConst130 = (int)1.0;
			float4 triplanar105 = TriplanarSampling105( _Noise1, ( ase_worldPos * _NoiseTiling1 ), ase_worldNormal, 1.0, float2( 1,1 ), 1.0, 0 );
			float4 temp_output_111_0 = ( triplanar105 * _NoiseIntensity1 );
			float HitNoise130 = temp_output_111_0.x;
			float HitSpread130 = _HitSpread1;
			sampler2D RampTex130 = _Ramp1;
			float HitFadeStart130 = _HitFadeStart1;
			float HitFadeSpread130 = _HitFadeSpread1;
			float HitFadePower130 = _HitFadePower1;
			float localHitExpression_VS130 = HitExpression_VS130( HitMaxSize130 , AffectorAmount130 , WorldPos130 , MakeZeroConst130 , HitNoise130 , HitSpread130 , RampTex130 , HitFadeStart130 , HitFadeSpread130 , HitFadePower130 );
			float HitWave_VS132 = localHitExpression_VS130;
			float3 ase_vertex3Pos = v.vertex.xyz;
			float3 HitWaveOffset140 = ( ( HitWave_VS132 * ase_vertex3Pos * 0.01 ) * _HitWaveOffset );
			v.vertex.xyz += HitWaveOffset140;
			v.vertex.w = 1;
		}

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			o.Normal = float3(0,0,1);
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 switchResult22 = (((i.ASEVFace>0)?(ase_worldNormal):(-ase_worldNormal)));
			float fresnelNdotV11 = dot( normalize( switchResult22 ), ase_worldViewDir );
			float fresnelNode11 = ( _RimBias + _RimScale * pow( max( 1.0 - fresnelNdotV11 , 0.0001 ), _RimPower ) );
			float FresnelFactor14 = fresnelNode11;
			float2 uv_LineHexagon = i.uv_texcoord * _LineHexagon_ST.xy + _LineHexagon_ST.zw;
			float4 tex2DNode24 = tex2D( _LineHexagon, uv_LineHexagon );
			float LineHexagon27 = tex2DNode24.r;
			float2 uv2_LineEmissMask = i.uv2_texcoord2 * _LineEmissMask_ST.xy + _LineEmissMask_ST.zw;
			float2 panner35 = ( 1.0 * _Time.y * _LineEmissSpeed + uv2_LineEmissMask);
			float LineEmiss41 = ( ( tex2DNode24.r * tex2D( _LineEmissMask, panner35 ).r ) * _LineEmissIntensity );
			float2 uv4_AuraTex = i.uv4_texcoord4 * _AuraTex_ST.xy + _AuraTex_ST.zw;
			float2 panner53 = ( 1.0 * _Time.y * ( _AuraSpeed * float2( 0.5,0.5 ) ) + ( uv4_AuraTex * float2( 0.2,0.2 ) ));
			float2 panner46 = ( 1.0 * _Time.y * _AuraSpeed + ( uv4_AuraTex + ( (tex2D( _AuraTex, panner53 )).rg * 0.5 ) ));
			float4 tex2DNode44 = tex2D( _AuraTex, panner46 );
			float2 uv4_AuraTexMask = i.uv4_texcoord4 * _AuraTexMask_ST.xy + _AuraTexMask_ST.zw;
			float2 panner64 = ( 1.0 * _Time.y * float2( 0.1,0.1 ) + uv4_AuraTexMask);
			float AuraColor50 = ( ( tex2DNode44.r * _AuraIntensity ) + ( tex2DNode44.r * tex2D( _AuraTexMask, panner64 ).r * _AuraTexMaskIntensity ) );
			float temp_output_29_0 = ( FresnelFactor14 + ( LineHexagon27 * _LineHexagonIntensity ) + LineEmiss41 + AuraColor50 );
			float HitMaxSize118 = _HitMaxSize1;
			int AffectorAmount118 = (int)20.0;
			float3 WorldPos118 = ase_worldPos;
			int MakeZeroConst118 = (int)1.0;
			float4 triplanar105 = TriplanarSampling105( _Noise1, ( ase_worldPos * _NoiseTiling1 ), ase_worldNormal, 1.0, float2( 1,1 ), 1.0, 0 );
			float4 temp_output_111_0 = ( triplanar105 * _NoiseIntensity1 );
			float HitNoise118 = temp_output_111_0.x;
			float HitSpread118 = _HitSpread1;
			sampler2D RampTex118 = _Ramp1;
			float HitFadeStart118 = _HitFadeStart1;
			float HitFadeSpread118 = _HitFadeSpread1;
			float HitFadePower118 = _HitFadePower1;
			float localHitExpression118 = HitExpression118( HitMaxSize118 , AffectorAmount118 , WorldPos118 , MakeZeroConst118 , HitNoise118 , HitSpread118 , RampTex118 , HitFadeStart118 , HitFadeSpread118 , HitFadePower118 );
			float HitWave119 = localHitExpression118;
			float temp_output_129_0 = ( temp_output_29_0 + ( ( temp_output_29_0 + _HitWaveIntensity ) * HitWave119 ) );
			o.Emission = ( ( _RimColor * _RimIntensity ) * temp_output_129_0 ).rgb;
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			float screenDepth69 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_screenPosNorm.xy ));
			float distanceDepth69 = abs( ( screenDepth69 - LinearEyeDepth( ase_screenPosNorm.z ) ) / ( _DepthFade1 ) );
			float clampResult122 = clamp( distanceDepth69 , 0.0 , 1.0 );
			float clampResult73 = clamp( ( temp_output_129_0 * clampResult122 ) , 0.0 , 1.0 );
			o.Alpha = clampResult73;
		}

		ENDCG
	}
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18500
188.8;182.4;1536;785;3115.065;-306.8134;1.51234;True;False
Node;AmplifyShaderEditor.CommentaryNode;142;-3983.938,1414.104;Inherit;False;3334.994;771.4148;FlowLight;21;45;47;56;54;53;52;59;57;58;60;63;46;64;49;44;66;61;48;65;67;50;FlowLight;0.375534,0.8711164,0.9150943,1;0;0
Node;AmplifyShaderEditor.Vector2Node;47;-3664.51,1669.06;Inherit;False;Property;_AuraSpeed;AuraSpeed;21;0;Create;True;0;0;False;0;False;0.1,0.1;0.02,0.035;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;45;-3933.938,1505.279;Inherit;False;3;44;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;54;-3316.155,1767.779;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;56;-3756.855,1835.38;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0.2,0.2;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;53;-3191.912,1831.327;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;52;-2980.091,1815.668;Inherit;True;Property;_TextureSample0;Texture Sample 0;20;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;44;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldPosInputsNode;143;-3107.812,2601.758;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformPositionNode;145;-3137.854,2791.643;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;59;-2644.054,1951.08;Inherit;False;Constant;_Float0;Float 0;15;0;Create;True;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;144;-2864.854,2703.643;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldNormalVector;147;-2850.854,2857.643;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SwizzleNode;57;-2659.655,1834.079;Inherit;False;FLOAT2;0;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;58;-2493.255,1861.38;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;43;-2573.06,582.1983;Inherit;False;1482.095;631.3567;LineColor;11;34;36;25;35;33;24;39;37;27;38;41;LineColor;0.9811321,0.50445,0.50445,1;0;0
Node;AmplifyShaderEditor.FunctionNode;146;-2604.854,2704.643;Inherit;False;Rejection;-1;;1;ea6ca936e02c9e74fae837451ff893c3;0;2;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;34;-2523.06,888.5181;Inherit;False;1;33;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NegateNode;151;-2406.583,2690.513;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;63;-2196.054,1834.985;Inherit;False;3;61;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;36;-2492.658,1051.355;Inherit;False;Property;_LineEmissSpeed;LineEmissSpeed;18;0;Create;True;0;0;False;0;False;0.1,0.1;0.02,0.02;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.CommentaryNode;100;-3341.205,-1277.775;Inherit;False;3627.242;1086.366;HitWave;25;121;106;120;119;118;113;110;114;111;112;116;108;117;115;105;107;103;104;102;101;130;131;132;154;155;HitWave;1,0.8254717,0.8254717,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;60;-2525.425,1492.842;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;35;-2225.658,892.3552;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WorldPosInputsNode;102;-3291.205,-854.3088;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;101;-3283.205,-676.3088;Inherit;False;Property;_NoiseTiling1;NoiseTiling;4;0;Create;True;0;0;False;0;False;1,1,1;0.1,0.1,0.2;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;148;-2226.074,2694.363;Inherit;False;PointToCenterDir;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;25;-2392.738,653.725;Inherit;False;0;24;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldPosInputsNode;150;-2190.665,2500.156;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.PannerNode;46;-2266.955,1490.315;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;64;-1888.098,1857.126;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.1,0.1;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WorldNormalVector;21;-2982.093,-4.518861;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;61;-1679.421,1847.94;Inherit;True;Property;_AuraTexMask;AuraTexMask;23;0;Create;True;0;0;False;0;False;-1;None;aeb46886909512e41842722f15bb898b;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;44;-2002.229,1464.104;Inherit;True;Property;_AuraTex;AuraTex;20;0;Create;True;0;0;False;0;False;-1;None;57451d90cad4e93448f1dbe1a84a7c70;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;152;-1905.581,2584.179;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;103;-3109.205,-763.3088;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NegateNode;23;-2761.773,63.43792;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;49;-1611.209,1556.048;Inherit;False;Property;_AuraIntensity;AuraIntensity;22;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;24;-2043.43,632.4164;Inherit;True;Property;_LineHexagon;LineHexagon;15;0;Create;True;0;0;False;0;False;-1;None;373bb7a955475ea4a82cd75a31359196;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexturePropertyNode;104;-3224.205,-1052.308;Inherit;True;Property;_Noise1;Noise;2;0;Create;True;0;0;False;0;False;None;3c506748d17579d4a85691a58877ff1e;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SamplerNode;33;-2025.42,865.309;Inherit;True;Property;_LineEmissMask;LineEmissMask;17;0;Create;True;0;0;False;0;False;-1;None;b2ebe4a36fc94024d91fe15b52fe5772;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;66;-1416.926,2070.119;Inherit;False;Property;_AuraTexMaskIntensity;AuraTexMaskIntensity;24;0;Create;True;0;0;False;0;False;0.5;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;2;-2708.789,-27.29325;Inherit;False;1481.41;404.8012;FresnelFactor;6;14;11;10;9;8;22;FresnelFactor;0.4130474,0.9622642,0.5099499,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;65;-1204.078,1852.602;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;107;-2641.86,-658.1798;Inherit;False;Property;_NoiseIntensity1;NoiseIntensity;5;0;Create;True;0;0;False;0;False;1;1.15;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;10;-2656.189,292.7386;Inherit;False;Property;_RimPower;RimPower;7;0;Create;True;0;0;False;0;False;5;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SwitchByFaceNode;22;-2627.473,6.637908;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TriplanarNode;105;-2953.205,-883.3088;Inherit;True;Spherical;World;False;Top Texture 0;_TopTexture0;white;-1;None;Mid Texture 0;_MidTexture0;white;-1;None;Bot Texture 0;_BotTexture0;white;-1;None;Triplanar Sampler;Tangent;10;0;SAMPLER2D;;False;5;FLOAT;1;False;1;SAMPLER2D;;False;6;FLOAT;0;False;2;SAMPLER2D;;False;7;FLOAT;0;False;9;FLOAT3;0,0,0;False;8;FLOAT;1;False;3;FLOAT2;1,1;False;4;FLOAT;1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;48;-1450.838,1491.45;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;9;-2656.189,216.7386;Inherit;False;Property;_RimScale;RimScale;3;0;Create;True;0;0;False;0;False;1;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;8;-2655.189,142.7387;Inherit;False;Property;_RimBias;RimBias;1;0;Create;True;0;0;False;0;False;0;0.4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;39;-1714.743,999.1279;Inherit;False;Property;_LineEmissIntensity;LineEmissIntensity;19;0;Create;True;0;0;False;0;False;1;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;153;-1707.581,2578.179;Inherit;False;HexagonCenter;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;37;-1676.393,842.2447;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;111;-2465.76,-761.2799;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;116;-1679.031,-1144.319;Inherit;False;Property;_HitMaxSize1;HitMaxSize;8;0;Create;True;0;0;False;0;False;0;8;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;67;-1158.401,1520.994;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;108;-2037.035,-746.8219;Inherit;False;Property;_HitSpread1;HitSpread;9;0;Create;True;0;0;False;0;False;1;2.57;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;27;-1682.793,632.1983;Inherit;False;LineHexagon;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;154;-2173.977,-1059.814;Inherit;False;153;HexagonCenter;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;113;-1517.075,-367.2091;Inherit;False;Property;_HitFadePower1;HitFadePower;11;0;Create;True;0;0;False;0;False;1;2.04;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;112;-1545.412,-1044.591;Inherit;False;Constant;_AffectorAmount1;AffectorAmount;10;0;Create;True;0;0;False;0;False;20;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;115;-1670.98,-765.6321;Inherit;True;Property;_Ramp1;Ramp;6;0;Create;True;0;0;False;0;False;None;256d86d8496a4e0f947100121f1fafb2;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RangedFloatNode;110;-2287.481,-878.5211;Inherit;False;Constant;_MakeZeroConst1;MakeZeroConst;9;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;114;-1722.399,-422.5438;Inherit;False;Property;_HitFadeSpread1;HitFadeSpread;13;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;117;-1714.397,-568.3069;Inherit;False;Property;_HitFadeStart1;HitFadeStart;14;0;Create;True;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;38;-1475.35,923.5915;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;11;-2416.201,22.70674;Inherit;False;Standard;WorldNormal;ViewDir;True;True;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;155;-1796.31,-1063.658;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;50;-873.7444,1477.437;Inherit;False;AuraColor;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;130;-987.7722,-633.2736;Inherit;False;float hit_result = 0@$for(int j = 0@ j < AffectorAmount@ j++)${$    float distance_mask = 1 - distance(HitPosition[j].xyz, WorldPos) - MakeZeroConst@$$    float hit_range =  saturate((distance_mask + HitSize[j] - HitNoise) / (HitSpread + 0.00001))@$$    float2 ramp_uv = float2(hit_range, 0.5)@$$    float hit_wave = tex2Dlod(RampTex, float4(ramp_uv,0,0)).r@$$    float hit_fade = saturate(pow( max( ( distance_mask + HitFadeStart * HitMaxSize) / (HitFadeSpread + 0.00001), 0.00001), HitFadePower))@$$    hit_result = hit_result + hit_fade * hit_wave@$}$$return saturate(hit_result)@;1;False;10;True;HitMaxSize;FLOAT;0;In;;Inherit;False;True;AffectorAmount;INT;20;In;;Inherit;False;True;WorldPos;FLOAT3;0,0,0;In;;Inherit;False;True;MakeZeroConst;INT;0;In;;Inherit;False;True;HitNoise;FLOAT;0;In;;Inherit;False;True;HitSpread;FLOAT;0;In;;Inherit;False;True;RampTex;SAMPLER2D;;In;;Inherit;False;True;HitFadeStart;FLOAT;0;In;;Inherit;False;True;HitFadeSpread;FLOAT;0;In;;Inherit;False;True;HitFadePower;FLOAT;0;In;;Inherit;False;HitExpression_VS;True;False;0;10;0;FLOAT;0;False;1;INT;20;False;2;FLOAT3;0,0,0;False;3;INT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;SAMPLER2D;;False;7;FLOAT;0;False;8;FLOAT;0;False;9;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;41;-1315.765,924.303;Inherit;False;LineEmiss;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;28;-55.09268,105.1657;Inherit;False;27;LineHexagon;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;31;-107.3676,238.7635;Inherit;False;Property;_LineHexagonIntensity;LineHexagonIntensity;16;0;Create;True;0;0;False;0;False;1;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;14;-1996.917,15.48662;Inherit;False;FresnelFactor;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;30;131.7986,177.7635;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;51;187.8279,386.5983;Inherit;False;50;AuraColor;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;42;137.0052,287.4901;Inherit;False;41;LineEmiss;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;118;-1024.989,-1021.716;Inherit;False;float hit_result = 0@$for(int j = 0@ j < AffectorAmount@ j++)${$    float distance_mask = 1 - distance(HitPosition[j].xyz, WorldPos) - MakeZeroConst@$$    float hit_range =  saturate((distance_mask + HitSize[j] - HitNoise) / (HitSpread + 0.00001))@$$    float2 ramp_uv = float2(hit_range, 0.5)@$$    float hit_wave = tex2D(RampTex, ramp_uv).r@$$    float hit_fade = saturate(pow( max( ( distance_mask + HitFadeStart * HitMaxSize) / (HitFadeSpread + 0.00001), 0.00001), HitFadePower))@$$    hit_result = hit_result + hit_fade * hit_wave@$}$$return saturate(hit_result)@;1;False;10;True;HitMaxSize;FLOAT;0;In;;Inherit;False;True;AffectorAmount;INT;20;In;;Inherit;False;True;WorldPos;FLOAT3;0,0,0;In;;Inherit;False;True;MakeZeroConst;INT;0;In;;Inherit;False;True;HitNoise;FLOAT;0;In;;Inherit;False;True;HitSpread;FLOAT;0;In;;Inherit;False;True;RampTex;SAMPLER2D;;In;;Inherit;False;True;HitFadeStart;FLOAT;0;In;;Inherit;False;True;HitFadeSpread;FLOAT;0;In;;Inherit;False;True;HitFadePower;FLOAT;0;In;;Inherit;False;HitExpression;True;False;0;10;0;FLOAT;0;False;1;INT;20;False;2;FLOAT3;0,0,0;False;3;INT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;SAMPLER2D;;False;7;FLOAT;0;False;8;FLOAT;0;False;9;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;15;136.6855,18.31808;Inherit;False;14;FresnelFactor;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexToFragmentNode;131;-704.9612,-626.6023;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;125;405.3605,246.2584;Inherit;False;Property;_HitWaveIntensity;HitWaveIntensity;25;0;Create;True;0;0;False;0;False;0;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;132;-483.9612,-626.6023;Inherit;False;HitWave_VS;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;29;392.185,79.68958;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;119;-718.932,-1022.072;Inherit;False;HitWave;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;136;328.9576,1082.719;Inherit;False;Constant;_Float1;Float 1;26;0;Create;True;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PosVertexDataNode;134;265.9576,923.7187;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;124;590.3605,179.2584;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;68;453.6039,496.4395;Inherit;False;Property;_DepthFade1;DepthFade;0;0;Create;True;0;0;False;0;False;0;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;127;501.3605,334.2584;Inherit;False;119;HitWave;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;133;272.545,815.5076;Inherit;False;132;HitWave_VS;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;135;519.9576,900.7187;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DepthFade;69;727.6039,478.4395;Inherit;False;True;False;True;2;1;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;138;546.9576,1096.719;Inherit;False;Property;_HitWaveOffset;HitWaveOffset;26;0;Create;True;0;0;False;0;False;0;5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;126;738.3605,286.2584;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;122;1006.331,455.3191;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;129;716.2059,83.88445;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;137;758.9576,953.7187;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;18;350.7856,-120.9665;Inherit;False;Property;_RimIntensity;RimIntensity;12;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;17;323.226,-317.6417;Inherit;False;Property;_RimColor;RimColor;10;0;Create;True;0;0;False;0;False;0.3378426,0.7604657,0.9811321,0;0.1921569,0.5647059,0.9568628,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;123;885.3425,161.9697;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;140;981.4714,953.2369;Inherit;False;HitWaveOffset;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;19;581.4066,-210.6965;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;141;1192.633,153.5583;Inherit;False;140;HitWaveOffset;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;106;-2530.704,-900.4766;Inherit;False;NoiseFactor;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;780.963,-96.95832;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;73;1031.457,117.7651;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GlobalArrayNode;121;-1031.022,-1223.055;Inherit;False;HitSize;0;20;0;True;False;0;1;True;Object;-1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GlobalArrayNode;120;-1274.381,-1227.775;Inherit;False;HitPosition;0;20;2;True;False;0;1;True;Object;-1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1421.186,-158.125;Float;False;True;-1;4;ASEMaterialInspector;0;0;Unlit;ForceField_FW;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Transparent;0.5;True;False;0;False;Transparent;;Transparent;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;2;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;54;0;47;0
WireConnection;56;0;45;0
WireConnection;53;0;56;0
WireConnection;53;2;54;0
WireConnection;52;1;53;0
WireConnection;144;0;143;0
WireConnection;144;1;145;0
WireConnection;57;0;52;0
WireConnection;58;0;57;0
WireConnection;58;1;59;0
WireConnection;146;3;144;0
WireConnection;146;4;147;0
WireConnection;151;0;146;0
WireConnection;60;0;45;0
WireConnection;60;1;58;0
WireConnection;35;0;34;0
WireConnection;35;2;36;0
WireConnection;148;0;151;0
WireConnection;46;0;60;0
WireConnection;46;2;47;0
WireConnection;64;0;63;0
WireConnection;61;1;64;0
WireConnection;44;1;46;0
WireConnection;152;0;150;0
WireConnection;152;1;148;0
WireConnection;103;0;102;0
WireConnection;103;1;101;0
WireConnection;23;0;21;0
WireConnection;24;1;25;0
WireConnection;33;1;35;0
WireConnection;65;0;44;1
WireConnection;65;1;61;1
WireConnection;65;2;66;0
WireConnection;22;0;21;0
WireConnection;22;1;23;0
WireConnection;105;0;104;0
WireConnection;105;9;103;0
WireConnection;48;0;44;1
WireConnection;48;1;49;0
WireConnection;153;0;152;0
WireConnection;37;0;24;1
WireConnection;37;1;33;1
WireConnection;111;0;105;0
WireConnection;111;1;107;0
WireConnection;67;0;48;0
WireConnection;67;1;65;0
WireConnection;27;0;24;1
WireConnection;38;0;37;0
WireConnection;38;1;39;0
WireConnection;11;0;22;0
WireConnection;11;1;8;0
WireConnection;11;2;9;0
WireConnection;11;3;10;0
WireConnection;50;0;67;0
WireConnection;130;0;116;0
WireConnection;130;1;112;0
WireConnection;130;2;154;0
WireConnection;130;3;110;0
WireConnection;130;4;111;0
WireConnection;130;5;108;0
WireConnection;130;6;115;0
WireConnection;130;7;117;0
WireConnection;130;8;114;0
WireConnection;130;9;113;0
WireConnection;41;0;38;0
WireConnection;14;0;11;0
WireConnection;30;0;28;0
WireConnection;30;1;31;0
WireConnection;118;0;116;0
WireConnection;118;1;112;0
WireConnection;118;2;155;0
WireConnection;118;3;110;0
WireConnection;118;4;111;0
WireConnection;118;5;108;0
WireConnection;118;6;115;0
WireConnection;118;7;117;0
WireConnection;118;8;114;0
WireConnection;118;9;113;0
WireConnection;131;0;130;0
WireConnection;132;0;131;0
WireConnection;29;0;15;0
WireConnection;29;1;30;0
WireConnection;29;2;42;0
WireConnection;29;3;51;0
WireConnection;119;0;118;0
WireConnection;124;0;29;0
WireConnection;124;1;125;0
WireConnection;135;0;133;0
WireConnection;135;1;134;0
WireConnection;135;2;136;0
WireConnection;69;0;68;0
WireConnection;126;0;124;0
WireConnection;126;1;127;0
WireConnection;122;0;69;0
WireConnection;129;0;29;0
WireConnection;129;1;126;0
WireConnection;137;0;135;0
WireConnection;137;1;138;0
WireConnection;123;0;129;0
WireConnection;123;1;122;0
WireConnection;140;0;137;0
WireConnection;19;0;17;0
WireConnection;19;1;18;0
WireConnection;106;0;105;1
WireConnection;20;0;19;0
WireConnection;20;1;129;0
WireConnection;73;0;123;0
WireConnection;121;1;112;0
WireConnection;120;1;112;0
WireConnection;0;2;20;0
WireConnection;0;9;73;0
WireConnection;0;11;141;0
ASEEND*/
//CHKSM=E6146C7C7F89F377A91F99EBA2089475F7534B08