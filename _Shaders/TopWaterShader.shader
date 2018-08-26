/* 
*	Used:
*	https://en.wikibooks.org/wiki/Cg_Programming/Unity/Reflecting_Surfaces
*	For help with the reflection and cube mapping
*
*	https://lindseyreidblog.wordpress.com/2017/12/15/simple-water-shader-in-unity/
* 	For help with the foam generation around objects
*/

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
		_FoamHeight ("Minimum Water Height for Foam", float) = 0.4
		[MaterialToggle] _ShowFoam ("Show Foam", float) = 0.0

		_Cube ("Reflection Map", Cube) = "" {}
		_RefTrans ("Reflection Opacity", Range(0, 1)) = 0.2
	}
	SubShader
	{
		Tags { 
			"RenderType" = "Opaque"
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
		
			//Needed for general unity commands
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 screenPos : TEXCOORD1;
				float objectY : TEXCOORD2;

				float3 normalDir : TEXCOORD3;
				float3 viewDir : TEXCOORD4;
			};

			//The reflection map for above water
			samplerCUBE _Cube;
			half _RefTrans;

			//Default colour/tint
			float4 _Colour;

			//Foam Properties
			float4 _FoamColour;
			half _FoamDepth;
			half _FoamHeight;
			half _ShowFoam;

			//Wave Properties
			half _Frequency;
			half _Strength;
			half _Speed;
			
			v2f vert (appdata v)
			{
				v2f o;

				o.vertex = UnityObjectToClipPos(v.vertex);

				//Moves the vertices in the y direction using a sine wave
				v.vertex.y += sin(o.vertex.x * o.vertex.z * _Frequency + _Time.y * _Speed) * _Strength;
				v.vertex.y += saturate(sin(o.vertex.z * o.vertex.z * 300 + _Time.y * _Speed));

				//Calculates the view direction (towards the point) and the normal direction (of the point)
				o.viewDir = mul(unity_ObjectToWorld, v.vertex).xyz - _WorldSpaceCameraPos;
            	o.normalDir = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);

				o.vertex = UnityObjectToClipPos(v.vertex);

				//Gets the screen position of the vertex
				o.screenPos = ComputeScreenPos(o.vertex);
				o.objectY = v.vertex.y;

				return o;
			}

			//Unity standard property for the camera depth - needs a script on the camera enabling depth detection
			sampler2D _CameraDepthTexture;
			
			fixed4 frag (v2f i) : COLOR
			{
				// sample the texture
				fixed4 col = _Colour;
				col.a = 1.0;
				
				//Calulates the depth of the point
				float4 depthSample = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, i.screenPos);

				//Calculates the depth towards that point
				float depth = LinearEyeDepth(depthSample);

				//Makes the foam if the depth is <1
				float4 foamLine = 1.0 - saturate(_FoamDepth * (depth - i.screenPos.w));
				foamLine.a = 1.0;

				//Adds in foam depending on the water height
				foamLine += smoothstep(_FoamHeight, 1.5, i.objectY);

				//Calculates the reflected direction between the view direction and normal direction
				float3 reflectedDir = reflect(i.viewDir, normalize(i.normalDir));

				//Distorts the reflection based on water height
				reflectedDir.x += sin(foamLine.y + _Time) * saturate(_WorldSpaceCameraPos.y - 10);

				//Adds the reflection onto the water
				col += _RefTrans * texCUBE(_Cube, reflectedDir);

				return col + foamLine * _FoamColour * step(0.5, _ShowFoam);
			}
			ENDCG
		}
	}
}