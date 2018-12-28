#!/bin/bash
function setup(){
    CURRENTPATH=$PWD
    curl -sL https://deb.nodesource.com/setup_8.x | bash -
    apt-get install -y nodejs
    npm install -g secp256k1 --unsafe-perm
    npm install -g cnpm --registry=https://registry.npm.taobao.org
    cnpm install -g babel-cli babel-preset-es2017 ethereum-console
    echo '{ "presets": ["es2017"] }' > ~/.babelrc
    wget https://github.com/FISCO-BCOS/fisco-solc/raw/master/fisco-solc-ubuntu
    sudo cp fisco-solc-ubuntu  /usr/bin/fisco-solc
    sudo chmod +x /usr/bin/fisco-solc
    cd bcos/systemcontractv2 && cnpm install
    cd $CURRENTPATH/bcos/web3lib && cnpm install 
    cd $CURRENTPATH/bcos/tool && cnpm install 
    cd $CURRENTPATH 
}

function deploySystemContract(){
    CURRENTPATH=$PWD
    cd bcos/systemcontractv2
    babel-node deploy.js 
    echo "===end of deploy systemContract==="
    cd $CURRENTPATH
}

function addNode(){
    CURRENTPATH=$PWD
    cd bcos/systemcontractv2
    if [ "$#" -ne 1 ];then
        echo "addNode node0.json"
        return 
    fi;
    cd bcos/systemcontractv2
    babel-node tool.js NodeAction registerNode $1
    babel-node tool.js NodeAction all
    babel-node monitor.js
    cd $CURRENTPATH
}