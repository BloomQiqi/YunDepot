using UnityEngine;

[DisallowMultipleComponent]
public class PerObjectMaterialProperties : MonoBehaviour
{
	static MaterialPropertyBlock block;

	static int baseColorId = Shader.PropertyToID("_BaseColor");

	[SerializeField]
	Color baseColor = Color.white;
    private void Awake()
    {
        OnValidate();
    }

    //当脚本或组件加载或者设置的值发送改变时调用
    private void OnValidate()
    {
        baseColor = new Color(Random.Range(0f, 1), Random.Range(0f, 1), Random.Range(0f, 1), Random.Range(0f, 1));
        if (block == null)
        {
            block = new MaterialPropertyBlock();
        }
        block.SetColor(baseColorId, baseColor);
        GetComponent<Renderer>().SetPropertyBlock(block);
    }
}