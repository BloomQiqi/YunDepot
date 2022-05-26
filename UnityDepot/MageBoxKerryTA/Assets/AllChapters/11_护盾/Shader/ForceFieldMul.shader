// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ForceFieldMul"
{
	Properties
	{
		_Size("Size", Range( 0 , 10)) = 1
		_Noise("Noise", 2D) = "white" {}
		_NoiseTiling("NoiseTiling", Vector) = (1,1,1,0)
		_NoiseIntensity("NoiseIntensity", Float) = 1
		_Ramp("Ramp", 2D) = "white" {}
		_HitMaxSize("HitMaxSize", Float) = 0
		_HitSpread("HitSpread", Float) = 1
		_HitFadePower("HitFadePower", Float) = 1
		_HitFadeSpread("HitFadeSpread", Float) = 1
		_HitFadeStart("HitFadeStart", Range( 0 , 1)) = 0
		_HitWaveIntensity("HitWaveIntensity", Float) = 0
		_RimBias("RimBias", Float) = 0
		_RimScale("RimScale", Float) = 1
		_RimPower("RimPower", Float) = 5
		_RimColor("RimColor", Color) = (0.3378426,0.7604657,0.9811321,0)
		_RimIntensity("RimIntensity", Float) = 0
		_FlowLight("FlowLight", 2D) = "white" {}
		_FlowMap("FlowMap", 2D) = "white" {}
		_FlowSpeed("FlowSpeed", Float) = 0.2
		_FlowStrength("FlowStrength", Vector) = (0.2,0.2,0,0)
		_DisslovePoint("DisslovePoint", Vector) = (0,0,0,0)
		_DepthFade("DepthFade", Float) = 0
		_DepthFadePower("DepthFadePower", Float) = 0
		_DissloveAmount("DissloveAmount", Float) = 0
		_DissloveRampTex("DissloveRampTex", 2D) = "white" {}
		_DissloveNoiseIntensity("DissloveNoiseIntensity", Float) = 0
		_DissloveEdgeIntensity("DissloveEdgeIntensity", Float) = 0
		_TimeSpeed("TimeSpeed", Float) = 0
		_DissloveSpread("DissloveSpread", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#include "UnityCG.cginc"
		#include "UnityShaderVariables.cginc"
		#pragma target 3.0
		#pragma surface surf Unlit alpha:fade keepalpha noshadow 
		struct Input
		{
			float3 worldPos;
			float3 worldNormal;
			INTERNAL_DATA
			float4 screenPos;
			float2 uv_texcoord;
		};

		uniform float4 HitPosition[20];
		uniform float HitSize[20];
		uniform float4 _RimColor;
		uniform float _RimIntensity;
		uniform float _RimBias;
		uniform float _RimScale;
		uniform float _RimPower;
		UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
		uniform float4 _CameraDepthTexture_TexelSize;
		uniform float _DepthFade;
		uniform float _DepthFadePower;
		uniform sampler2D _FlowLight;
		uniform float4 _FlowLight_ST;
		uniform float _Size;
		uniform sampler2D _FlowMap;
		uniform float4 _FlowMap_ST;
		uniform float2 _FlowStrength;
		uniform float _FlowSpeed;
		uniform float _HitWaveIntensity;
		uniform float _HitMaxSize;
		uniform sampler2D _Noise;
		uniform float3 _NoiseTiling;
		uniform float _NoiseIntensity;
		uniform float _HitSpread;
		uniform sampler2D _Ramp;
		uniform float _HitFadeStart;
		uniform float _HitFadeSpread;
		uniform float _HitFadePower;
		uniform sampler2D _DissloveRampTex;
		SamplerState sampler_DissloveRampTex;
		uniform float3 _DisslovePoint;
		uniform float _DissloveAmount;
		uniform float _TimeSpeed;
		uniform float _DissloveNoiseIntensity;
		uniform float _DissloveSpread;
		uniform float _DissloveEdgeIntensity;


		inline float4 TriplanarSampling61( sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			half4 xNorm; half4 yNorm; half4 zNorm;
			xNorm = tex2D( topTexMap, tiling * worldPos.zy * float2(  nsign.x, 1.0 ) );
			yNorm = tex2D( topTexMap, tiling * worldPos.xz * float2(  nsign.y, 1.0 ) );
			zNorm = tex2D( topTexMap, tiling * worldPos.xy * float2( -nsign.z, 1.0 ) );
			return xNorm * projNormal.x + yNorm * projNormal.y + zNorm * projNormal.z;
		}


		float HitExpression56( float HitMaxSize, int AffectorAmount, float3 WorldPos, int MakeZeroConst, float HitNoise, float HitSpread, sampler2D RampTex, float HitFadeStart, float HitFadeSpread, float HitFadePower )
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
			float3 ase_normWorldNormal = normalize( ase_worldNormal );
			float fresnelNdotV66 = dot( ase_normWorldNormal, ase_worldViewDir );
			float fresnelNode66 = ( _RimBias + _RimScale * pow( max( 1.0 - fresnelNdotV66 , 0.0001 ), _RimPower ) );
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			float screenDepth106 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_screenPosNorm.xy ));
			float distanceDepth106 = abs( ( screenDepth106 - LinearEyeDepth( ase_screenPosNorm.z ) ) / ( _DepthFade ) );
			float clampResult108 = clamp( ( ( 1.0 - distanceDepth106 ) * _DepthFadePower ) , 0.0 , 1.0 );
			float FresnelFactor70 = ( fresnelNode66 + clampResult108 );
			float2 uv_FlowLight = i.uv_texcoord * _FlowLight_ST.xy + _FlowLight_ST.zw;
			float2 temp_output_4_0_g1 = (( uv_FlowLight / _Size )).xy;
			float2 uv_FlowMap = i.uv_texcoord * _FlowMap_ST.xy + _FlowMap_ST.zw;
			float2 temp_output_41_0_g1 = ( ( (tex2D( _FlowMap, uv_FlowMap )).rg - float2( 0.5,0.5 ) ) + 0.5 );
			float2 temp_output_17_0_g1 = _FlowStrength;
			float mulTime22_g1 = _Time.y * _FlowSpeed;
			float temp_output_27_0_g1 = frac( mulTime22_g1 );
			float2 temp_output_11_0_g1 = ( temp_output_4_0_g1 + ( temp_output_41_0_g1 * temp_output_17_0_g1 * temp_output_27_0_g1 ) );
			float2 temp_output_12_0_g1 = ( temp_output_4_0_g1 + ( temp_output_41_0_g1 * temp_output_17_0_g1 * frac( ( mulTime22_g1 + 0.5 ) ) ) );
			float4 lerpResult9_g1 = lerp( tex2D( _FlowLight, temp_output_11_0_g1 ) , tex2D( _FlowLight, temp_output_12_0_g1 ) , ( abs( ( temp_output_27_0_g1 - 0.5 ) ) / 0.5 ));
			float4 temp_cast_0 = (FresnelFactor70).xxxx;
			float smoothstepResult91 = smoothstep( 0.95 , 1.0 , i.uv_texcoord.y);
			float4 lerpResult94 = lerp( lerpResult9_g1 , temp_cast_0 , smoothstepResult91);
			float4 FlowLight89 = lerpResult94;
			float4 temp_output_101_0 = ( FresnelFactor70 * FlowLight89 );
			float HitMaxSize56 = _HitMaxSize;
			int AffectorAmount56 = (int)20.0;
			float3 WorldPos56 = ase_worldPos;
			int MakeZeroConst56 = (int)1.0;
			float4 triplanar61 = TriplanarSampling61( _Noise, ( ase_worldPos * _NoiseTiling ), ase_worldNormal, 1.0, float2( 1,1 ), 1.0, 0 );
			float HitNoise56 = ( triplanar61 * _NoiseIntensity ).x;
			float HitSpread56 = _HitSpread;
			sampler2D RampTex56 = _Ramp;
			float HitFadeStart56 = _HitFadeStart;
			float HitFadeSpread56 = _HitFadeSpread;
			float HitFadePower56 = _HitFadePower;
			float localHitExpression56 = HitExpression56( HitMaxSize56 , AffectorAmount56 , WorldPos56 , MakeZeroConst56 , HitNoise56 , HitSpread56 , RampTex56 , HitFadeStart56 , HitFadeSpread56 , HitFadePower56 );
			float HitWave78 = localHitExpression56;
			float3 objToWorld123 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float mulTime161 = _Time.y * _TimeSpeed;
			float NoiseFactor146 = triplanar61.x;
			float clampResult129 = clamp( ( ( ( distance( _DisslovePoint , ( ase_worldPos - objToWorld123 ) ) - ( ( _DissloveAmount + mulTime161 ) - 1.6 ) ) - ( _DissloveNoiseIntensity * NoiseFactor146 ) ) / _DissloveSpread ) , 0.0 , 1.0 );
			float temp_output_139_0 = ( 1.0 - clampResult129 );
			float2 appendResult133 = (float2(temp_output_139_0 , 0.5));
			float DissloveEdge130 = ( tex2D( _DissloveRampTex, appendResult133 ).r * _DissloveEdgeIntensity );
			float4 temp_output_115_0 = ( temp_output_101_0 + ( ( temp_output_101_0 + _HitWaveIntensity ) * HitWave78 ) + DissloveEdge130 );
			o.Emission = ( ( _RimColor * _RimIntensity ) * temp_output_115_0 ).rgb;
			float grayscale102 = Luminance(temp_output_115_0.rgb);
			float smoothstepResult140 = smoothstep( 0.0 , 1.0 , temp_output_139_0);
			float DissloveAlpha142 = smoothstepResult140;
			float clampResult103 = clamp( ( grayscale102 * DissloveAlpha142 ) , 0.0 , 1.0 );
			o.Alpha = clampResult103;
		}

		ENDCG
	}
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18500
-170.4;510.4;1536;796;3092.015;497.2342;3.680659;True;False
Node;AmplifyShaderEditor.CommentaryNode;77;-1747.803,522.4185;Inherit;False;2798.003;1006.389;HitWave;21;78;22;64;61;63;2;21;57;31;15;58;48;56;65;47;62;60;59;14;10;146;HitWave;1,0.8254717,0.8254717,1;0;0
Node;AmplifyShaderEditor.WorldPosInputsNode;63;-1697.803,945.8851;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;65;-1689.803,1123.885;Inherit;False;Property;_NoiseTiling;NoiseTiling;4;0;Create;True;0;0;False;0;False;1,1,1;0.2,0.2,0.2;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CommentaryNode;95;-1665.019,2638.643;Inherit;False;1481.41;404.8012;FresnelFactor;12;108;109;106;107;70;66;68;69;67;110;112;111;FresnelFactor;0.4130474,0.9622642,0.5099499,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;154;-1723.618,3300.837;Inherit;False;2767.204;665.5767;Disslove;26;152;142;140;130;151;134;133;139;129;127;147;128;126;125;148;149;153;124;145;121;118;120;123;157;158;161;Disslove;0.9339623,0.5594963,0.5594963,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;158;-1490.188,3822.083;Inherit;False;Property;_TimeSpeed;TimeSpeed;29;0;Create;True;0;0;False;0;False;0;4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;107;-1229.595,2876.783;Inherit;False;Property;_DepthFade;DepthFade;23;0;Create;True;0;0;False;0;False;0;1.34;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;62;-1630.803,747.8853;Inherit;True;Property;_Noise;Noise;3;0;Create;True;0;0;False;0;False;None;3c506748d17579d4a85691a58877ff1e;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;64;-1515.803,1036.885;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldPosInputsNode;120;-1673.618,3493.074;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformPositionNode;123;-1666.618,3660.074;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;126;-1398.617,3676.44;Inherit;False;Property;_DissloveAmount;DissloveAmount;25;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;161;-1332.35,3802.363;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DepthFade;106;-955.595,2858.783;Inherit;False;True;False;True;2;1;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TriplanarNode;61;-1359.803,916.8851;Inherit;True;Spherical;World;False;Top Texture 0;_TopTexture0;white;-1;None;Mid Texture 0;_MidTexture0;white;-1;None;Bot Texture 0;_BotTexture0;white;-1;None;Triplanar Sampler;Tangent;10;0;SAMPLER2D;;False;5;FLOAT;1;False;1;SAMPLER2D;;False;6;FLOAT;0;False;2;SAMPLER2D;;False;7;FLOAT;0;False;9;FLOAT3;0,0,0;False;8;FLOAT;1;False;3;FLOAT2;1,1;False;4;FLOAT;1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;146;-937.3024,899.7173;Inherit;False;NoiseFactor;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;109;-665.2874,2871.82;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;121;-1444.618,3569.074;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;157;-1140.188,3700.083;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;118;-1477.246,3350.837;Inherit;False;Property;_DisslovePoint;DisslovePoint;22;0;Create;True;0;0;False;0;False;0,0,0;2.67,2.68,-10;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CommentaryNode;105;-1672.732,1645.967;Inherit;False;2067.92;796.17;FlowLight;14;83;82;84;90;85;87;80;104;81;100;91;79;94;89;FlowLight;0.6367924,0.9418279,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;111;-899.4587,2974.001;Inherit;False;Property;_DepthFadePower;DepthFadePower;24;0;Create;True;0;0;False;0;False;0;1.22;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;67;-1614.019,2729.375;Inherit;False;Property;_RimBias;RimBias;13;0;Create;True;0;0;False;0;False;0;0.41;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;112;-488.4587,2910.001;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;83;-1622.732,2070.939;Inherit;False;0;82;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;153;-1101.542,3570.249;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1.6;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;145;-991.2301,3754.143;Inherit;False;146;NoiseFactor;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;149;-1001.707,3677.305;Inherit;False;Property;_DissloveNoiseIntensity;DissloveNoiseIntensity;27;0;Create;True;0;0;False;0;False;0;0.65;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;124;-1213.445,3461.129;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;69;-1615.019,2879.375;Inherit;False;Property;_RimPower;RimPower;15;0;Create;True;0;0;False;0;False;5;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;68;-1615.019,2803.375;Inherit;False;Property;_RimScale;RimScale;14;0;Create;True;0;0;False;0;False;1;0.99;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;82;-1358.476,2048.108;Inherit;True;Property;_FlowMap;FlowMap;19;0;Create;True;0;0;False;0;False;-1;None;f4a4b1c04c15a784ca546dc6c403e249;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;148;-765.7073,3702.305;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;108;-340.4516,2832.116;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;66;-1372.431,2688.643;Inherit;False;Standard;WorldNormal;ViewDir;True;True;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;125;-978.1718,3494.485;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;110;-670.6906,2727.956;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;128;-617.2776,3768.326;Inherit;False;Property;_DissloveSpread;DissloveSpread;30;0;Create;True;0;0;False;0;False;0;2.03;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;84;-1006.024,2047.49;Inherit;False;FLOAT2;0;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;147;-618.9966,3628.087;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;90;-683.3177,2189.622;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;104;-834.8463,2031.656;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;85;-1024.192,2133.171;Inherit;False;Property;_FlowStrength;FlowStrength;21;0;Create;True;0;0;False;0;False;0.2,0.2;0.2,0.2;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleDivideOpNode;127;-447.1775,3634.825;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;80;-971.3173,1695.967;Inherit;True;Property;_FlowLight;FlowLight;18;0;Create;True;0;0;False;0;False;None;aeb46886909512e41842722f15bb898b;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RegisterLocalVarNode;70;-417.5471,2690.523;Inherit;False;FresnelFactor;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;87;-1023.825,2258.63;Inherit;False;Property;_FlowSpeed;FlowSpeed;20;0;Create;True;0;0;False;0;False;0.2;0.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;81;-996.2072,1890.002;Inherit;False;0;80;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;100;-311.6928,2066.487;Inherit;False;70;FresnelFactor;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;91;-463.0539,2188.737;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0.95;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;79;-599.3304,1982.113;Inherit;False;Flow;0;;1;acad10cc8145e1f4eb8042bebe2d9a42;2,50,0,51,0;5;5;SAMPLER2D;;False;2;FLOAT2;0,0;False;18;FLOAT2;0,0;False;17;FLOAT2;1,1;False;24;FLOAT;0.2;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;129;-294.0321,3647.319;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;15;-1048.458,1142.014;Inherit;False;Property;_NoiseIntensity;NoiseIntensity;5;0;Create;True;0;0;False;0;False;1;1.15;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;94;-45.08212,2000.65;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;1,1,1,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;139;-145.0347,3659.232;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;14;-872.3583,1038.914;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;48;-120.9952,1231.887;Inherit;False;Property;_HitFadeStart;HitFadeStart;11;0;Create;True;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;47;-85.62906,655.8751;Inherit;False;Property;_HitMaxSize;HitMaxSize;7;0;Create;True;0;0;False;0;False;0;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;60;-74.04435,1059.291;Inherit;True;Property;_Ramp;Ramp;6;0;Create;True;0;0;False;0;False;None;256d86d8496a4e0f947100121f1fafb2;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RangedFloatNode;21;-128.9965,1377.65;Inherit;False;Property;_HitFadeSpread;HitFadeSpread;10;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;22;187.6094,1402.956;Inherit;False;Property;_HitFadePower;HitFadePower;9;0;Create;True;0;0;False;0;False;1;1.51;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;58;47.99001,755.6031;Inherit;False;Constant;_AffectorAmount;AffectorAmount;10;0;Create;True;0;0;False;0;False;20;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;89;170.388,1969.713;Inherit;False;FlowLight;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;31;-694.0792,921.6727;Inherit;False;Constant;_MakeZeroConst;MakeZeroConst;9;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;2;-672.6208,750.3643;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;10;-443.6334,1053.372;Inherit;False;Property;_HitSpread;HitSpread;8;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;133;46.53217,3687.306;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;152;310.3614,3856.824;Inherit;False;Property;_DissloveEdgeIntensity;DissloveEdgeIntensity;28;0;Create;True;0;0;False;0;False;0;1.86;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;134;243.0022,3657.609;Inherit;True;Property;_DissloveRampTex;DissloveRampTex;26;0;Create;True;0;0;False;0;False;-1;None;256d86d8496a4e0f947100121f1fafb2;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;71;1185.131,677.3615;Inherit;False;70;FresnelFactor;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;56;554.7213,782.39;Inherit;False;float hit_result = 0@$for(int j = 0@ j < AffectorAmount@ j++)${$    float distance_mask = 1 - distance(HitPosition[j].xyz, WorldPos) - MakeZeroConst@$$    float hit_range =  saturate((distance_mask + HitSize[j] - HitNoise) / (HitSpread + 0.00001))@$$    float2 ramp_uv = float2(hit_range, 0.5)@$$    float hit_wave = tex2D(RampTex, ramp_uv).r@$$    float hit_fade = saturate(pow( max( ( distance_mask + HitFadeStart * HitMaxSize) / (HitFadeSpread + 0.00001), 0.00001), HitFadePower))@$$    hit_result = hit_result + hit_fade * hit_wave@$}$$return saturate(hit_result)@;1;False;10;True;HitMaxSize;FLOAT;0;In;;Inherit;False;True;AffectorAmount;INT;20;In;;Inherit;False;True;WorldPos;FLOAT3;0,0,0;In;;Inherit;False;True;MakeZeroConst;INT;0;In;;Inherit;False;True;HitNoise;FLOAT;0;In;;Inherit;False;True;HitSpread;FLOAT;0;In;;Inherit;False;True;RampTex;SAMPLER2D;;In;;Inherit;False;True;HitFadeStart;FLOAT;0;In;;Inherit;False;True;HitFadeSpread;FLOAT;0;In;;Inherit;False;True;HitFadePower;FLOAT;0;In;;Inherit;False;HitExpression;True;False;0;10;0;FLOAT;0;False;1;INT;20;False;2;FLOAT3;0,0,0;False;3;INT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;SAMPLER2D;;False;7;FLOAT;0;False;8;FLOAT;0;False;9;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;88;1198.29,772.7055;Inherit;False;89;FlowLight;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;78;819.6998,778.1219;Inherit;False;HitWave;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;117;1375.764,855.04;Inherit;False;Property;_HitWaveIntensity;HitWaveIntensity;12;0;Create;True;0;0;False;0;False;0;0.74;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;151;591.3613,3750.824;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;101;1409.063,710.8126;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;116;1579.364,785.0399;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;113;1469.456,939.9827;Inherit;False;78;HitWave;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;130;763.1984,3671.904;Inherit;False;DissloveEdge;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;131;1702.35,1016.708;Inherit;False;130;DissloveEdge;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;140;40.28589,3564.305;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;114;1735.998,835.3193;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;142;230.2859,3563.305;Inherit;False;DissloveAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;115;1920.998,706.3193;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;72;1327.825,386.1136;Inherit;False;Property;_RimColor;RimColor;16;0;Create;True;0;0;False;0;False;0.3378426,0.7604657,0.9811321,0;0.8784314,0.7176471,0.9960785,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;143;2038.474,906.955;Inherit;False;142;DissloveAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;75;1388.323,573.5659;Inherit;False;Property;_RimIntensity;RimIntensity;17;0;Create;True;0;0;False;0;False;0;4.02;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCGrayscale;102;2060.984,776.9608;Inherit;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;74;1587.323,478.5658;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;144;2263.807,836.2426;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GlobalArrayNode;59;562.3801,577.1387;Inherit;False;HitSize;0;20;0;True;False;0;1;True;Object;-1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;103;2407.863,788.0851;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;76;2078.754,475.0326;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GlobalArrayNode;57;319.0209,572.4186;Inherit;False;HitPosition;0;20;2;True;False;0;1;True;Object;-1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;2651.682,421.939;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;ForceFieldMul;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Transparent;0.5;True;False;0;False;Transparent;;Transparent;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;2;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;64;0;63;0
WireConnection;64;1;65;0
WireConnection;161;0;158;0
WireConnection;106;0;107;0
WireConnection;61;0;62;0
WireConnection;61;9;64;0
WireConnection;146;0;61;1
WireConnection;109;0;106;0
WireConnection;121;0;120;0
WireConnection;121;1;123;0
WireConnection;157;0;126;0
WireConnection;157;1;161;0
WireConnection;112;0;109;0
WireConnection;112;1;111;0
WireConnection;153;0;157;0
WireConnection;124;0;118;0
WireConnection;124;1;121;0
WireConnection;82;1;83;0
WireConnection;148;0;149;0
WireConnection;148;1;145;0
WireConnection;108;0;112;0
WireConnection;66;1;67;0
WireConnection;66;2;68;0
WireConnection;66;3;69;0
WireConnection;125;0;124;0
WireConnection;125;1;153;0
WireConnection;110;0;66;0
WireConnection;110;1;108;0
WireConnection;84;0;82;0
WireConnection;147;0;125;0
WireConnection;147;1;148;0
WireConnection;104;0;84;0
WireConnection;127;0;147;0
WireConnection;127;1;128;0
WireConnection;70;0;110;0
WireConnection;91;0;90;2
WireConnection;79;5;80;0
WireConnection;79;2;81;0
WireConnection;79;18;104;0
WireConnection;79;17;85;0
WireConnection;79;24;87;0
WireConnection;129;0;127;0
WireConnection;94;0;79;0
WireConnection;94;1;100;0
WireConnection;94;2;91;0
WireConnection;139;0;129;0
WireConnection;14;0;61;0
WireConnection;14;1;15;0
WireConnection;89;0;94;0
WireConnection;133;0;139;0
WireConnection;134;1;133;0
WireConnection;56;0;47;0
WireConnection;56;1;58;0
WireConnection;56;2;2;0
WireConnection;56;3;31;0
WireConnection;56;4;14;0
WireConnection;56;5;10;0
WireConnection;56;6;60;0
WireConnection;56;7;48;0
WireConnection;56;8;21;0
WireConnection;56;9;22;0
WireConnection;78;0;56;0
WireConnection;151;0;134;1
WireConnection;151;1;152;0
WireConnection;101;0;71;0
WireConnection;101;1;88;0
WireConnection;116;0;101;0
WireConnection;116;1;117;0
WireConnection;130;0;151;0
WireConnection;140;0;139;0
WireConnection;114;0;116;0
WireConnection;114;1;113;0
WireConnection;142;0;140;0
WireConnection;115;0;101;0
WireConnection;115;1;114;0
WireConnection;115;2;131;0
WireConnection;102;0;115;0
WireConnection;74;0;72;0
WireConnection;74;1;75;0
WireConnection;144;0;102;0
WireConnection;144;1;143;0
WireConnection;59;1;58;0
WireConnection;103;0;144;0
WireConnection;76;0;74;0
WireConnection;76;1;115;0
WireConnection;57;1;58;0
WireConnection;0;2;76;0
WireConnection;0;9;103;0
ASEEND*/
//CHKSM=4CA01BBEF9236314695B122143F3326B756AF266