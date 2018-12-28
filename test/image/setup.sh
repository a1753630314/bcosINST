#!/bin/bash
echo "please enable core dump with following command"
echo "echo '/tmp/core.%t.%e.%p' |  tee /proc/sys/kernel/core_pattern
"
function buildBcos(){
    echo "are you sure you hava place FISCO-BCOS code to directory ./FISCO-BCOS [Y/N]:"
    read yes
    case $yes in
        Yes|Y)
            buildImage 
            ;;
        No|N)
            echo "please download the code by the command below. And then re-execute this function."
            echo "wget https://github.com/FISCO-BCOS/FISCO-BCOS/archive/master.zip"
            echo "unzip FISCO-BCOS-master.zip"
            ;;
        *)
            echo "invalid input $yes"
            return 
            ;;
    esac
}

function buildImage() {
    echo "do you want  make fisco-bcos support GM ALG [Y/N]:"
    DOCKERFILE="Dockerfile"
    SOLC_TOOL="fisco-solc"
    IMAGE_NAME="fiscobcosdev"
    read gm
    case $gm in
        Yes|Y)
            genGMDockerfile
            DOCKERFILE="Dockerfilegm"
            SOLC_TOOL="fisco-solc-guomi"
            IMAGE_NAME="fiscobcosdevguomi"
            ;;
        No|N)
            genNonGMDockerfile
            ;;
        *)
            echo "invalid option $gm"
            return 
            ;;
    esac
    echo "start build the image"
    chmod +x $SOLC_TOOL
    docker build . -t $IMAGE_NAME -f $DOCKERFILE
}

function genDockerfile() {
    echo "do you want  make fisco-bcos support GM ALG [Y/N]:"
    read gm;
    case $gm in 
        Yes|Y):
            genGMDockerfile
            ;;
        No|N):
            genNonGMDockerfile
            ;;
    esac
}

function genNonGMDockerfile() {
    cat > Dockerfile <<EOF
FROM centos:7.2.1511
COPY ./FISCO-BCOS /FISCO-BCOS
RUN cp ./FISCO-BCOS/fisco-solc /usr/local/bin/fisco-solc
RUN chmod +x /usr/local/bin/fisco-solc
RUN ulimit -c unlimited
RUN echo 'kernel.core_pattern = /var/core/fisco_bcos_%e_%p\n kernel.core_uses_pid = 0' >> /etc/sysctl.conf
RUN yum update && yum install -y git openssl openssl-devel deltarpm cmake3 gcc-c++
RUN cd /FISCO-BCOS  &&  chmod +x scripts/install_deps.sh  && ./scripts/install_deps.sh
RUN  cd /FISCO-BCOS && mkdir -p build && cd build  && \
    cmake  -DEVMJIT=OFF -DTESTS=OFF -DMINIUPNPC=OFF .. \
    && make  && make install && make clean  && mkdir -p /bcos-data/node
ENV HOME /usr/local
RUN cd /FISCO-BCOS/cert && chmod +x *.sh && sed -i 's/sudo//g' *.sh && sed -i 's/\ config/\ \.\/config/g' chain.sh  && rm -rf /FISCO-BCOS/.git &&  cd /FISCO-BCOS/deps/src && rm -rf \$( ls -lt|grep drw|awk '{print \$NF}')
EOF
}

function genGMDockerfile() {
    cat > Dockerfilegm <<EOF
FROM centos:7.2.1511
COPY ./FISCO-BCOS /FISCO-BCOS
RUN cp ./FISCO-BCOS/fisco-solc-guomi-centos /usr/local/bin/fisco-solc-guomi 
RUN chmod +x /usr/local/bin/fisco-solc-guomi
RUN ulimit -c unlimited
RUN echo 'kernel.core_pattern = /var/core/fisco_bcos_%e_%p\n kernel.core_uses_pid = 0' >> /etc/sysctl.conf
EOF
}

