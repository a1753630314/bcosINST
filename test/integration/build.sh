#!/bin/bash

function genPeerYaml(){
    if [ "$#" -ne 1 ];then
        echo "genPeerYaml N(N is an integer)"
        return
    fi;
    NO=$1
    echo "start gen peer${NO}.bcos.bqj.cn.yaml"
    cat > peer${NO}.bcos.bqj.cn.yaml <<EOF
version: "3"
networks:
  bcos-ov:
    external:
      name: bcos-ov
services:
  peer${NO}.bcos.bqj.cn:
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
    hostname: peer${NO}.bcos.bqj.cn
    image: fiscoorg/fiscobcos:latest
    networks:
      bcos-ov:
        aliases:
        - peer${NO}.bcos.bqj.cn
    environment:
    - GODEBUG=netdns=go
    command: sh -c 'fisco-bcos   --genesis /bcos-data/node/genesis.json --config /bcos-data/node/config.json'
    volumes:
    - ./data/node-${NO}/:/bcos-data/node
    - /root/hosts:/etc/hosts
    ulimits:
      core: -1
    security_opt:
    - seccomp:unconfined
EOF
    echo "=============="
    echo "please create your own /root/hosts file for the peer"
    echo "please execute \"echo '/tmp/fisco-bcos.%t.%e.%p' |  tee /proc/sys/kernel/core_pattern \" on every host which run fisco-bcos"
    echo "=============="
    if [ "$NO" -eq 0 ];then 
        cat ports.yaml >> peer${NO}.bcos.bqj.cn.yaml
    fi;
    rm -rf ./data/node-${NO}
    mkdir -p ./data/node-${NO}/{data,log,keystore}
    cp ../../bcos/scripts/{genesis.json,config.json,log.conf,start.sh,stop.sh} ./data/node-${NO}/
}

function InitGenesisNode(){
    genPeerYaml 0
    if [ "$#" -ne 1 ];then
        echo "InitGenesisNode GodAddress";
        return 
    fi;
    GOD=$1
    setCryptoMod 0
    InitNodeId=$(cat ./data/node-0/data/network.rlp.pub) 
    updateGenesis $GOD $InitNodeId
    UpdateConfig 0 $InitNodeId 127.0.0.1 agency0
}

function AddNode(){
    if [ "$#" -ne 2 ];then
        echo "AddNode 0  GodAddress";
        return 
    fi;
    NO=$1
    GOD=$2
    genPeerYaml $NO
    setCryptoMod $NO
    InitNodeId=$(cat ./data/node-${NO}/data/network.rlp.pub) 
    updateGenesis $GOD $InitNodeId
    if [ "$1" -eq 0 ];then
        cp genesis.json ./data/node-${NO}/
    else 
        cp ./data/node-0/genesis.json ./data/node-${NO}/
    fi;
    #if [ "$NO" -eq 0 ];then
    #    echo "start generate genesis node config"
    #    UpdateConfig 0 $InitNodeId 127.0.0.1 agency${NO} 
    #   return
    #fi;
    echo "start generate peer${NO}.bcos.bqj.cn node"
    UpdateConfig $NO $InitNodeId peer${NO}.bcos.bqj.cn agency${NO}
    cp config.json ./data/node-${NO}/
    echo "=====please update ./data/node-${NO}/config.json mannul======"
    genPeerCert $NO
}

function setCryptoMod(){
    if [ "$#" -ne 1 ];then
        echo "setCryptoMod 0"
        return
    fi;
    echo "start generate cryptomod.json"
    I=$1
    cat > cryptomod.json <<EOF
{
	"cryptomod":"0",
	"rlpcreatepath":"./data/node-${I}/data/network.rlp",
	"datakeycreatepath":"",
	"keycenterurl":"",
	"superkey":""
}
EOF
    echo "start gennetworkrlp file"
    fisco-bcos --gennetworkrlp  cryptomod.json
}


function updateGenesis(){
    if [ "$#" -ne 2 ];then
        echo "updateGenesis godAddress InitNodeId"
        return
    fi;
    GOD=$1
    InitNodeId=$2
    echo "start gen genesis.json"
    cat > genesis.json <<EOF
{
     "nonce": "0x0",
     "difficulty": "0x0",
     "mixhash": "0x0",
     "coinbase": "0x0",
     "timestamp": "0x0",
     "parentHash": "0x0",
     "extraData": "0x0",
     "gasLimit": "0x13880000000000",
     "god":"${GOD}",
     "alloc": {}, 	
     "initMinerNodes":["${InitNodeId}"]
}
EOF
}

function UpdateConfig(){
    if [ "$#" -ne 4 ];then
        echo "UpdateConfig Index InitNodeId PeerIp AgencyInfo"
        return
    fi;
    INDEX=$1
    NODEID=$2
    PEERIP=$3
    AGENCYINFO=$4
    echo "start gen config.json"
    cat > config.json <<EOF
{
        "sealEngine": "PBFT",
        "systemproxyaddress":"0x0",
        "listenip":"0.0.0.0",
        "cryptomod":"0",
        "ssl":"0",
        "rpcport": "8545",
        "p2pport": "30303",
        "channelPort": "30304",
        "wallet":"/bcos-data/node/keys.info",
        "keystoredir":"/bcos-data/node/keystore/",
        "datadir":"/bcos-data/node/data/",
        "vm":"interpreter",
        "networkid":"12345",
        "logverbosity":"4",
        "coverlog":"OFF",
        "eventlog":"ON",
        "statlog":"OFF",
        "logconf":"/bcos-data/node/log.conf",
        "params": {
                "accountStartNonce": "0x0",
                "maximumExtraDataSize": "0x0",
                "tieBreakingGas": false,
                "blockReward": "0x0",
                "networkID" : "0x0"
        },
        "NodeextraInfo":[
                {
                "Nodeid":"${NODEID}",
                "Nodedesc": "node${INDEX}",
                "Agencyinfo": "${AGENCYINFO}",
                "Peerip": "${PEERIP}",
                "Identitytype": 1,
                "Port":30303,
                "Idx":${INDEX}
                }
        ]
}
EOF
    cat > node${INDEX}.json <<EOF
{
    "id":"${NODEID}",
    "ip":"peer${INDEX}.bcos.bqj.cn",
    "port":30303,
    "category":1,
    "desc":"node${INDEX}",
    "CAhash":"",
    "agencyinfo":"${AGENCYINFO}",
    "idx":${INDEX}
}
EOF
    cp node${INDEX}.json ../../bcos/systemcontractv2
}


function genPeerCert(){
    if [ "$#" -ne 1 ];then
        echo "genPeerCert IndexNum "
    fi;
    IndexNum=$1
    ./genkey.sh server ./ca.key ./ca.crt 365
    cp ca.crt server.crt server.key ./data/node-$1/data/
    openssl x509 -noout -in server.crt -serial
    echo "moved ca.crt server.crt server.key ./data/node-$1/data/"
    SERIAL=$(openssl x509 -noout -in server.crt -serial|awk -F'=' '{print $2}')
    cat > ca-${IndexNum}.json <<EOF
{
        "hash" : "${SERIAL}",
        "status" : 1,
        "pubkey":"",
        "orgname":"",
        "notbefore":20170223,
        "notafter":20180223,
        "whitelist":"",
        "blacklist":""
}
EOF
 cp ca-${IndexNum}.json ../../bcos/systemcontractv2/
}

function genRootCA(){
    ./genkey.sh ca 3650
}
#ls data/node-*/data -d
#./genkey.sh ca 3650
#./genkey.sh server ./ca.key ./ca.crt 365
