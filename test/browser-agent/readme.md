# report agent 文档

`ReportAgent.py`中已经配置的监控的`HOST_IP`为`gethostname()`的执行结果。服务端的IP为`browser.bcos.bqj.cn`,端口为8888。
bcos节点日志已经配置为`"/bcos-data/node/log"`,日志配置文件为`"/bcos-data/node/log.conf"`,rpc服务端口为`8545`
使用前请确保`browser.bcos.bqj.cn`能正常解析,并且浏览器服务端已经正常运行。

## 使用

```shell
ContainerID=xxxx # 找出容器的id
docker cp ReportAgent.py $ContainerID:/root/browser-agent/
docker cp start_Agent.sh $ContainerID:/root/browser-agent/
docker cp stop_Agent.sh $ContainerID:/root/browser-agent/
docker exec -it $ContainerID bash
```

进入容器后执行

```shell
apt-get update
apt-get install -y python-pip
mkdir -p /root/.pip/
cp pip.conf /root/.pip/
cd /root/browser-agent
pip install -r requirements.txt
bash ./start_Agent.sh
```
