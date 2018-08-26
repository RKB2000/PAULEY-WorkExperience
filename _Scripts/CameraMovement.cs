using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMovement : MonoBehaviour {

	public List<Transform> positions; 
	
	private int count = 0;
	// Update is called once per frame
	void Update () {
		if (Input.GetKeyDown(KeyCode.Space) || Input.GetKeyDown(KeyCode.Mouse0)) {
			count++;

			if (count > 2) count = 0;

			transform.position = positions[count].position;
		}
	}
}
