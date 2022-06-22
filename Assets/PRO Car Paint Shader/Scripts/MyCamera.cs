using UnityEngine;
using System.Collections;

#if UNITY_EDITOR
using UnityEditor;
#endif

public enum everyFrameOptions
{
	Update,
	LateUpdate,
	FixedUpdate}

;

public class MyCamera : MonoBehaviour
{
	public CamRotation Rotation;
	[Space][Space]
	public Rays RaysCaster;


	void Awake()
	{
	}

	void Start()
	{
		InvokeRepeating("check", 1, RaysCaster.refreshrate);
		Rotation.Start(transform);
	}

	Transform hit;
	Transform obstacle;

	void check()
	{
		hit = RaysCaster.castray(transform.position, transform.forward);
		if (hit != null && hit.tag == "obstacle")
			obstacle = hit;
	}

	void Update()
	{
		if (Rotation.Frame == everyFrameOptions.Update)
			Rotation.Move(transform);
		if (RaysCaster.Frame == everyFrameOptions.Update)
			RaysCaster.Update(transform);
	}

	void LateUpdate()
	{
		if (obstacle != null) {
			if (obstacle == hit)
				obstacle.GetComponent<MeshRenderer>().material.SetFloat("_Transparency", Mathf.Lerp(obstacle.GetComponent<MeshRenderer>().material.GetFloat("_Transparency"), 0, Time.deltaTime * 2));
			else
				obstacle.GetComponent<MeshRenderer>().material.SetFloat("_Transparency", Mathf.Lerp(obstacle.GetComponent<MeshRenderer>().material.GetFloat("_Transparency"), 1, Time.deltaTime * 2));
		}

		if (Rotation.Frame == everyFrameOptions.LateUpdate)
			Rotation.Move(transform);
		if (RaysCaster.Frame == everyFrameOptions.LateUpdate)
			RaysCaster.Update(transform);
	}

	void FixedUpdate()
	{
		if (Rotation.Frame == everyFrameOptions.FixedUpdate)
			Rotation.Move(transform);
		if (RaysCaster.Frame == everyFrameOptions.FixedUpdate)
			RaysCaster.Update(transform);
	}
}

[System.Serializable]
public class Rays
{
	private Ray ray;
	private RaycastHit hit;
	public string EventToSend = "";
	public int layer = 8;
	public string Tag = "Player";
	public Transform hitted;
	public float refreshrate = 1;

	public everyFrameOptions Frame = everyFrameOptions.FixedUpdate;

	public Transform castray(Vector3 position, Vector3 direction)
	{
		if (Physics.Raycast(position, direction, out hit)) {
			return hitted = hit.transform;
		}
		return null;
	}

	public void Update(Transform trans)
	{
		if (Input.touchCount != 0 || Input.GetButtonDown("Fire1")) {
			if (Input.touchCount != 0) {
				Touch touch = Input.touches[0];
				ray = Camera.main.ScreenPointToRay(touch.position);

				if (Physics.Raycast(ray, out hit, 100f)) {
					if (layer == 0 && Tag != "" && Tag == hit.transform.tag) {
						if (hit.transform != trans.GetComponent <MyCamera>().Rotation.targetObject) {
							trans.GetComponent <MyCamera>().Rotation.targetObject = hit.transform;
							trans.GetComponent <MyCamera>().Rotation.Arrange = true;
						}
					} else if (Tag == "" && layer != 0 && hit.transform.gameObject.layer == layer) {
						if (hit.transform != trans.GetComponent <MyCamera>().Rotation.targetObject) {
							trans.GetComponent <MyCamera>().Rotation.targetObject = hit.transform;
							trans.GetComponent <MyCamera>().Rotation.Arrange = true;
						}
					} else if (Tag == hit.transform.tag && hit.transform.gameObject.layer == layer) {
						if (hit.transform != trans.GetComponent <MyCamera>().Rotation.targetObject) {
							trans.GetComponent <MyCamera>().Rotation.targetObject = hit.transform;
							trans.GetComponent <MyCamera>().Rotation.Arrange = true;
						}
					}
				}

			} else if (Input.GetButtonDown("Fire1")) {
				ray = Camera.main.ScreenPointToRay(Input.mousePosition);

				if (Physics.Raycast(ray, out hit, 100f)) {
					if (layer == 0 && Tag != "" && Tag == hit.transform.tag) {
						if (hit.transform != trans.GetComponent <MyCamera>().Rotation.targetObject) {
							trans.GetComponent <MyCamera>().Rotation.targetObject = hit.transform;
							trans.GetComponent <MyCamera>().Rotation.Arrange = true;
						}
					} else if (Tag == "" && layer != 0 && hit.transform.gameObject.layer == layer) {
						if (hit.transform != trans.GetComponent <MyCamera>().Rotation.targetObject) {
							trans.GetComponent <MyCamera>().Rotation.targetObject = hit.transform;
							trans.GetComponent <MyCamera>().Rotation.Arrange = true;
						}
					} else if (Tag == hit.transform.tag && hit.transform.gameObject.layer == layer) {
						if (hit.transform != trans.GetComponent <MyCamera>().Rotation.targetObject) {
							trans.GetComponent <MyCamera>().Rotation.targetObject = hit.transform;
							trans.GetComponent <MyCamera>().Rotation.Arrange = true;
						}
					}
				}
			}
			hitted = hit.transform;
		}
	}
}

[System.Serializable]
public class CamRotation
{
	[Header("-----------------Main-----------------")]
	public bool Enable = true;
	public bool GetInput = true;
	[Range(0.0f, 1.0f)]
	public float Optimizer = 0.5f;
	public bool Arrange = true;
	public bool idleRotation = true;
	public bool useCurrentLoc = true;
	public everyFrameOptions Frame = everyFrameOptions.FixedUpdate;
	[Space][Space]

