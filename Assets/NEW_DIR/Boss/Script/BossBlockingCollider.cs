﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BossBlockingCollider : MonoBehaviour
{
    [SerializeField]
    private bool leftHand;

    [SerializeField]
    private BossV2 bossRef;

    readonly float handOffset = 2f;
    readonly float initBlocking = 8f;

    private void OnCollisionEnter(Collision collision)
    {
        if(collision.gameObject.layer == 9 && !collision.collider.isTrigger)
        {
            if(leftHand)
            {
                bossRef.leftHandBlocking = initBlocking;
                bossRef.leftHandBlockingPoint = collision.gameObject.transform.position - (Vector3.right * handOffset);
                bossRef.leftHandParentAnim.enabled = false;
            }
            else
            {
                bossRef.rightHandBlocking = initBlocking;
                bossRef.rightHandBlockingPoint = collision.gameObject.transform.position + (Vector3.right * handOffset);
            }
        }
    }
}
