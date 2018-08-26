Shader "Custom/Caustics" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

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

		float random1D(float p, float seed) 
		{
			return frac(sin(p) * seed);
		}

		float plot(float2 uv, float base, float eqa) 
		{
			return smoothstep(eqa + 0.45 * abs(sin(uv.x + uv.y + _Time.y * 0.3)), eqa, base) -
				smoothstep(eqa, eqa - 0.45 * abs(cos(uv.x + uv.y + _Time.y * 0.3)), base);
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			float4 col = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			
			//Scales the texture
			float2 uv = IN.uv_MainTex * 50.0;
			
			//Gets the int and fraction value for the point
			//Creates tiles and moves them through time
			float2 i_uv = floor(float2(uv.x + _Time.x * 0.02, uv.y + _Time.x * 0.23));
			float2 f_uv = frac(float2(uv.x + _Time.x * 0.02, uv.y + _Time.x * 0.23));
			
			//Equation for the vertical lines
			float eqaX = lerp(random1D(i_uv.y, i_uv.x * 134785.543), 
							random1D(i_uv.y + 1.0, i_uv.x * 134785.543), 
							smoothstep(0.,1.,f_uv.y));
			
			//Equation for the horizontal lines
			float eqaY = lerp(random1D(i_uv.x, i_uv.y * 53325.345), 
							random1D(i_uv.x + 1.0, i_uv.y * 53325.345), 
							smoothstep(0.,1.0,f_uv.x));
			
			//Adds transparency to minimise the visual artefacts
			float2 alpha = 0.6 - abs(float2(0.5, 0.5) - f_uv);
			
			//Adds the lines onto the background
			float plotX = plot(uv, eqaX, f_uv.x);
			float plotY = plot(uv, eqaY, f_uv.y);

			col += alpha.x * 0.6 * float4(plotX, plotX, plotX, plotX);
			col += alpha.y * 0.6 * float4(plotY, plotY, plotY, plotY);

			o.Albedo = col.rgb;

			// Metallic and smoothness come from slider variables
			o.Metallic = 1.0 - col.x;
			o.Smoothness = col.x;
			o.Alpha = col.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