function genGMDockerfile2() {
    cat > Dockerfilegm <<EOF
FROM centos:7.2.1511
COPY ./FISCO-BCOS /FISCO-BCOS
RUN cp ./FISCO-BCOS/fisco-solc-guomi-centos /usr/local/bin/fisco-solc-guomi 
RUN chmod +x /usr/local/bin/fisco-solc-guomi
RUN ulimit -c unlimited
RUN echo 'kernel.core_pattern = /var/core/fisco_bcos_%e_%p\n kernel.core_uses_pid = 0' >> /etc/sysctl.conf
RUN yum -y update && yum install -y git openssl openssl-devel deltarpm cmake3 gcc-c++
RUN cd /FISCO-BCOS  &&  chmod +x scripts/install_deps.sh  && sleep 1 && ./scripts/install_deps.sh
RUN cd /FISCO-BCOS && mkdir -p build && cd build  && \
    cmake3 -DENCRYPTTYPE=ON -DEVMJIT=OFF -DTESTS=OFF -DMINIUPNPC=OFF .. \
    && make  && make install && make clean  && mkdir -p /bcos-data/node
RUN yum install -y curl apt-utils vim vim-common flex bison gcc g++  apport
RUN yum install java-1.8.0-openjdk  java-1.8.0-openjdk-devel
RUN yum install net-tools.x86_64
RUN yum install -y nodejs
RUN npm install -g cnpm --registry=https://registry.npm.taobao.org
RUN cnpm install -g babel-cli babel-preset-es2017 ethereum-console
RUN echo '{ "presets": ["es2017"] }' > ~/.babelrc
ENV HOME /usr/local
RUN cd /FISCO-BCOS/cert/GM && chmod +x *.sh && sed -i 's/sudo//g' *.sh && sed -i 's/\ config/\ \.\/config/g' gmchain.sh  && rm -rf /FISCO-BCOS/.git &&  cd /FISCO-BCOS/deps/src && rm -rf \$(ls -lt|grep drw|awk '{print \$NF}') 
EOF
}

function genJavaSDKDockerfile(){
    cat >Dockerfilejavasdk <<EOF
FROM ubuntu:16.04
ADD ./web3sdk-master /web3sdk 
ADD ./fisco-solc-master /fisco-solc
VOLUME [ "/contracts" ]
RUN apt-get update && apt-get install -y git lsof tofrodos openjdk-8-jdk gradle  \
    &&  chmod +x /web3sdk/tools/bin/web3sdk && cd /web3sdk && gradle build && chmod +x /web3sdk/dist/bin/web3sdk
RUN cd /fisco-solc && chmod +x scripts/install_deps.sh && apt-get install -y cmake make 
#RUN mkdir -p build && cd build && cmake -DENCRYPTTYPE=ON .. && make && cd solc && mv fisco-solc /usr/bin/fisco-solc-guomi
#RUN cd /fisco-solc/build && cmake .. && make clean && make && cd  solc && mv fisco-solc /usr/bin/fisco-solc
RUN cp /fisco-solc/fisco-solc-guomi-ubuntu /usr/bin/fisco-solc-guomi
RUN cp /fisco-solc/fisco-solc-ubuntu /usr/bin/fisco-solc
RUN rm -rf /var/lib/apt/lists/*
EOF
}

function genNodejsSDKDockerfile(){
    cat >Dockerfilenodejssdk <<EOF 
FROM ubuntu:16.04
COPY ./FISCO-BCOS /FISCO-BCOS
RUN apt-get update && apt-get install -y curl xz-utils
RUN curl -sL https://nodejs.org/dist/v8.12.0/node-v8.12.0-linux-x64.tar.xz | tar -xJC /usr/local/
RUN mv /usr/local/node-v8.12.0-linux-x64 /usr/local/node
USER root
ENV PATH /usr/local/node/bin:$PATH
RUN apt-get -y install git openssl libssl-dev libkrb5-dev cmake
RUN apt-get -y install --fix-missing make g++
RUN apt-get -y install python
RUN npm install -g secp256k1 --unsafe-perm
RUN npm install -g cnpm --registry=https://registry.npm.taobao.org
RUN cnpm install -g babel-cli babel-preset-es2017 ethereum-console
RUN apt-get install dos2unix
RUN cd /FISCO-BCOS/web3lib && cnpm install && chmod +x guomi.sh && dos2unix guomi.sh && ./guomi.sh
RUN cd /FISCO-BCOS/tool && cnpm install && chmod +x guomi.sh && dos2unix guomi.sh && ./guomi.sh
RUN cd /FISCO-BCOS/systemcontract && cnpm install && chmod +x guomi.sh && dos2unix guomi.sh && ./guomi.sh
RUN apt-get -y install vim
RUN apt-get -y install inetutils-ping
RUN cp /FISCO-BCOS/fisco-solc-guomi-ubuntu /usr/local/bin/fisco-solc-guomi && chmod +x /usr/local/bin/fisco-solc-guomi
EOF
}

#echo '/tmp/fisco_bcos.%t.%e.%p' | tee /proc/sys/kernel/core_pattern
#wget https://github.com/FISCO-BCOS/FISCO-BCOS/archive/master.zip
#unzip FISCO-BCOS-master.zip
#wget https://github.com/FISCO-BCOS/fisco-solc/raw/master/fisco-solc-ubuntu
#mv fisco-solc-ubuntu  fisco-solc
#chmod +x  fisco-solc    
#docker build . -t fiscobcosdev