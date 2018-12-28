# bcos-browser浏览器搭建

## 构建数据库服务镜像

在当前目录下执行:

```shell
docker build . -t bcosdb
docker run --name bdb -p 3306:3306 -d bcosdb
```

## 启动浏览器服务

当前目录下执行下面的代码:

```shell
docker network create bcos-ov
docker-compose -f docker-compose.yaml up -d
```

进入容器执行下面的代码

```shell
cd /usr/local/tomcat/webapps
cp /root/*.war .
cd /usr/local/tomcat/webapps/fisco-bcos-browser/WEB-INF/classes && sed -i '/test\ /test/g' jdbc.properties
```

然后重启该容器，执行完毕后用浏览器访问 `http://192.168.50.118:888/fisco-bcos-browser/home/home.page` 即可

另外，还需要运行了bcos节点的机器部署agent

## bcos节点部署客户端

执行下面的