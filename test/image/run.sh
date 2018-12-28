#!/bin/bash

function base() {
cd /FISCO-BCOS/cert/GM
chmod +x *.sh
apt-get update
sed -i 's/sudo//g' *.sh
apt-get install -y git make vim openjdk-8-jdk
export HOME=/usr/local
sed -i 's/\ config/\ \.\/config/g' gmchain.sh
fisco-bcos --newaccount > god.txt
GOD_ADDRESS=`cat god.txt|grep address|awk -F':' '{print $NF}'`
}

#Makefile:548: recipe for target 'install_sw' failed
#make: *** [install_sw] Error 1
#execute command bash config --prefix=/FISCO-BCOS/cert/GM/TASSL no-shared && make -j2 && make install FAILED

#./gmchain.sh
#./gmagency.sh ANNE
#./gmnode.sh WB node-0
#./gmsdk.sh WB sdk
#cp genesis.json config.json log.conf start.sh stop.sh WB/node-0/
#Warning:
#The JKS keystore uses a proprietary format. It is recommended to migrate to PKCS12 which is an industry standard format using "keytool -importkeystore -srckeystore client.keystore -destkeystore client.keystore -deststoretype pkcs12".

function genChainInit() {
   ./gmchain.sh 
}

function genSdk() {
    if [ "$#" -ne 2 ];then
        echo "addAgency blockchain.bqj.cn sdkN";
        return 
    fi;
    ORG=$1
    SDK=$2
    ./gmsdk.sh $ORG $SDK

    for i in `ls -lt ./${ORG}|grep drw|grep -v $SDK|awk '{print $NF}'`
    do
        cp ./${ORG}/${SDK}/{server.crt,server.key,ca.crt} ./${ORG}/${i}/data/
    done
    echo "please mv ./${ORG}/${SDK}/{ca.crt,client.keystore} to target sdk dir,for example: /mydata/web3sdk/dist/conf/"
    echo "one Org only generation one sdk is enough"
}

function addAgency() {
    if [ "$#" -ne 1 ];then
        echo "addAgency blockchain.bqj.cn";
        return 
    fi;
    ORG=$1
   ./gmagency.sh $ORG
}

function genGenesisNode(){
    if [ "$#" -ne 3 ];then
        echo "genNodeDir ORG Node GodAddress ";
        return 
    fi;
    ORG=$1
    NODE=$2
    GOD=$3

    ./gmnode.sh $ORG  $NODE 
    mkdir -p ./${ORG}/${NODE}/{data,log,keystore}
    NODEID=$(cat ./${ORG}/${NODE}/gmnode.nodeid)
    mv ./${ORG}/${NODE}/gm* ./${ORG}/${NODE}/data/
    cp /FISCO-BCOS/{start.sh,stop.sh} ./${ORG}/${NODE}/
    cat > ./${ORG}/${NODE}/config.json <<EOF
{
        "sealEngine": "PBFT",
        "systemproxyaddress":"0x0",
        "listenip":"0.0.0.0",
        "cryptomod":"0",
        "rpcport": "8545",
        "p2pport": "30303",
        "channelPort": "30304",
        "wallet":"./data/keys.info",
        "keystoredir":"./data/keystore/",
        "datadir":"./data/",
        "vm":"interpreter",
        "networkid":"12345",
        "logverbosity":"4",
        "coverlog":"OFF",
        "eventlog":"ON",
        "statlog":"OFF",
        "logconf":"./log.conf"
}
EOF
    cat > ./${ORG}/${NODE}/genesis.json <<EOF
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
     "initMinerNodes":["${NODEID}"]
}
EOF
    cat > ./${ORG}/${NODE}/data/bootstrapnodes.json <<EOF
{
    "nodes":[{"host":"127.0.0.1","p2pport":"30303"}]
}
EOF

    cat > ./${ORG}/${NODE}/log.conf <<EOF
* GLOBAL:
    ENABLED                 =   true
    TO_FILE                 =   true
    TO_STANDARD_OUTPUT      =   false
    FORMAT                  =   "%level|%datetime{%Y-%M-%d %H:%m:%s:%g}|%msg"
    FILENAME                =   "./log/log_%datetime{%Y%M%d%H}.log"
    MILLISECONDS_WIDTH      =   3
    PERFORMANCE_TRACKING    =   false
    MAX_LOG_FILE_SIZE       =   209715200 ## 200MB - Comment starts with two hashes (##)
    LOG_FLUSH_THRESHOLD     =   100  ## Flush after every 100 logs

* TRACE:
    ENABLED                 =   true
    FILENAME                =   "./log/trace_log_%datetime{%Y%M%d%H}.log"

* DEBUG:
    ENABLED                 =   true
    FILENAME                =   "./log/debug_log_%datetime{%Y%M%d%H}.log"

* FATAL:
    ENABLED                 =   true
    FILENAME                =   "./log/fatal_log_%datetime{%Y%M%d%H}.log"

* ERROR:
    ENABLED                 =   true
    FILENAME                =   "./log/error_log_%datetime{%Y%M%d%H}.log"

* WARNING:
     ENABLED                 =   true
     FILENAME                =   "./log/warn_log_%datetime{%Y%M%d%H}.log"

* INFO:
    ENABLED                 =   true
    FILENAME                =   "./log/info_log_%datetime{%Y%M%d%H}.log"

