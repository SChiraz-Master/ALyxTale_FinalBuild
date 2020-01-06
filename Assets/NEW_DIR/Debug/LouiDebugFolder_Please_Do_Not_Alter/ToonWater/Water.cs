﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Water : MonoBehaviour
{
    public static WaterParticleManager wpm;
    Vector3 locationSet;
    private HandleSfx sfx;

    private void Start()
    {
        sfx = GetComponent<HandleSfx>();
        if(wpm == null)
        {
            wpm = GameObject.Find("WaterParticleManager").GetComponent<WaterParticleManager>();
        }

        locationSet.y = transform.position.y;
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.gameObject.layer == 14)
        {
            //No check for rigidbody here because this collision cannot happen if the entering entity does not have one
            Rigidbody rb = other.gameObject.GetComponentInParent<Rigidbody>();
            locationSet.x = other.gameObject.transform.position.x;
            locationSet.y = transform.position.y;
            locationSet.z = other.gameObject.transform.position.z;
            wpm.Splash(locationSet, rb.mass, rb.velocity.magnitude);
            if(sfx != null)
            {
                sfx.PlayOneShotByIndex(0);
            }
        }
    }

    
}
