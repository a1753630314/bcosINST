#!/bin/bash
function genchainROOTCA(){
    
    bash ../../cert/GM/gmchain.sh
}

function genchainAgencyCA() {
     if [ "$#" -ne 1 ];then
        echo "usage: genchainAgencyCA agencyName"
        return
    fi;
    bash ../../cert/GM/gmagency.sh $1
}


function addagencyNode() {
    if [ "$#" -ne 1 ];then
        echo "usage: genchainAgencyCA agencyName nodeName"
        return
    fi;
   bash ../../cert/GM/gmnode.sh $1
}


function genSDKCert() {
    bash ../../cert/GM/gmsdk.sh sdk
}

