// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ForceField"
{
	Properties
	{
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" }
		Cull Back
		CGPROGRAM
		#pragma target 3.0
		#pragma surface surf Unlit alpha:fade keepalpha addshadow fullforwardshadows 
		struct Input
		{
			half filler;
		};

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18500
128.8;433.6;1222;500;1698.666;492.2434;1.3;True;False
Node;AmplifyShaderEditor.WorldPosInputsNode;2;-1288.038,-253.6599;Inherit;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMaxOpNode;35;218.535,-217.4794;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1E-05;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;9;80.72085,161.2703;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;45;-143.7833,-290.6115;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;22;367.3246,-273.6869;Inherit;False;Property;_HitFadePower;HitFadePower;5;0;Create;True;0;0;False;0;False;1;1.51;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;24;206.7078,-455.1386;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;12;265.7458,162.7718;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;7;-118.4584,123.1081;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;16;530.046,296.7022;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ClampOpNode;37;783.9363,-380.3002;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;38;1083.184,-83.53506;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;55;1310.696,-80.06259;Inherit;False;SampleResult;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;13;-976.9078,366.1447;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;56;1611.338,312.7422;Inherit;False;55;SampleResult;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;17;730.9796,371.4832;Inherit;True;Property;_Ramp;Ramp;7;0;Create;True;0;0;False;0;False;-1;None;256d86d8496a4e0f947100121f1fafb2;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PowerNode;19;573.4648,-381.2183;Inherit;False;True;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;21;8.795517,-215.4153;Inherit;False;Property;_HitFadeSpread;HitFadeSpread;6;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;10;-112.2792,286.2702;Inherit;False;Property;_HitSpread;HitSpread;3;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;54;-673.5006,-70.2403;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;4;-1019.237,-345.0599;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;61;-1109.598,922.1683;Inherit;False;Property;_NoiseTiling;NoiseTiling;10;0;Create;True;0;0;False;0;False;1,1,1;1,2,1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldPosInputsNode;59;-1111.334,742.1389;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.OneMinusNode;18;-854.3755,-344.2471;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;58;-1100.547,532.9341;Inherit;True;Property;_Noise;Noise;0;0;Create;True;0;0;False;0;False;None;0b9d646e8eaef6749851346201bd314b;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RangedFloatNode;31;-884.6779,-243.5097;Inherit;False;Constant;_MakeZeroConst;MakeZeroConst;9;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;60;-919.5981,833.1683;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;6;-1001.814,134.1155;Inherit;False;Property;_HitSizeAmount;HitSizeAmount;2;0;Create;True;0;0;False;0;False;0;3.47;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TriplanarNode;57;-780.7322,652.2094;Inherit;True;Spherical;World;False;Top Texture 0;_TopTexture0;white;-1;None;Mid Texture 0;_MidTexture0;white;-1;None;Bot Texture 0;_BotTexture0;white;-1;None;Triplanar Sampler;Tangent;10;0;SAMPLER2D;;False;5;FLOAT;1;False;1;SAMPLER2D;;False;6;FLOAT;0;False;2;SAMPLER2D;;False;7;FLOAT;0;False;9;FLOAT3;0,0,0;False;8;FLOAT;1;False;3;FLOAT2;1,1;False;4;FLOAT;1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;30;-660.4635,-343.7596;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;15;-548.5999,865.1597;Inherit;False;Property;_NoiseIntensity;NoiseIntensity;4;0;Create;True;0;0;False;0;False;1;1.15;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;14;-342.5999,745.1595;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;47;-941.1783,-8.099648;Inherit;False;Property;_HitMaxSize;HitMaxSize;8;0;Create;True;0;0;False;0;False;0;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;27;-333.4982,-9.959846;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;48;-974.9326,-131.298;Inherit;False;Property;_HitFadeStart;HitFadeStart;9;0;Create;True;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;1;-1276.142,-420.8991;Inherit;False;Property;_HitPosition;HitPosition;1;0;Create;True;0;0;False;0;False;0,0,0;12.66,0.76,0.08272754;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;2065.645,473.051;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;ForceField;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Transparent;0.5;True;True;0;False;Transparent;;Transparent;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;2;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;35;0;21;0
WireConnection;9;0;7;0
WireConnection;9;1;10;0
WireConnection;45;0;30;0
WireConnection;45;1;54;0
WireConnection;24;0;45;0
WireConnection;24;1;35;0
WireConnection;12;0;9;0
WireConnection;7;0;27;0
WireConnection;7;1;14;0
WireConnection;16;0;12;0
WireConnection;37;0;19;0
WireConnection;38;0;37;0
WireConnection;38;1;17;1
WireConnection;55;0;38;0
WireConnection;17;1;16;0
WireConnection;19;0;24;0
WireConnection;19;1;22;0
WireConnection;54;0;48;0
WireConnection;54;1;47;0
WireConnection;4;0;1;0
WireConnection;4;1;2;0
WireConnection;18;0;4;0
WireConnection;60;0;59;0
WireConnection;60;1;61;0
WireConnection;57;0;58;0
WireConnection;57;9;60;0
WireConnection;30;0;18;0
WireConnection;30;1;31;0
WireConnection;14;0;57;1
WireConnection;14;1;15;0
WireConnection;27;0;30;0
WireConnection;27;1;6;0
ASEEND*/
//CHKSM=6478E5F922CB4A0EDAE75F7F73FD5CA0E8433912