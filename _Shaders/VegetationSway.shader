Shader "Custom/VegetationSway" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0

		_Speed ("Sway Speed", Range(20, 50)) = 25
		_Rigidness ("Rigidness", Range(1, 50)) = 25
		_SwayMax ("Sway Max", Range(0.0, 0.9)) = 0.05
		_YOffset ("Y Offset", float) = 0.5
	}

	SubShader {
		Tags { "RenderType"="Opaque" "DisableBatching" = "True" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows vertex:vert addshadow

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		float _Speed;
		float _Rigidness;
		float _SwayMax;
		float _YOffset;

		struct Input {
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		void vert(inout appdata_full v) {
			//Code from Minions Art:
			//https://www.patreon.com/posts/quick-game-art-13724221

			//Finds the vertex position in world space
			float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

			//Calulates the x and z movement using a sign wave
			float x = sin(worldPos.x / _Rigidness + (_Time.x * _Speed)) * (v.vertex.y - _YOffset) * 5;
			float z = sin(worldPos.z / _Rigidness + (_Time.x * _Speed * 0.7)) * (v.vertex.y - _YOffset) * 5;

			//Applies the movement with a limit and y-offset
			v.vertex.x += step(0.0, v.vertex.y - _YOffset) * x * _SwayMax;
			v.vertex.z += step(0.0, v.vertex.y - _YOffset) * z * _SwayMax;
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