	[Header("----------------Target----------------")]
	public Transform targetObject;
	public Vector3 targetOffset = new Vector3(0f, -0.75f, 0f);
	[Space][Space]

	[Header("-------------Configuration------------")]
	public float averageDistance = 8.0f;
	public Vector2 DistanceMinMax = new Vector2(7f, 12f);
	public Vector2 YLimit = new Vector2(-3f, 25f);
	public Vector2 sensivety = new Vector2(200f, 200f);
	public int zoomSpeed = 40;
	public float zoomDampening = 5.0f;
	[Range(0.0f, 10.0f)]
	public float idleWait = 1;
	public float idleSpeed = 200.0f;

	public Vector2 RoationMinMax = new Vector2(47f, 10.4f);
	private float currentDistance;
	private float desiredDistance;
	private Quaternion currentRotation;
	private Quaternion desiredRotation;
	private Quaternion rotation;
	private Vector3 position;
	private float idleTimer = 0.0f;
	private float idleSmooth = 0.0f;


	public void Start(Transform trans)
	{
		if (!targetObject) {
			if (GameObject.FindGameObjectWithTag("Player"))
				targetObject = GameObject.FindGameObjectWithTag("Player").transform;
			else {
				GameObject go = new GameObject("Cam Target");
				go.transform.position = trans.position + (trans.forward * averageDistance);
				targetObject = go.transform;
			}
		}
		currentDistance = averageDistance;
		desiredDistance = averageDistance;

		position = trans.position;
		rotation = trans.rotation;
		currentRotation = trans.rotation;
		desiredRotation = trans.rotation;

		if (useCurrentLoc) {
			RoationMinMax.x = Vector3.Angle(Vector3.right, trans.right);
			RoationMinMax.y = Vector3.Angle(Vector3.up, trans.up);
		}

		position = targetObject.position - (rotation * Vector3.forward * currentDistance + targetOffset);
	}

	public void  Move(Transform trans)
	{
		if (Enable)
			rotatearound(trans);
		else if (Arrange == false)
			Arrange = true;
	}

	public void ToggleInput()
	{
		GetInput = !GetInput;
	}

	public void ToggleEnable()
	{
		Enable = !Enable;
	}

	public void SetInput(bool value)
	{
		GetInput = value;
	}

	public void SetEnable(bool value)
	{
		Enable = value;
	}

	void rotatearound(Transform trans)
	{

		if (!Arrange) {
			if (GetInput && Input.GetMouseButton(2) && Input.GetKey(KeyCode.LeftAlt) && Input.GetKey(KeyCode.LeftControl)) {
				desiredDistance -= Input.GetAxis("Mouse Y") * 0.02f * zoomSpeed * 0.125f * Mathf.Abs(desiredDistance);
			} else if (GetInput && Input.GetMouseButton(0)) {
				RoationMinMax.x += Input.GetAxis("Mouse X") * sensivety.x * 0.02f;
				RoationMinMax.y -= Input.GetAxis("Mouse Y") * sensivety.y * 0.02f;
				RoationMinMax.y = ClampAngle(RoationMinMax.y, YLimit.x, YLimit.y);

				desiredRotation = Quaternion.Euler(RoationMinMax.y, RoationMinMax.x, 0);
				currentRotation = trans.rotation;
				rotation = Quaternion.Lerp(currentRotation, desiredRotation, 0.02f * zoomDampening);
				trans.rotation = rotation;
				idleTimer = 0;
				idleSmooth = 0;

			} else {
				idleTimer += 0.02f;
				if (idleTimer > idleWait) {
					idleSmooth += (0.02f + idleSmooth) * 0.005f;
					idleSmooth = Mathf.Clamp(idleSmooth, 0, 1);
					if (idleRotation)
						RoationMinMax.x += idleSpeed * 0.001f * idleSmooth;
				}

				RoationMinMax.y = ClampAngle(RoationMinMax.y, YLimit.x, YLimit.y);
				desiredRotation = Quaternion.Euler(RoationMinMax.y, RoationMinMax.x, 0);
				currentRotation = trans.rotation;
				rotation = Quaternion.Lerp(currentRotation, desiredRotation, Time.smoothDeltaTime);
				trans.rotation = rotation;
			}
		} else {
			desiredRotation = Quaternion.Euler(RoationMinMax.y, RoationMinMax.x, 0);
			currentRotation = trans.rotation;
			rotation = Quaternion.Lerp(currentRotation, desiredRotation, Time.smoothDeltaTime * 1f);
			trans.rotation = rotation;
		}

		if (GetInput)
			desiredDistance -= Input.GetAxis("Mouse ScrollWheel") * 0.02f * zoomSpeed * Mathf.Abs(desiredDistance);

		desiredDistance = Mathf.Clamp(desiredDistance, DistanceMinMax.x, DistanceMinMax.y);
		currentDistance = Mathf.Lerp(currentDistance, desiredDistance, 0.02f * zoomDampening);
		position = targetObject.position - (rotation * Vector3.forward * currentDistance + targetOffset);

		if (Arrange) {
			trans.position = Vector3.Lerp(trans.position, position, Time.smoothDeltaTime * 4);
			if (trans.position.x > position.x - Optimizer && trans.position.x < position.x + Optimizer &&
			    trans.position.y > position.y - Optimizer && trans.position.y < position.y + Optimizer &&
			    trans.position.z > position.z - Optimizer && trans.position.z < position.z + Optimizer)
				Arrange = false;
		} else
			trans.position = position;
	}

	private static float ClampAngle(float angle, float min, float max)
	{
		if (angle < -360)
			angle += 360;
		if (angle > 360)
			angle -= 360;
		return Mathf.Clamp(angle, min, max);
	}
}