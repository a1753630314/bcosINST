# 说明文档

## 制作镜像

默认情况下我们使用官方的镜像，如果需要自行制作镜像可以参考下面的步骤制作

```shell
cd test/image
./setup.sh
```

## 部署系统合约

在当前目录下执行

```shell
ROOTDIR=$PWD
node accountManager.js > godInfo.txt
ADDRESS=$(cat ./bcos/tool/godInfo.txt |grep address|awk '{print $NF}')
source setup.sh
setup
cd test/integration
source build.sh
genRootCA # 如果需要重新生成证书请执行此函数
AddNode 0 $ADDRESS #给创世节点生成配置
AddNode 1 $ADDRESS #给第二个节点生成配置
AddNode 2 $ADDRESS #给第三个节点生成配置
docker-compose -f peer0.bcos.bqj.cn.yaml up -d
sleep 30 # 执行tail -f data/nodo-0/log/info*|grep seal 查看是否有挖矿日志出现
cd $ROOTDIR
deploySystemContract  #部署系统智能合约
```

部署系统智能合约最后执行成功的话会出现类似下面的日志

```s
SystemProxy address :0x919868496524eedc26dbb81915fa1547a20f8998
-----------------SystemProxy route ----------------------
0 )TransactionFilterChain=>0x05a7fb241c702ac8a69695abae89be860ecd6182,false,22
1 )ConfigAction=>0xa40c864c28ee8b07dc2eeab4711e3161fc87e1e2,false,23
2 )NodeAction=>0x61dba250334e0fd5804c71e7cbe79eabecef8abe,false,24
3 )CAAction=>0xbad1ba7704fa69f5afebd350a57ce231acf5f122,false,25
4 )ContractAbiMgr=>0x9216757a91607668cf8a7a38f8ae56206a6e9f6b,false,26
5 )ConsensusControlMgr=>0x1406a0c559995562fc77bf2a214a2dcfab4f6b2b,false,27
6 )FileInfoManager=>0xfcd14ed03e6d94ca127d557a1883dd042a81ea11,false,28
7 )FileServerManager=>0x73479ed8162e198b9627b962eb4aae7098bdc770,false,29
==end of deploy systemContract==
```

修改`data/node-*/config.json`中的`systemproxyaddress`的值为上面的`SystemProxy address`的值。重启容器。
重启之后将进入`$ROOTDIR/bcos/systemcontractv2`目录，在此目录下执行下面的命令:

```shell
babel-node tool.js NodeAction registerNode node0.json #注册节点
babel-node tool.js NodeAction all #查看当前注册的节点列表
babel-node monitor.js #查看连接到本节点的节点列表
```

由于`node0.json`是创世节点的配置，所以在执行时需要启动创世节点，如果是其他节点，注册时不能启动，需要等注册成功方可启动

另外，其他节点的配置文件`config.json`中`NodeextraInfo`的值需要包含创世节点的配置。值类似下面：

```json
[{
                "Nodeid":"bed753c8bdb385b975d21e8e81bb56768732e9c846cb3b26de5df91bda9f99c9095575fc42f903f9fc3bc7653c5715abadc9724ef79af74aa9ef892870344b82",
                "Nodedesc": "node0",
                "Agencyinfo": "agency0",
                "Peerip": "peer0.bcos.bqj.cn",
                "Identitytype": 1,
                "Port":30303,
                "Idx":0
                }，
{
                "Nodeid":"5668f42297055b563f7d32a0fd409056322fad0470d00ccc485ffccdb4a7a64f8d6f6710777062e01e166b8d04772e179579331f04f06642807dcb9bd4f8c902",
                "Nodedesc": "node1",
                "Agencyinfo": "agency1",
                "Peerip": "peer1.bcos.bqj.cn",
                "Identitytype": 1,
                "Port":30303,
                "Idx":1
                }]
```

## 配置节点证书

节点的证书存放目录在节点文件目录的data文件夹下。包括：

