### 逻辑梳理

ks-installer启动后,将会先引导ks-apiserver,再引导ks-controller-manager,最后引导ks-console

### 小试牛刀

直接上手改，让它报错，顺着报错日志学

##### 构建自己的shell-operator

1.shell-operator需要提前在本地如下编译

```
git clone --branch v1.0.0-beta.5 https://github.com/flant/shell-operator.git
```

```
cd shell-operator
```

```
export CGO_ENABLED=0
cd /go/src/github.com/flant/shell-operator
go build -ldflags="-s -w -X 'github.com/flant/shell-operator/pkg/app.Version=1.0.0'" -o shell-operator ./cmd/shell-operator
```

2.打包d3osdev/shell-operator:v1.0.0-beta.5-alpine3.13, Dockerfile如下；

```
FROM python:3.9.6-alpine3.13

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories

COPY helm-v3.6.2-linux-amd64.tar.gz helm-v3.6.2-linux-amd64.tar.gz

COPY shell-operator /shell-operator

RUN apk --no-cache add jq gcc bash libffi-dev openssl-dev curl unzip musl-dev openssl && \
    export CRYPTOGRAPHY_DONT_BUILD_RUST=1 && \
    pip install --no-cache-dir ansible_runner==2.0.1 ansible==2.9.23 kubernetes -i https://pypi.tuna.tsinghua.edu.cn/simple && \
    tar -zxf helm-v3.6.2-linux-amd64.tar.gz && \
    mv linux-amd64/helm /bin/helm && \
    rm -rf *linux-amd64* && \
    chmod +x /bin/helm && \
    wget https://storage.googleapis.com/kubernetes-release/release/v1.18.18/bin/linux/amd64/kubectl -O /bin/kubectl && \
    chmod +x /bin/kubectl && \
    ln -s /bin/kubectl /usr/local/bin/kubectl && \
    ln -s /bin/helm /usr/local/bin/helm && \
    mkdir -p /hooks/d3os /d3os/installer/roles /d3os/results/env /d3os/playbooks /d3os/config &&\
    adduser -D -g d3os -u 1002 d3os

RUN chown -R d3os:d3os /shell-operator && \
    chown -R d3os:d3os /hooks && \
    chown -R d3os:d3os /d3os

RUN chmod +x -R /hooks/d3os

ENV SHELL_OPERATOR_WORKING_DIR /hooks
ENV ANSIBLE_ROLES_PATH /d3os/installer/roles

ENTRYPOINT ["/shell-operator"]

CMD ["start"]
```

3.构建并推送

```
docker build -t registry-edge.cosmoplat.com/d3osdev/shell-operator:v1.0.0-beta.5-alpine3.13  .
```

```
docker push registry-edge.cosmoplat.com/d3osdev/shell-operator:v1.0.0-beta.5-alpine3.13
```

##### 构建自己的ks-installer

```
git clone --branch d3os-3.1 https://github.com/Dravening/ks-installer.git
```

```
cd ks-installer
```

```
docker build -t registry-edge.cosmoplat.com/d3os/ks-installer:v3.1.1.3  .
```

```
docker push registry-edge.cosmoplat.com/d3os/ks-installer:v3.1.1.3
```

### 注意事项

ks-installer 会注册webhook-secret(roles/ks-core/prepare/files/ks-init/...)到集群中, 影响ks-controller-manager的运行。要手动生成证书文件

1.创建 CA 证书机构

```
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "server": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "87600h"
      }
    }
  }
}
EOF
```

```
cat > ca-csr.json <<EOF
{
    "CN": "kubernetes",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "BeiJing",
            "ST": "BeiJing",
            "O": "k8s",
            "OU": "System"
        }
    ]
}
EOF
```

生成 CA 证书和私钥

```
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
2021/01/23 16:59:51 [INFO] generating a new CA key and certificate from CSR
2021/01/23 16:59:51 [INFO] generate received request
2021/01/23 16:59:51 [INFO] received CSR
2021/01/23 16:59:51 [INFO] generating key: rsa-2048
2021/01/23 16:59:51 [INFO] encoded CSR
2021/01/23 16:59:51 [INFO] signed certificate with serial number 502715407096434913295607470541422244575186494509
```

```
[root@k8s-master ssl]# ls
ca-config.json  ca.csr  ca-csr.json  ca-key.pem  ca.pem
```

创建server端证书

```
cat > server-csr.json <<EOF
{
  "CN": "admission",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
        "C": "CN",
        "L": "BeiJing",
        "ST": "BeiJing",
        "O": "k8s",
        "OU": "System"
    }
  ]
}
EOF
```

```
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json \
  -hostname=ks-controller-manager.d3os-system.svc -profile=server server-csr.json | cfssljson -bare server
2021/01/23 17:08:37 [INFO] generate received request
2021/01/23 17:08:37 [INFO] received CSR
2021/01/23 17:08:37 [INFO] generating key: rsa-2048
2021/01/23 17:08:37 [INFO] encoded CSR
2021/01/23 17:08:37 [INFO] signed certificate with serial number 701199816701013791180179639053450980282079712724
```

> 注意：这里写hostname，例如ks-controller-manager.d3os-system.svc

~~使用生成的 server 证书和私钥创建一个 Secret 对象~~

~~kubectl create secret tls admission-registry-tls --key=server-key.pem --cert=server.pem~~

