Shader "Unlit/WaterShader"
{
	Properties
	{
		_Colour ("Colour", color) = (1.0, 1.0, 1.0, 1.0)
		_Frequency ("Wave Frequency", float) = 2.0
		_Strength ("Wave Strength", float) = 0.3
		_Speed ("Wave Speed", float) = 0.5

		_FoamDepth ("Foam Depth", float) = 0.4
		_FoamColour ("Foam Colour", color) = (0.0, 0.0, 0.0, 1.0)
		[MaterialToggle] _ShowFoam ("Show Foam", float) = 0.0
	}
	SubShader
	{
		Tags
		{ 
			"Queue" = "Transparent"
		}

		// Grab the screen behind the object into _BackgroundTexture
        GrabPass
        {
            "_BackgroundTexture"
        }

        // Background distortion
        Pass
        {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // Properties
            sampler2D _BackgroundTexture;
			float  _Speed;
			float  _Strength;

            struct vertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float3 texCoord : TEXCOORD0;
            };

            struct vertexOutput
            {
                float4 pos : SV_POSITION;
                float4 grabPos : TEXCOORD0;
            };

            vertexOutput vert(vertexInput input)
            {
                vertexOutput output;

                // convert input to world space
                output.pos = UnityObjectToClipPos(input.vertex);
                float4 normal4 = float4(input.normal, 0.0);
				float3 normal = normalize(mul(normal4, unity_WorldToObject).xyz);

                // use ComputeGrabScreenPos function from UnityCG.cginc
                // to get the correct texture coordinate
                output.grabPos = ComputeGrabScreenPos(output.pos);

				output.grabPos.y += sin(_Time*_Speed) * _Strength;
                output.grabPos.x += cos(_Time*_Speed) * _Strength;

                return output;
            }

            float4 frag(vertexOutput input) : COLOR
            {
                return tex2Dproj(_BackgroundTexture, input.grabPos);
            }
            ENDCG
        }

		Pass
		{
            Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
            #include "UnityCG.cginc"

			#pragma vertex vert
			#pragma fragment frag
			
			// Properties
			float4 _Colour;
			float4 _FoamColour;
			float  _FoamDepth;
			float  _Speed;
			float  _Strength;
			//float _ExtraHeight;
			sampler2D _CameraDepthTexture;
			//sampler2D _MainTex;

			struct vertexInput
			{
				float4 vertex : POSITION;
				float4 texCoord : TEXCOORD1;
			};

			struct vertexOutput
			{
				float4 pos : SV_POSITION;
				float4 texCoord : TEXCOORD0;
				float4 screenPos : TEXCOORD1;
			};

			vertexOutput vert(vertexInput input)
			{
				vertexOutput output;

				// convert to world space
				output.pos = UnityObjectToClipPos(input.vertex);

				output.pos.y += sin(_Time*_Speed)*_Strength;
				output.pos.x += cos(_Time*_Speed)*_Strength;

				// compute depth
				output.screenPos = ComputeScreenPos(output.pos);

				// texture coordinates 
				output.texCoord = input.texCoord;

				return output;
			}

			float4 frag(vertexOutput input) : COLOR
			{
				// apply depth texture
				float4 depthSample = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, input.screenPos);
				float depth = LinearEyeDepth(depthSample).r;

				// create foamline
				float foamLine = 1 - saturate(_FoamDepth * (depth - input.screenPos.w));
				//float4 foamRamp = float4(tex2D(_DepthRampTex, float2(foamLine, 0.5)).rgb, 1.0);

				// sample main texture
				//float4 albedo = tex2D(_MainTex, input.texCoord.xy);

			    float4 col = _Colour + foamLine * _FoamColour;
                return col;
			}

			ENDCG
		}
		
		Pass
        {
			Name  "ShadowPass"
            Tags {"LightMode"="ShadowCaster"}
 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"
 
            struct v2f {
                V2F_SHADOW_CASTER;
            };
 
            v2f vert(appdata_base v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }
 
            float4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }	
	}
}