ca.crt：根证书公钥，整条区块链共用。
ca.key：根证书私钥，私钥应保密，仅在生成节点证书公私钥时使用。
server.crt：节点证书的公钥。
server.key：节点证书的私钥，私钥应保密。
证书文件应严格按照上述命名方法命名。

FISCO BCOS通过授权某节点对应的公钥server.crt，控制此节点是否能够与其它节点正常通信。

### 开启所有节点的SSL验证功能

在进行节点证书授权管理前，需开启区块链上每个节点的SSL验证功能。
此处以创世节点为例，其它节点也应采用相同的操作。

cd ./data/nod-0/
vim config.json
将ssl字段置为1，效果如下。

"ssl":"1",
修改完成后重启容器.
其它节点也采用相同的操作，开启SSL验证功能。
注意：必须所有的节点都开启ssl功能，才能继续下一步骤。

配置机构证书信息
将节点的证书写入系统合约，为接下来的证书准入做准备。每张证书都应该写入系统合约中。节点的证书若不写入系统合约，相应的节点将不允许通信。

```shell
cd $ROOTDIR/bcos/systemcontractv2
babel-node tool.js CAAction update ca-0.json
```

### 设置证书验证开关

证书验证开关能够控制是否采用证书准入机制。开启后，将根据系统合约里的证书状态（status）控制节点间是否能够通信。不在系统合约中的证书对应的节点，将不允许通信。

在打开此开关前，请确认：

（1）所有的节点都正确的配置了相应机构的证书（即server.key、server.crt）。

（2）所有节点的SSL验证已经打开。（标志位已经设置，设置后节点已经重启）。

（3）所有机构的证书信息都已经配置入系统合约。

上述条件未达到，会出现节点无法连接，节点无法共识，合约操作无法进行的情况。若出现上述情况，请先关闭所有节点的SSL验证功能，做了正确的配置后，再打开SSL功能。

**开启全局开关**
执行命令，CAVerify设置为true

```shell
babel-node tool.js ConfigAction set CAVerify true
babel-node tool.js ConfigAction get CAVerify
```

输出true，表示开关已打开

```shell
CAVerify=true,29
```

**关闭全局开关**
开关关闭后，节点间的通信不再验证证书。执行命令，CAVerify设置为false

```shell
babel-node tool.js ConfigAction set CAVerify false
```

**更新证书准入状态**
配置status，0表示不可用，1表示可用。其它字段默认即可。如下，让node2的证书不可用。即status置0。

```json
{
        "hash" : "8A4B2CDE94348D22",
        "status" : 0,
        "pubkey":"",
        "orgname":"",
        "notbefore":20170223,
        "notafter":20180223,
        "whitelist":"",
        "blacklist":""
}
```

```shell
babel-node tool.js CAAction updateStatus ca-0.json
babel-node tool.js CAAction all
```

得到结果

```shell
{ HttpProvider: 'http://127.0.0.1:8545',
  Ouputpath: './output/',
  privKey: 'bcec428d5205abe0f0cc8a734083908d9eb8563e31f943d760786edf42ad67dd',
  account: '0x64fa644d2a694681bd6addd6c5e36cccd8dcdde3' }
Soc File :CAAction
Func :all
SystemProxy address 0x919868496524eedc26dbb81915fa1547a20f8998
CAAction address 0xbad1ba7704fa69f5afebd350a57ce231acf5f122
HashsLength= 3
----------CA 0---------
hash=FD1AFC8235897ECB
pubkey=
orgname=
notbefore=20170223
notafter=20180223
status=1
blocknumber=33
whitelist=
blacklist=
----------CA 1---------
hash=FD1AFC8235897ECC
pubkey=
orgname=
notbefore=20170223
notafter=20180223
status=1
blocknumber=34
whitelist=
blacklist=
----------CA 2---------
hash=FD1AFC8235897ECD
pubkey=
orgname=
notbefore=20170223
notafter=20180223
status=1
blocknumber=35
whitelist=
blacklist=
```