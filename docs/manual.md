### 杂项记录

容器registry-edge.cosmoplat.com/d3os/ks-installer:v3.1.1.2的环境变量

SHELL_OPERATOR_WORKING_DIR=/hooks
ANSIBLE_ROLES_PATH=/d3os/installer/roles
HOME=/home/d3osbash-5.1

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
