// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "VAT"
{
	Properties
	{
		_Vertexanimtex("Vertex anim tex", 2D) = "white" {}
		_FrameCount("FrameCount", Float) = 100
		_Vertexanimtex2("Vertex anim tex2", 2D) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		CGPROGRAM
		#include "UnityShaderVariables.cginc"
		#pragma target 3.0
		#pragma surface surf Unlit keepalpha addshadow fullforwardshadows vertex:vertexDataFunc 
		struct Input
		{
			half filler;
		};

		uniform sampler2D _Vertexanimtex;
		uniform float _FrameCount;
		uniform sampler2D _Vertexanimtex2;

		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float CurrentFrame12 = ( -ceil( ( frac( ( _Time.y * 0.2 ) ) * _FrameCount ) ) / _FrameCount );
			float2 appendResult4 = (float2(v.texcoord.xy.x , CurrentFrame12));
			float2 UV_LUT19 = appendResult4;
			float3 break18 = ( ( (tex2Dlod( _Vertexanimtex, float4( UV_LUT19, 0, 0.0) )).rgb * ( 3.0 - 0.0 ) ) + 0.0 );
			float4 appendResult23 = (float4(break18.z , break18.y , break18.x , 0.0));
			float3 break51 = ( ( (tex2Dlod( _Vertexanimtex2, float4( UV_LUT19, 0, 0.0) )).rgb * ( 3.0 - 0.0 ) ) + 0.0 );
			float4 appendResult52 = (float4(break51.z , break51.y , break51.x , 0.0));
			v.vertex.xyz += ( appendResult23 + appendResult52 ).xyz;
			v.vertex.w = 1;
		}

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
225.6;304.8;1340;532;2116.488;2.101746;2.16653;True;False
Node;AmplifyShaderEditor.RangedFloatNode;9;-2591.806,-210.6131;Inherit;False;Constant;_TimeSpeed;TimeSpeed;2;0;Create;True;0;0;False;0;False;0.2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;7;-2593.108,-303.4129;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;10;-2360.223,-283.6591;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FractNode;8;-2095.097,-280.4153;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;5;-2021.992,-108.7512;Inherit;False;Property;_FrameCount;FrameCount;1;0;Create;True;0;0;False;0;False;100;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;13;-1943.142,-267.5117;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CeilOpNode;15;-1788.989,-267.6142;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;28;-1647.218,-262.7316;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;16;-1572.788,-186.4144;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;12;-1280.778,-217.1742;Inherit;False;CurrentFrame;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;17;-2174.614,168.2625;Inherit;False;12;CurrentFrame;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;2;-2255.433,44.16409;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;4;-1895.672,64.37596;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;19;-1604.949,65.49713;Inherit;False;UV_LUT;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;44;-1703.898,583.1235;Inherit;False;19;UV_LUT;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;20;-1699.366,365.4107;Inherit;False;19;UV_LUT;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;1;-1304.982,338.2534;Inherit;True;Property;_Vertexanimtex;Vertex anim tex;0;0;Create;True;0;0;False;0;False;-1;2b07aad8a3e062a4e9a15fd2bf3f774d;2b07aad8a3e062a4e9a15fd2bf3f774d;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;46;-948.786,578.5682;Inherit;False;Constant;_Float1;Float 1;5;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;45;-955.4349,483.8213;Inherit;False;Constant;_Float0;Float 0;5;0;Create;True;0;0;False;0;False;3;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;43;-1330.531,581.5679;Inherit;True;Property;_Vertexanimtex2;Vertex anim tex2;4;0;Create;True;0;0;False;0;False;-1;a1f42b647b31b8a4e8a1fe0c07b0f37e;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;38;-1184.748,149.2938;Inherit;False;Constant;_BoundingMin;BoundingMin;5;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;37;-1191.397,54.54685;Inherit;False;Constant;_BoundingMax;BoundingMax;5;0;Create;True;0;0;False;0;False;3;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;39;-991.9296,86.12917;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;21;-941.7225,244.0428;Inherit;False;FLOAT3;0;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;47;-755.9676,515.4036;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;50;-826.3812,678.8843;Inherit;False;FLOAT3;0;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;48;-576.4468,537.0125;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;40;-812.4089,107.7381;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;49;-412.1764,545.1357;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;42;-607.3715,153.492;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;18;-708.6546,248.0154;Inherit;True;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.BreakToComponentsNode;51;-602.5916,686.5684;Inherit;True;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.DynamicAppendNode;52;-361.9481,688.0366;Inherit;True;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DynamicAppendNode;23;-417.8369,251.0515;Inherit;True;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StaticSwitch;24;-2280.344,-93.0733;Inherit;False;Property;_Keyword0;Keyword 0;2;0;Create;True;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;26;-2470.845,-90.7804;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;99;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;25;-2752.614,-85.82527;Inherit;False;Property;_CurrentFrame;CurrentFrame;3;0;Create;True;0;0;False;0;False;99;0;0;99;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;53;-188.1853,432.1536;Inherit;True;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;0,0;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;VAT;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;10;0;7;0
WireConnection;10;1;9;0
WireConnection;8;0;10;0
WireConnection;13;0;8;0
WireConnection;13;1;5;0
WireConnection;15;0;13;0
WireConnection;28;0;15;0
WireConnection;16;0;28;0
WireConnection;16;1;5;0
WireConnection;12;0;16;0
WireConnection;4;0;2;1
WireConnection;4;1;17;0
WireConnection;19;0;4;0
WireConnection;1;1;20;0
WireConnection;43;1;44;0
WireConnection;39;0;37;0
WireConnection;39;1;38;0
WireConnection;21;0;1;0
WireConnection;47;0;45;0
WireConnection;47;1;46;0
WireConnection;50;0;43;0
WireConnection;48;0;50;0
WireConnection;48;1;47;0
WireConnection;40;0;21;0
WireConnection;40;1;39;0
WireConnection;49;0;48;0
WireConnection;49;1;46;0
WireConnection;42;0;40;0
WireConnection;42;1;38;0
WireConnection;18;0;42;0
WireConnection;51;0;49;0
WireConnection;52;0;51;2
WireConnection;52;1;51;1
WireConnection;52;2;51;0
WireConnection;23;0;18;2
WireConnection;23;1;18;1
WireConnection;23;2;18;0
WireConnection;24;1;26;0
WireConnection;26;0;25;0
WireConnection;53;0;23;0
WireConnection;53;1;52;0
WireConnection;0;11;53;0
ASEEND*/
//CHKSM=D3217126F1E65DAA5FDE2C3DDE67E65D7A307F1A