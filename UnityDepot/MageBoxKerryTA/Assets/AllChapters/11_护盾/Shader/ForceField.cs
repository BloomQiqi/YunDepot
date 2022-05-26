using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode()]
public class ForceField : MonoBehaviour
{
    public ParticleSystem ps;
    // Start is called before the first frame update
    public GameObject go;
    public int AffectorAmount = 20;

    private ParticleSystem.Particle[] particles;
    private Vector4[] positions;
    private float[] sizes;

    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            DoRaycast();
        }


        ParticleSystem.MainModule psmain = ps.main;
        psmain.maxParticles = AffectorAmount;

        particles = new ParticleSystem.Particle[AffectorAmount];
        positions = new Vector4[AffectorAmount];
        sizes = new float[AffectorAmount];

        int numParticlesAlive = ps.GetParticles(particles);
        for (int i = 0; i < numParticlesAlive; i++)
        {
            positions[i] = particles[i].position;
            sizes[i] = particles[i].GetCurrentSize(ps);
        }
        var hitPosition = go.GetComponent<MeshRenderer>().sharedMaterial.GetVectorArray("HitPosition");
        var hitSize = go.GetComponent<MeshRenderer>().sharedMaterial.GetFloatArray("HitSize");

        go.GetComponent<MeshRenderer>().sharedMaterial.SetVectorArray("HitPosition", positions);
        go.GetComponent<MeshRenderer>().sharedMaterial.SetFloatArray("HitSize", sizes);
        hitPosition = go.GetComponent<MeshRenderer>().sharedMaterial.GetVectorArray("HitPosition");
        hitSize = go.GetComponent<MeshRenderer>().sharedMaterial.GetFloatArray("HitSize");
    }

    void DoRaycast()
    {
        RaycastHit hitInfo;
        Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);

        if (Physics.Raycast(ray, out hitInfo, 1000))
        {
            ps.transform.position = hitInfo.point;
            ps.Emit(1);
        }
    }
}
