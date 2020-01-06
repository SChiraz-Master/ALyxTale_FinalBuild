﻿//Created by Dylan LeClair 11/27/19

//Player collider must be on layer 14

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PushPlayerOut : MonoBehaviour
{
    //Reference to scripts and component variables
    private Collider platformCollider;
    private MultiPurposePlatform platformScript;
    private PlayerClass playerScript;

    //Raycast variables
    private LayerMask player = 1 << 14;

    //Cache wait time
    private readonly WaitForSeconds timer = new WaitForSeconds(0.5f);

    private void Awake()
    {
        //Find reference to player script
        playerScript = FindObjectOfType<PlayerClass>();
    }

    private void Start()
    {
        //Get reference to components
        platformCollider = GetComponent<Collider>();
        platformScript = GetComponent<MultiPurposePlatform>(); 
    }

    private void Update()
    {
        //Draw box cast down from moving platform
        if (Physics.BoxCast(platformCollider.bounds.center, transform.localScale, transform.TransformDirection(Vector3.down), Quaternion.identity, 
            1.6f, player, QueryTriggerInteraction.UseGlobal))
        {
            //Diable player controls and push player out from under moving platform
            playerScript.DisableControls();
            playerScript.GenericAddForce(transform.right, 1.0f);
        }
    }
}
