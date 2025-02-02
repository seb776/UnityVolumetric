using UnityEngine;

[ExecuteInEditMode]
public class Cloud : MonoBehaviour
{
    private Material _cloudMaterial;

    void Start()
    {
        _cloudMaterial = this.gameObject.GetComponent<MeshRenderer>().material;
    }

    void Update()
    {
        _cloudMaterial.SetVector("_CloudBoxPosition", this.gameObject.transform.position);
        _cloudMaterial.SetVector("_CloudBoxScale", this.gameObject.transform.lossyScale);
    }
}
