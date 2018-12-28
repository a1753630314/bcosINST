# 国密版bcos网络搭建指南
 阅读本文档之前请先阅读下面文档
 1. [FISCO BCOS区块链操作手册](https://github.com/FISCO-BCOS/FISCO-BCOS/tree/master/doc/manual)
 2. [国密操作文档](https://github.com/FISCO-BCOS/FISCO-BCOS/blob/master/doc/%E5%9B%BD%E5%AF%86%E6%93%8D%E4%BD%9C%E6%96%87%E6%A1%A3.md)
 
## 搭建步骤
1. 制作国密版docker镜像文件

```shell
mkdir 0704
cp setup.sh 0704
cd 0704
source setup.sh
buildBcos #如果要根据开发分支的代码构建，需要手动执行这个函数里面的步骤
```

2. 生成证书

首先进入容器

```shell
docker run -d  --name fc13tool fiscobcoswithtool init
docker cp run.sh fc13tool:/FISCO-BCOS/cert/GM
docker exec -it fc13tool bash
```

进入容器后执行下面的命令

```shell
cd /FISCO-BCOS/cert/GM
source run.sh
genChainInit
addAgency blockchain.bqj.cn
addAgency blockchain.cbca.net
addAgency blockchain.wmxmedia.com
addAgency blockchain.ntsc.ac.cn
addAgency blockchain.itrus.com.cn
addAgency blockchain.bxsfjdzx.gov.cn
fisco-bcos --newaccount > god.txt
GOD_ADDRESS=`cat god.txt|grep address|awk -F':' '{print $NF}'`
genGenesisNode blockchain.bqj.cn peer0  $GOD_ADDRESS
GENESISNODE=xxxx
genNodeConfig blockchain.bqj.cn peer1 $GOD_ADDRESS $GENESISNODE
genNodeConfig blockchain.cbca.net peer0 $GOD_ADDRESS  $GENESISNODE
genNodeConfig blockchain.cbca.net peer1 $GOD_ADDRESS  $GENESISNODE
genNodeConfig blockchain.wmxmedia.com peer0 $GOD_ADDRESS  $GENESISNODE
genNodeConfig blockchain.wmxmedia.com peer1 $GOD_ADDRESS  $GENESISNODE
genNodeConfig blockchain.ntsc.ac.cn peer0 $GOD_ADDRESS  $GENESISNODE
genNodeConfig blockchain.ntsc.ac.cn peer1 $GOD_ADDRESS  $GENESISNODE
genNodeConfig blockchain.itrus.com.cn peer0 $GOD_ADDRESS  $GENESISNODE
genNodeConfig blockchain.itrus.com.cn peer1 $GOD_ADDRESS  $GENESISNODE
genNodeConfig blockchain.bxsfjdzx.gov.cn peer0 $GOD_ADDRESS  $GENESISNODE
genNodeConfig blockchain.bxsfjdzx.gov.cn peer1 $GOD_ADDRESS  $GENESISNODE
genSdk blockchain.bqj.cn sdk1
genSdk blockchain.cbca.net sdk1
genSdk blockchain.wmxmedia.com sdk1
genSdk blockchain.ntsc.ac.cn sdk1
genSdk blockchain.itrus.com.cn sdk1
genSdk blockchain.bxsfjdzx.gov.cn sdk1
genNodePeerYaml blockchain.bqj.cn peer0
genNodePeerYaml blockchain.bqj.cn peer1
genNodePeerYaml blockchain.cbca.net peer0
genNodePeerYaml blockchain.cbca.net peer1
genNodePeerYaml blockchain.wmxmedia.com peer0
genNodePeerYaml blockchain.wmxmedia.com peer1
genNodePeerYaml blockchain.ntsc.ac.cn peer0
genNodePeerYaml blockchain.ntsc.ac.cn peer1
genNodePeerYaml blockchain.itrus.com.cn peer0
genNodePeerYaml blockchain.itrus.com.cn peer1
genNodePeerYaml blockchain.bxsfjdzx.gov.cn peer0
genNodePeerYaml blockchain.bxsfjdzx.gov.cn peer1

genWeb3SdkYaml
```

3. 修改配置文件

退出容器，然后执行下面的命令

```shell
docker cp fc13tool:/FISCO-BCOS/cert/GM .
```

对于创世节点的bootstrapnodes.json，它的配置如下:

```json
{
    "nodes":[
        {"host":"127.0.0.1","p2pport":"30303"}
    ]
}
```

编辑好后将这个文件放到`./${ORG}/${NODE}/data`目录下，对于非创世节点，需要将`127.0.0.1` 替换成创世节点的ip。

4. 启动环境

```shell
docker-compose -f peer0.blockchain.bqj.cn.yaml up -d #在GM目录下，如果要在一台机器上搭建集群，需要保证所有节点的docker-compose文件暴露的端口没有冲突；如果是多个节点，需要每个都有暴露相应端口
```


## web3sdk使用

使用sdk目录下的Dockerfile生成镜像，然后用上面生成的 web3sdk.yaml 文件启动容器

## javasdk 使用
用下面的命令生成国密账号，把国密账号填入`conf/applicationContext.xml`中

```shell
java -cp 'conf/:apps/*:lib/*' org.bcos.contract.tools.GenGmAccount genkey key.info #生成国密账号
-------------------------------------------------------------------------------
==========Generate (private key, public key, account) For Guomi randomly =======
=====INIT GUOMI KEYPAIR ====
===public:0ef2a3aef6f51574c62330ba99cf89b005e966f54b016cd62510e51c5d9765af9d928f166bc5c5bb9115c496d6dda8dbd4bac2d025f9b1229d1e0305b4bf8aeb
===private:b888fcc5cf685230ebdd2705493bebec5826d3bc8a2b4d332d34ef7b06135c6b
===GEN COUNT :[B@1c3a4799
DeduceAccountFromPublic failed, error message:exception decoding Hex string: String index out of range: 127
==== generate private/public key with GuoMi algorithm failed ====
cat key.info
{"privateKey":"d8d4e29b18252d7415ab0dfcf3fa1f0abc11bac1de254bf1d91c4a8866e1282a","publicKey":"6de57330ec3d4360834af935fef512bc4b785b66772c02afe2148b68da9c7d900b3ddd773f28595481f83cd69ec9de6ebb287762727cb5db9f08a031d89af1c9","account":"0xc874bcb663c2fbbe9aa66f12d10953e60d9d3cd9"}
#修改配置文件conf/applicationContext.xml 配置该账号，配置其中需要连接节点的ip
```

修改`applicationContext.xml`中连接的ip为创世节点的ip,然后执行下面的命令

```shell
cd /web3sdk/dist
java -cp 'conf/:apps/*:lib/*' org.bcos.contract.tools.InitSystemContract > systemcontractinfo.txt #部署系统智能合约
SystemAddress=`cat systemcontractinfo.txt|grep systemProxy|awk '{print $NF}'`
sed -i "/systemProxyAddress/s/value=\".*.\"/value=\"${SystemAddress}\"/" conf/applicationContext.xml
```

确保配置文件`conf/applicationContext.xml`中加密配置配置如下

```xml
<bean id="encryptType" class="org.bcos.web3j.crypto.EncryptType">
		<constructor-arg value="1"/>
</bean>
```

将`SystemAddress`的值写入所有节点的配置文件中，重启创世节点，

**注册创世节点**
在容器外执行下面的命令把peer0.blockchain.bqj.cn的配置文件拷贝到web3sdk容器的`/web3sdk/dist/conf/`目录下

```shell
docker cp blockchain.bqj.cn/peer0/data/gmnode.json f72fb174a4d9:/web3sdk/dist/conf/peer0bqj.json
```

然后在web3sdk容器执行下面的命令注册节点:

```shell
cd /web3sdk/dist
java -cp 'conf/:apps/*:lib/*' org.bcos.contract.tools.SystemContractTools NodeAction registerNode peer0bqj.json #注册节点
java -cp 'conf/:apps/*:lib/*' org.bcos.contract.tools.SystemContractTools NodeAction all #查看已注册的节点
```

### 注册其他节点

注册其他节点时需要保证现有已注册的节点和被注册的节点全部处于启动状态，注册流程与注册创世节点流程一致

### 部署智能合约

1. 将智能合约拷贝到容器的`/web3sdk/dist/contracts`目录下,将智能合约代码库中的`tool/SolBuild.java`拷贝到`/web3sdk/src/main/java/org/bcos/contract/tools/`目录下,备份`/web3sdk/dist/conf/`目录下的ca.crt,client.keystore,applicaitonContext.xml文件；
2. 执行`cd /web3sdk/dist/bin && bash compile.sh org.bcos.contract.tools 1 /usr/bin/fisco-solc-guomi`,执行完毕后拷贝`../output/org/bcos/contract/tools`目录下的java代码到`/web3sdk/src/main/java/org/bcos/contract/tools`下；
3. 修改`/web3sdk/src/main/java/org/bcos/contract/tools/SolBuild.java`中的`FinanceCore`为待部署合约的名字，然后在`/web3sdk`目录下执行`gradle build`命令，执行通过后执行下一步;
3. 还原步骤1中的备份，并在`/web3sdk/dist`目录下执行`java -cp 'conf/:apps/*:lib/*' org.bcos.contract.tools.SolBuild`即可完成合约的部署，当有多个合约时，重复第3，4步即可;

### 设置合约名称

```shell
java -cp 'conf/:apps/*:lib/*' org.bcos.contract.tools.SystemContractTools CNSAction add credit /web3sdk/dist/conf/credit.abi /web3sdk/dist/lib/output/Credit.address
===================================================================
=====INIT GUOMI KEYPAIR from Private Key
====generate kepair from priv key:19d74b6a2c10d1244e3eb62b455aaaf6145ac7a0b8905be648d171995d15028a
generate keypair data succeed
cns add operation success.
```

使用例子

```shell
root@web3sdk:/web3sdk/dist# java -cp 'conf/:apps/*:lib/*' org.bcos.contract.tools.SystemContractTools CNSAction add credit /web3sdk/dist/conf/credit.abi /web3sdk/dist/lib/output/Credit.address
===================================================================
=====INIT GUOMI KEYPAIR from Private Key
====generate kepair from priv key:19d74b6a2c10d1244e3eb62b455aaaf6145ac7a0b8905be648d171995d15028a
generate keypair data succeed
cns add operation success.
root@web3sdk:/web3sdk/dist# java -cp 'conf/:apps/*:lib/*' org.bcos.contract.tools.SystemContractTools CNSAction
===================================================================
=====INIT GUOMI KEYPAIR from Private Key
====generate kepair from priv key:19d74b6a2c10d1244e3eb62b455aaaf6145ac7a0b8905be648d171995d15028a
generate keypair data succeed
cns invalid args length.
 CnsAction Usage:
	 CNSAction get    contract version
	 CNSAction add    contract contract.abi contract.address
	 CNSAction update contract contract.abi contract.address
	 CNSAction list [simple]
	 CNSAction historylist contract [version] [simple]
	 CNSAction reset contract [version] index
root@web3sdk:/web3sdk/dist# java -cp 'conf/:apps/*:lib/*' org.bcos.contract.tools.SystemContractTools CNSAction get credit
===================================================================
=====INIT GUOMI KEYPAIR from Private Key
====generate kepair from priv key:19d74b6a2c10d1244e3eb62b455aaaf6145ac7a0b8905be648d171995d15028a
generate keypair data succeed
 ====> contract => credit ,version =>  not exist.
root@web3sdk:/web3sdk/dist#java -cp 'conf/:apps/*:lib/*' org.bcos.contract.tools.SystemContractTools CNSAction list|grep -v  abi
====> cns list index = 8 <====
	 contract    = credit
	 version     = 1.2
	 address     = 0x03e770a462e9d40844fba3bcd03a51e2f4b5b246
	 blocknumber = 28
	 timestamp   = 1530866199023
root@web3sdk:/web3sdk/dist# java -cp 'conf/:apps/*:lib/*' org.bcos.contract.tools.SystemContractTools CNSAction historylist credit
===================================================================
=====INIT GUOMI KEYPAIR from Private Key
====generate kepair from priv key:19d74b6a2c10d1244e3eb62b455aaaf6145ac7a0b8905be648d171995d15028a
generate keypair data succeed
 cns history total count => 0
cns historylist operation success.
root@web3sdk:/web3sdk/dist# java -cp 'conf/:apps/*:lib/*' org.bcos.contract.tools.SystemContractTools CNSAction add copyright /web3sdk/dist/conf/copyright.abi /web3sdk/dist/lib/output/Copyright.address
===================================================================
=====INIT GUOMI KEYPAIR from Private Key
====generate kepair from priv key:19d74b6a2c10d1244e3eb62b455aaaf6145ac7a0b8905be648d171995d15028a
generate keypair data succeed
cns add operation success.
```

下面的命令可以列出当前已经命名的智能合约

```shell
java -cp 'conf/:apps/*:lib/*' org.bcos.contract.tools.SystemContractTools CNSAction list|grep -v abi
====> cns list index = 8 <====
	 contract    = credit
	 version     = 1.2
	 address     = 0xddebda63cc7acd255bf08beb83f1383ffe2964dc
	 blocknumber = 27
	 timestamp   = 1531116309148
 ====> cns list index = 9 <====
	 contract    = copyright
	 version     = 1.2
	 address     = 0xe82dbf546b192816823349067305bccf978209ee
	 blocknumber = 28
	 timestamp   = 1531116360428
```

## 机构证书准入
基本流程参照官方文档，其中有几个需要注意的问题，是官方文档中的错误
1. 1.3.4 版本不需要打开 config.json 中的 "ssl"="1" 的开关，在1.3.4以前的版本，国密版本打开开关应该是 "ssl"="2"
2. babel-node tool.js CAAction update ca.json  这个命令中是错误的。
   正确的命令格式为：babel-node tool.js CAAction all|add|remove
3. 上面 ca.json 格式不是官方文档中的格式，应该是

```` json 
   {
        "serial" : "9D63F22C0CD9B591",
        "pubkey":"",
        "name":"peer0.blockchain.itrus.com.cn"
   }
````