* VERBOSE:
    ENABLED                 =   true
    FILENAME                =   "./log/verbose_log_%datetime{%Y%M%d%H}.log"

EOF
    
   # mv ./${ORG}/${NODE}/{gmca.crt,gmagency.crt,gmnode.crt,gmnode.key,gmnode.private} ./${ORG}/${NODE}/data/
    #genesis.json config.json log.conf 
    echo "GenesisNode is: ${NODEID}"
}

function genNodeConfig(){
    if [ "$#" -ne 4 ];then
        echo "genNodeDir ORG Node GodAddress GenesisNode";
        return 
    fi;

    ORG=$1
    NODE=$2
    GOD=$3
    GENESISNODE=$4
    ./gmnode.sh $ORG  $NODE
    mkdir -p ./${ORG}/${NODE}/{data,log,keystore}
    mv ./${ORG}/${NODE}/gm* ./${ORG}/${NODE}/data/ 
    cp /FISCO-BCOS/{start.sh,stop.sh} ./${ORG}/${NODE}/
    #mv ./${ORG}/${NODE}/gm* ./${ORG}/${NODE}/data/
    #mv ./${ORG}/${NODE}/{gmca.crt,gmagency.crt,gmnode.crt,gmnode.key,gmnode.private} ./${ORG}/${NODE}/data/
    cat > ./${ORG}/${NODE}/config.json <<EOF
{
        "sealEngine": "PBFT",
        "systemproxyaddress":"0x0",
        "listenip":"0.0.0.0",
        "cryptomod":"0",
        "rpcport": "8545",
        "p2pport": "30303",
        "channelPort": "30304",
        "wallet":"./data/keys.info",
        "keystoredir":"./data/keystore/",
        "datadir":"./data/",
        "vm":"interpreter",
        "networkid":"12345",
        "logverbosity":"4",
        "coverlog":"OFF",
        "eventlog":"ON",
        "statlog":"OFF",
        "logconf":"./log.conf"
}
EOF

    cat > ./${ORG}/${NODE}/genesis.json <<EOF
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
     "initMinerNodes":["${GENESISNODE}"]
}
EOF

    cat > ./${ORG}/${NODE}/log.conf <<EOF
* GLOBAL:
    ENABLED                 =   true
    TO_FILE                 =   true
    TO_STANDARD_OUTPUT      =   false
    FORMAT                  =   "%level|%datetime{%Y-%M-%d %H:%m:%s:%g}|%msg"
    FILENAME                =   "./log/log_%datetime{%Y%M%d%H}.log"
    MILLISECONDS_WIDTH      =   3
    PERFORMANCE_TRACKING    =   false
    MAX_LOG_FILE_SIZE       =   209715200 ## 200MB - Comment starts with two hashes (##)
    LOG_FLUSH_THRESHOLD     =   100  ## Flush after every 100 logs

* TRACE:
    ENABLED                 =   true
    FILENAME                =   "./log/trace_log_%datetime{%Y%M%d%H}.log"

* DEBUG:
    ENABLED                 =   true
    FILENAME                =   "./log/debug_log_%datetime{%Y%M%d%H}.log"

* FATAL:
    ENABLED                 =   true
    FILENAME                =   "./log/fatal_log_%datetime{%Y%M%d%H}.log"

* ERROR:
    ENABLED                 =   true
    FILENAME                =   "./log/error_log_%datetime{%Y%M%d%H}.log"

* WARNING:
     ENABLED                 =   true
     FILENAME                =   "./log/warn_log_%datetime{%Y%M%d%H}.log"

* INFO:
    ENABLED                 =   true
    FILENAME                =   "./log/info_log_%datetime{%Y%M%d%H}.log"

* VERBOSE:
    ENABLED                 =   true
    FILENAME                =   "./log/verbose_log_%datetime{%Y%M%d%H}.log"
EOF
    
}



function genNodePeerYaml(){
    if [ "$#" -ne 2 ];then
        echo "usage: genNodePeerYaml blockchain.bqj.cn peer0";
        return 
    fi;
    ORG=$1
    NODE=$2
    cat >${NODE}.${ORG}.yaml <<EOF
version: "3"
networks:
  bcos-ov:
    external:
      name: bcos-ov
services:
  ${NODE}.${ORG}:
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
    hostname: ${NODE}.${ORG}
    image: fiscobcoswithtool
    ulimits:
      core: -1
    security_opt:
    - seccomp:unconfined
    networks:
      bcos-ov:
        aliases:
        - ${NODE}.${ORG}
    environment:
    - GODEBUG=netdns=go
    command: sh -c 'cd /bcos-data/node && fisco-bcos   --genesis ./genesis.json --config ./config.json'
    volumes:
    - ./${ORG}/${NODE}/:/bcos-data/node
    ports:
    - 8545:8545
    - 30303:30303
    - 30304:30304
EOF
}

function genWeb3SdkYaml(){
    cat >web3sdk.yaml <<EOF
version: "3"
networks:
  bcos-ov:
    external:
      name: bcos-ov
services:
  web3sdk.blockchain.bqj.cn:
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
    hostname: web3sdk.blockchain.bqj.cn
    image: fiscobcos-node
    networks:
      bcos-ov:
        aliases:
        - web3sdk.blockchain.bqj.cn
    environment:
    - GODEBUG=netdns=go
    command: init 
EOF
}