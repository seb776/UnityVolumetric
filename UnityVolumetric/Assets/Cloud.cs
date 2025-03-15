using UnityEngine;

[ExecuteInEditMode]
public class Cloud : MonoBehaviour
{
    public Material CloudMaterial;

    void Update()
    {
        if (!CloudMaterial)
        {
            CloudMaterial = this.gameObject.GetComponent<MeshRenderer>().sharedMaterial;
        }
        CloudMaterial.SetVector("_CloudBoxPosition", this.gameObject.transform.position);
        CloudMaterial.SetVector("_CloudBoxScale", this.gameObject.transform.lossyScale);
    }
}
