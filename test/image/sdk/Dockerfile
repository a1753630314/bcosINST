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
#ln -s /usr/bin/fromdos /usr/bin/dos2unix &&  ln -s /usr/bin/todos /usr/bin/unix2dos &&