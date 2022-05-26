// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "dissolve"
{
	Properties
	{
		_Cutoff( "Mask Clip Value", Float ) = 0.5
		_Maintex("Maintex", 2D) = "white" {}
		_Gradient("Gradient", 2D) = "white" {}
		_ChangeAmount("ChangeAmount", Range( 0 , 1)) = 0
		_Edgewidth("Edgewidth", Range( 0 , 2)) = 0.1
		_EdgeColor("EdgeColor", Color) = (0,0,0,0)
		_EdgeColorIntensity("EdgeColorIntensity", Float) = 1
		[Toggle(_TIMEFLOW_ON)] _TIMEFLOW("TIMEFLOW", Float) = 0
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
		#pragma shader_feature_local _TIMEFLOW_ON
		#pragma surface surf Unlit keepalpha addshadow fullforwardshadows 
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
		uniform float _Edgewidth;
		SamplerState sampler_Maintex;
		uniform float _Cutoff = 0.5;

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
				float staticSwitch28 = (-1.0 + (frac( mulTime26 ) - 0.0) * (1.0 - -1.0) / (1.0 - 0.0));
			#else
				float staticSwitch28 = _ChangeAmount;
			#endif
			float Gradient23 = ( tex2D( _Gradient, uv_Gradient ).r - staticSwitch28 );
			float clampResult17 = clamp( ( 1.0 - ( distance( Gradient23 , 0.5 ) / _Edgewidth ) ) , 0.0 , 1.0 );
			float4 lerpResult21 = lerp( tex2DNode1 , ( _EdgeColor * _EdgeColorIntensity * tex2DNode1 ) , clampResult17);
			o.Emission = lerpResult21.rgb;
			o.Alpha = 1;
			clip( ( tex2DNode1.a * step( 0.5 , Gradient23 ) ) - _Cutoff );
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18500
-245.6;442.4;1213;702;2590.706;-618.2546;1;True;False
Node;AmplifyShaderEditor.SimpleTimeNode;26;-2125.828,872.057;Inherit;False;1;0;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;22;-2144.309,354.9184;Inherit;False;930.912;474.0438;Gradient;6;23;7;11;6;4;28;;1,1,1,1;0;0
Node;AmplifyShaderEditor.FractNode;27;-1943.828,916.2568;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;11;-1906.583,739.7062;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;-1;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;6;-2138.889,624.52;Inherit;False;Property;_ChangeAmount;ChangeAmount;3;0;Create;True;0;0;False;0;False;0;0.477;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;28;-1843.729,596.4572;Inherit;False;Property;_TIMEFLOW;TIMEFLOW;7;0;Create;True;0;0;False;0;False;0;0;1;True;;Toggle;2;Key0;Key1;Create;True;True;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;4;-2020.167,392.5289;Inherit;True;Property;_Gradient;Gradient;2;0;Create;True;0;0;False;0;False;-1;1a52ef923eabcb84cbe56f5e2a1ae548;91a691479f12f574e9bfedfb2dc5f90a;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;7;-1604.293,445.6253;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;23;-1424.175,454.6921;Inherit;False;Gradient;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;25;-900.7517,670.4593;Inherit;False;1036.148;427.1341;EdgeColor;6;14;15;13;12;16;17;;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;24;-826.7838,510.2967;Inherit;False;23;Gradient;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;14;-850.7517,798.0591;Inherit;False;Constant;_Float0;Float 0;4;0;Create;True;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;15;-734.2877,982.1934;Inherit;False;Property;_Edgewidth;Edgewidth;4;0;Create;True;0;0;False;0;False;0.1;0.22;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;13;-660.1516,720.4593;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;12;-414.1752,748.007;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;18;-643.9126,-113.6765;Inherit;False;Property;_EdgeColor;EdgeColor;5;0;Create;True;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;19;-636.4724,110.6121;Inherit;False;Property;_EdgeColorIntensity;EdgeColorIntensity;6;0;Create;True;0;0;False;0;False;1;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;1;-996.6288,41.19707;Inherit;True;Property;_Maintex;Maintex;1;0;Create;True;0;0;False;0;False;-1;22f6b69afffc98441a907e29171dacff;22f6b69afffc98441a907e29171dacff;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;16;-219.2089,751.8465;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;17;-35.40369,775.7458;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;10;-567.5919,454.554;Inherit;True;2;0;FLOAT;0.5;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-380.3728,-23.28788;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;5;-310.8513,249.8398;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;21;-190.5726,44.3121;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;3;0,0;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;dissolve;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;True;0;True;Opaque;;AlphaTest;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;0;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;27;0;26;0
WireConnection;11;0;27;0
WireConnection;28;1;6;0
WireConnection;28;0;11;0
WireConnection;7;0;4;1
WireConnection;7;1;28;0
WireConnection;23;0;7;0
WireConnection;13;0;24;0
WireConnection;13;1;14;0
WireConnection;12;0;13;0
WireConnection;12;1;15;0
WireConnection;16;0;12;0
WireConnection;17;0;16;0
WireConnection;10;1;24;0
WireConnection;20;0;18;0
WireConnection;20;1;19;0
WireConnection;20;2;1;0
WireConnection;5;0;1;4
WireConnection;5;1;10;0
WireConnection;21;0;1;0
WireConnection;21;1;20;0
WireConnection;21;2;17;0
WireConnection;3;2;21;0
WireConnection;3;10;5;0
ASEEND*/
//CHKSM=B74F097F0F3BA72ECE7CF80427DF9D210852291B