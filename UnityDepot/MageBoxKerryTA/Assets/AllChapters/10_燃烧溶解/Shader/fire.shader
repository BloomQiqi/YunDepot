// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "fire"
{
	Properties
	{
		_Cutoff( "Mask Clip Value", Float ) = 0.5
		_Noise("Noise", 2D) = "white" {}
		_NoiseSpeed("NoiseSpeed", Vector) = (0,0,0,0)
		[HDR]_Color0("Color 0", Color) = (0,0,0,0)
		_Gradient("Gradient", 2D) = "white" {}
		_Softness("Softness", Range( 0 , 1)) = 0
		_GradientEndCon("GradientEndCon", Float) = 0.31
		_FireShape("FireShape", 2D) = "white" {}
		_NoiseIntensity("NoiseIntensity", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "AlphaTest+0" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#include "UnityShaderVariables.cginc"
		#pragma target 3.0
		#pragma surface surf Unlit keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float2 uv_texcoord;
		};

		uniform float4 _Color0;
		uniform sampler2D _Noise;
		SamplerState sampler_Noise;
		uniform float2 _NoiseSpeed;
		uniform float4 _Noise_ST;
		uniform sampler2D _Gradient;
		SamplerState sampler_Gradient;
		uniform float4 _Gradient_ST;
		uniform float _GradientEndCon;
		uniform float _Softness;
		uniform sampler2D _FireShape;
		uniform float _NoiseIntensity;
		uniform float _Cutoff = 0.5;

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float4 break33 = _Color0;
			float2 uv_Noise = i.uv_texcoord * _Noise_ST.xy + _Noise_ST.zw;
			float2 panner7 = ( 1.0 * _Time.y * _NoiseSpeed + uv_Noise);
			float Noise26 = tex2D( _Noise, panner7 ).r;
			float2 uv_Gradient = i.uv_texcoord * _Gradient_ST.xy + _Gradient_ST.zw;
			float4 tex2DNode19 = tex2D( _Gradient, uv_Gradient );
			float GradientEndCon39 = ( ( 1.0 - tex2DNode19.r ) * _GradientEndCon );
			float4 appendResult34 = (float4(break33.r , ( break33.g + ( Noise26 * GradientEndCon39 ) ) , break33.b , 0.0));
			o.Emission = ( appendResult34 * 1.5 ).xyz;
			o.Alpha = 1;
			float clampResult25 = clamp( ( Noise26 - _Softness ) , 0.0 , 1.0 );
			float Gradient27 = tex2DNode19.r;
			float smoothstepResult22 = smoothstep( clampResult25 , Noise26 , Gradient27);
			float4 appendResult47 = (float4(( i.uv_texcoord.x + ( _NoiseIntensity * (Noise26*2.0 + -1.0) * GradientEndCon39 ) ) , i.uv_texcoord.y , 0.0 , 0.0));
			float4 FireShape54 = tex2D( _FireShape, appendResult47.xy );
			clip( ( smoothstepResult22 * FireShape54 ).r - _Cutoff );
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18500
395.2;168;1213;666;4148.628;691.7002;4.297255;True;False
Node;AmplifyShaderEditor.CommentaryNode;30;-2256.302,-84.36064;Inherit;False;1110.34;610.3443;Comment;11;20;19;27;1;15;7;5;26;36;37;38;;1,1,1,1;0;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;20;-2043.999,-34.36065;Inherit;False;0;19;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;15;-2168.646,337.1254;Inherit;False;Property;_NoiseSpeed;NoiseSpeed;2;0;Create;True;0;0;False;0;False;0,0;0,-1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;1;-2206.302,188.6313;Inherit;False;0;5;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;19;-1815.198,-29.16062;Inherit;True;Property;_Gradient;Gradient;4;0;Create;True;0;0;False;0;False;-1;None;31ba75cf72e4b854393801314ca3b891;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;7;-1919.514,265.245;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;5;-1690.653,295.9836;Inherit;True;Property;_Noise;Noise;1;0;Create;True;0;0;False;0;False;-1;81e2bbf6818e7f446a9c980b35f7f089;dbd1f787eb120b54b82d10d1347e6be4;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;37;-1588.659,195.257;Inherit;False;Property;_GradientEndCon;GradientEndCon;6;0;Create;True;0;0;False;0;False;0.31;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;36;-1484.659,114.257;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;38;-1333.758,127.2569;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;53;-1989.799,879.6017;Inherit;False;1673.133;552.8547;Comment;10;54;43;47;49;51;52;48;50;46;45;FireShape;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;26;-1370.762,309.1635;Inherit;False;Noise;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;39;-1203.009,132.5224;Inherit;False;GradientEndCon;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;50;-1939.799,1202.116;Inherit;False;26;Noise;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;51;-1760.62,1305.057;Inherit;False;39;GradientEndCon;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;48;-1728.655,1084.175;Inherit;False;Property;_NoiseIntensity;NoiseIntensity;8;0;Create;True;0;0;False;0;False;0;0.46;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;52;-1751.399,1165.199;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;49;-1484.255,1150.475;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;45;-1540.464,949.1005;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;46;-1197.263,929.6017;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;47;-1017.69,957.433;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ColorNode;18;-790.7694,-455.7352;Inherit;False;Property;_Color0;Color 0;3;1;[HDR];Create;True;0;0;False;0;False;0,0,0,0;1,0.3490196,0.1084906,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;42;-619.1636,-258.0066;Inherit;False;26;Noise;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;40;-648.0829,-167.7159;Inherit;False;39;GradientEndCon;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;28;-802.1191,414.471;Inherit;False;26;Noise;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;23;-924.0261,590.8923;Inherit;False;Property;_Softness;Softness;5;0;Create;True;0;0;False;0;False;0;0.083;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;43;-864.0885,1082.24;Inherit;True;Property;_FireShape;FireShape;7;0;Create;True;0;0;False;0;False;-1;None;883238cefe294ff4f8b5e510509033da;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;21;-621.5402,577.9757;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;27;-1445.431,-4.442188;Inherit;False;Gradient;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;-404.7637,-264.7066;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;33;-574.9999,-455.4076;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.GetLocalVarNode;29;-619.1219,300.1021;Inherit;False;27;Gradient;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;25;-463.6987,572.7227;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;35;-198.1315,-314.2099;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;54;-562.4478,1075.803;Inherit;False;FireShape;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;31;-250.4325,-93.87374;Inherit;False;Constant;_Intensity;Intensity;7;0;Create;True;0;0;False;0;False;1.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;34;-31.15675,-455.7076;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SmoothstepOpNode;22;-204.5336,411.338;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;55;-180.0262,701.1902;Inherit;False;54;FireShape;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;32;-78.35308,-109.8706;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;44;38.10028,702.0709;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;128.7,26;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;fire;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;True;0;True;Opaque;;AlphaTest;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;0;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;19;1;20;0
WireConnection;7;0;1;0
WireConnection;7;2;15;0
WireConnection;5;1;7;0
WireConnection;36;0;19;1
WireConnection;38;0;36;0
WireConnection;38;1;37;0
WireConnection;26;0;5;1
WireConnection;39;0;38;0
WireConnection;52;0;50;0
WireConnection;49;0;48;0
WireConnection;49;1;52;0
WireConnection;49;2;51;0
WireConnection;46;0;45;1
WireConnection;46;1;49;0
WireConnection;47;0;46;0
WireConnection;47;1;45;2
WireConnection;43;1;47;0
WireConnection;21;0;28;0
WireConnection;21;1;23;0
WireConnection;27;0;19;1
WireConnection;41;0;42;0
WireConnection;41;1;40;0
WireConnection;33;0;18;0
WireConnection;25;0;21;0
WireConnection;35;0;33;1
WireConnection;35;1;41;0
WireConnection;54;0;43;0
WireConnection;34;0;33;0
WireConnection;34;1;35;0
WireConnection;34;2;33;2
WireConnection;22;0;29;0
WireConnection;22;1;25;0
WireConnection;22;2;28;0
WireConnection;32;0;34;0
WireConnection;32;1;31;0
WireConnection;44;0;22;0
WireConnection;44;1;55;0
WireConnection;0;2;32;0
WireConnection;0;10;44;0
ASEEND*/
//CHKSM=82325188BABE105E70138356ECD95E7181D3C645