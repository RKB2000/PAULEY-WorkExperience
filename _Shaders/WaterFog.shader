Shader "Hidden/WaterFog"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_TintColour ("Tint Colour", Color) = (0.0, 0.0, 0.0, 1.0)
		_FogDepth ("Fog Depth", float) = 0.3
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass 
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : POSITION;
				float4 screenPos : TEXCOORD1;
				float2 uv : TEXCOORD0;
			};

			v2f vert (appdata v)
			{
				v2f o;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.screenPos = ComputeScreenPos(o.vertex);

				return o;
			}
			
			sampler2D _MainTex;
			sampler2D _CameraDepthTexture;
			float4 _TintColour;
			float _FogDepth;

			fixed4 frag (v2f i) : SV_Target
			{
				
				float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, i.screenPos));
				float value = clamp(smoothstep(_FogDepth - 40, _FogDepth + 10, depth), 0.0, 0.99);
			
				fixed4 view = tex2D(_MainTex, i.uv);

				fixed4 col = lerp(view, _TintColour, value);

				//return float4(value, value, value, 1.0);
				return col;
			}
			ENDCG
		}
	}
}
