using UnityEngine;
using UnityEngine.Rendering;
public class G1 : MonoBehaviour
{
    //GPU instancing材质
    public Material material;
    //GPU instancing网格
    public Mesh mesh;
    //随便找个位置做随机
    public Transform target;
    //是否使用cammandBuffer渲染
    public bool useCommandBuffer = false;
    //观察摄像机
    public Camera m_Camera;

    private Matrix4x4[] m_atrix4x4s = new Matrix4x4[1023];
    void Start()
    {

        CommandBufferForDrawMeshInstanced();
    }


    private void OnGUI()
    {
        if (GUILayout.Button("<size=50>当位置发生变化时候在更新</size>"))
        {

            CommandBufferForDrawMeshInstanced();
        }
    }

    void Update()
    {

        if (!useCommandBuffer)
        {
            GraphicsForDrawMeshInstanced();
        }

    }


    void SetPos()
    {
        for (int i = 0; i < m_atrix4x4s.Length; i++)
        {
            target.position = Random.onUnitSphere * 10f;
            m_atrix4x4s[i] = target.localToWorldMatrix;
        }

    }


    void GraphicsForDrawMeshInstanced()
    {
        if (!useCommandBuffer)
        {
            SetPos();
            Graphics.DrawMeshInstanced(mesh, 0, material, m_atrix4x4s, m_atrix4x4s.Length);
        }
    }

    void CommandBufferForDrawMeshInstanced()
    {
        if (useCommandBuffer)
        {

            SetPos();
            if (m_buff != null)
            {
                m_Camera.RemoveCommandBuffer(CameraEvent.AfterForwardOpaque, m_buff);
                CommandBufferPool.Release(m_buff);
            }

            m_buff = CommandBufferPool.Get("DrawMeshInstanced");

            for (int i = 0; i < 1; i++)
            {
                m_buff.DrawMeshInstanced(mesh, 0, material, 0, m_atrix4x4s, m_atrix4x4s.Length);
            }
            m_Camera.AddCommandBuffer(CameraEvent.AfterForwardOpaque, m_buff);
        }
    }

    CommandBuffer m_buff = null;

}