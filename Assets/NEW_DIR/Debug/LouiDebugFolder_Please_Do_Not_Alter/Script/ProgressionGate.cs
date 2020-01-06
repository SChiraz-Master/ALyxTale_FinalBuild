﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ProgressionGate : MonoBehaviour
{
    [SerializeField]
    private Collider teleportCollider;
    [SerializeField]
    private ParticleSystem[] psNum;
    [SerializeField]
    private ParticleSystem[] psDoor;
    [SerializeField]
    private Animation anim;
    [SerializeField]
    private int shardsNeeded;

    private bool open;
    private bool showingShards;
    private const string playerTag = "Player";

    private void Start()
    {
        teleportCollider.enabled = false;

        foreach (ParticleSystem ps in psDoor)
        {
            ps.Stop();
        }

        foreach (ParticleSystem ps in psNum)
        {
            ps.Stop();
        }
    }

    private void OnTriggerEnter(Collider other)
    {
        if(other.gameObject.layer == 14)
        {
            if(HudManager.shardsCollected >= shardsNeeded && !open)
            {
                open = true;
                anim.Play();

                foreach(ParticleSystem ps in psDoor)
                {
                    ps.Play();
                }

                StartCoroutine(EnableTeleporter());
                //teleportCollider.enabled = true;
            }
            else if(!open)
            {
                showingShards = true;

                foreach(ParticleSystem ps in psNum)
                {
                    ps.Play();
                }
            }
        }
    }

    private void OnTriggerExit(Collider other)
    {
        if (!open && other.gameObject.layer == 14)
        {
            showingShards = false;

            foreach (ParticleSystem ps in psNum)
            {
                ps.Stop();
            }
        }
    }

    IEnumerator EnableTeleporter()
    {
        yield return new WaitForSeconds(2);
        teleportCollider.enabled = true;
    }
}
