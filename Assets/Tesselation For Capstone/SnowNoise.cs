﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SnowNoise : MonoBehaviour
{

    public Shader snowFallShader;
    private Material snowFallMat;
    private MeshRenderer meshRenderer;
    [Range(0, 0.1f)]
    public float flakeAmount;
    [Range(0, 1)]
    public float flakeOpacity;

    // Start is called before the first frame update
    void Start()
    {
        meshRenderer = GetComponent<MeshRenderer>();
        snowFallMat = new Material(snowFallShader);
    }

    // Update is called once per frame
    void Update()
    {
        snowFallMat.SetFloat("_FlakeAmount", flakeAmount);
        snowFallMat.SetFloat("_FlakeOpacity", flakeOpacity);
        RenderTexture snow = (RenderTexture)meshRenderer.material.GetTexture("_Splat");
        RenderTexture temp = RenderTexture.GetTemporary(snow.width, snow.height, 0, RenderTextureFormat.ARGBFloat);
        Graphics.Blit(snow, temp, snowFallMat);
        Graphics.Blit(temp, snow);
        meshRenderer.material.SetTexture("_Splat", snow);
        RenderTexture.ReleaseTemporary(temp);
    }
}
