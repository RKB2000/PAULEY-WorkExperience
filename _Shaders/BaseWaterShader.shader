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
		Tags { 
			"Queue"="Geometry"
			}
		
		LOD 200

		Pass
		{  
			Name  "InitialPass"
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			//#pragma multi_compile_instancing
		
			//Needed for ComputeScreenPos
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float4 screenPos : TEXCOORD1;
			};

			//Default colour/tint
			float4 _Colour;

			//Foam Properties
			float4 _FoamColour;
			half _FoamDepth;
			half _ShowFoam;

			//Wave Properties
			half _Frequency;
			half _Strength;
			half _Speed;
			
			v2f vert (appdata v)
			{
				v2f o;

				//Converts the vertex to world coords
				o.vertex = UnityObjectToClipPos(v.vertex);
				UNITY_TRANSFER_FOG(o,o.vertex);

				//Moves the vertices in the y direction using a sine wave
				o.vertex.y += sin(o.vertex.x * o.vertex.z * _Frequency + _Time.y * _Speed) * _Strength;

				//Gets the screen position of the vertex
				o.screenPos = ComputeScreenPos(o.vertex);

				return o;
			}

			//Unity standard property for the camera depth - needs a script on the camera enabling depth detection
			sampler2D _CameraDepthTexture;
			
			fixed4 frag (v2f i) : COLOR
			{
				// sample the texture
				fixed4 col = _Colour;
				
				//Calulates the depth of the point
				float4 depthSample = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, i.screenPos);

				//Calculates the depth towards that point
				float depth = LinearEyeDepth(depthSample);

				//Makes the foam if the depth is <1
				float4 foamLine = 1.0 - saturate(_FoamDepth * (depth - i.screenPos.w));
				foamLine.w = 1.0;

				return col + foamLine * _FoamColour * step(0.5, _ShowFoam);
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