using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CameraModifiers : MonoBehaviour {

	public Color tintColour;
	public float fogDepth;

	private Camera cam;
	private Material material;
	// Use this for initialization
	void Awake () {
		//Gets the camera object from the project 
		cam = GetComponent<Camera>();
		material = new Material(Shader.Find("Hidden/WaterFog"));

		//Enables depth detection on the camera
		cam.depthTextureMode = DepthTextureMode.Depth;
	}

	void OnRenderImage (RenderTexture source, RenderTexture destination) {
		if (transform.position.y < 10) {
			material.SetColor("_TintColour", tintColour);
			material.SetFloat("_FogDepth", fogDepth);
			Graphics.Blit(source, destination, material);
		}
		else {
			Graphics.Blit(source, destination);
		}
		
	}
}
