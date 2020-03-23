[![Build Status](https://travis-ci.org/nginxinc/kubernetes-ingress.svg?branch=master)](https://travis-ci.org/nginxinc/kubernetes-ingress)  [![FOSSA Status](https://app.fossa.io/api/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress.svg?type=shield)](https://app.fossa.io/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress?ref=badge_shield)  [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)  [![Go Report Card](https://goreportcard.com/badge/github.com/nginxinc/kubernetes-ingress)](https://goreportcard.com/report/github.com/nginxinc/kubernetes-ingress)

# Ep07. Kubernetes Pods Replicasets & Deployments

## Ready
|Preinstall|Version|
|----|----|
|Vagrant|1.0|
|VirtualBox|6.0|

## Assumptions
|Role|FQDN|IP|OS|RAM|CPU|
|----|----|----|----|----|----|
|Master|kmaster.example.com|172.42.42.100|CentOS 7|2G|2|
|Worker1|kworker1.example.com|172.42.42.101|CentOS 7|1G|1|
|Worker2|kworker2.example.com|172.42.42.102|CentOS 7|1G|1|

## Get Git information
```
$ mkdir play && cd $_
$ git clone https://github.com/grtlinux/hello_kubernetes.git
$ cd hello_kubernetes/Season01/Ep07/run0
```

## Useful tools
- git
- docker
- vagrant
- virtualbox
- tree
- etc

## Make Vagrantfile and create machines
```
$ cat Vagrantfile
    # -*- mode: ruby -*-
    # vi: set ft=ruby :

    ENV['VAGRANT_NO_PARALLEL'] = 'yes'

    Vagrant.configure(2) do |config|

    # Kubernetes Master Server
    config.vm.define "kmaster" do |kmaster|
        kmaster.vm.box = "centos/7"
        kmaster.vm.hostname = "kmaster.example.com"
        kmaster.vm.network "private_network", ip: "172.42.42.100"
        kmaster.vm.provider "virtualbox" do |v|
        v.name = "kmaster"
        v.memory = 2048
        v.cpus = 2
        # Prevent VirtualBox from interfering with host audio stack
        v.customize ["modifyvm", :id, "--audio", "none"]
        end
    end

    NodeCount = 2
    # Kubernetes Worker Nodes
    (1..NodeCount).each do |i|
        config.vm.define "kworker#{i}" do |workernode|
        workernode.vm.box = "centos/7"
        workernode.vm.hostname = "kworker#{i}.example.com"
        workernode.vm.network "private_network", ip: "172.42.42.10#{i}"
        workernode.vm.provider "virtualbox" do |v|
            v.name = "kworker#{i}"
            v.memory = 1024
            v.cpus = 1
            # Prevent VirtualBox from interfering with host audio stack
            v.customize ["modifyvm", :id, "--audio", "none"]
        end
        end
    end

    end
```
```
$ vagrant up
    < wait 1 or 2 minutes >
```

## Kubernetes Dashboard
```
$ kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
$ kubectl create -f sa_cluster_admin.yaml
$ kubectl get sa -n kube-system
$ kubectl describe sa dashboard-admin -n kube-system
    .....
    Mountable secrets: dashboard-admin-token-vjz7n
    .....
$ kubectl describe secret dashboard-admin-token-vjz7n -n kube-system
    .....
    token: XXXXXXXXX-COPY-XXXXXXXXXXXX
    .....
$ kubectl proxy
    Starting to serve on 127.0.0.1:8001
{
    tunnel: ssh -p 22222 -L 8001:localhost:8001 kiea@grtlinux11.iptime.org
    browser url:
        http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
        token: XXXXXXXXX-COPY-XXXXXXXXXXXX
}
```


## Pod
```
$ watch kubectl get all -o wide
$ cat 1-nginx-pod.yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx
    spec:
      containers:
      - image: nginx
        name: nginx
$ kubectl apply -f 1-nginx-pod.yaml
$ kubectl get event
$ kubectl describe pod nginx
$ kubectl describe pod nginx -o yaml > /tmp/imsi-pod.yaml
$ vi /tmp/imsi-pod.yaml
$ kubectl apply -f /tmp/imsi-pod.yaml
$ kubectl delete -f /tmp/imsi-pod.yaml
$ kubectl delete pod nginx
$ kubectl delete -f 1-nginx-pod.yaml
```

## ReplicaSet
```
$ watch kubectl get all -o wide
$ cat 1-nginx-replicaset.yaml
    apiVersion: apps/v1
    kind: ReplicaSet
    metadata:
      labels:
        run: nginx
      name: nginx-replicaset
    spec:
      replicas: 2
      selector:
        matchLabels:
          run: nginx
      template:
        metadata:
          labels:
            run: nginx
        spec:
          containers:
          - image: nginx
            name: nginx
$ kubectl apply -f 1-nginx-replicaset.yaml
$ kubectl get event
$ kubectl describe pod nginx-XXXXX | grep -i controlled
$ kubectl describe replicaset nginx-replicaset
$ kubectl describe replicaset nginx-replicaset -o yaml > /tmp/imsi-replicaset.yaml
$ vi /tmp/imsi-replicaset.yaml
$ kubectl apply -f /tmp/imsi-replicaset.yaml
$ kubectl delete -f /tmp/imsi-replicaset.yaml
$ kubectl delete replicaset nginx-replicaset
$ kubectl delete -f 1-nginx-replicaset.yaml
```

## Deployment
```
$ watch kubectl get all -o wide
$ cat 1-nginx-deployment.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      labels:
        run: nginx
      name: nginx-deploy
    spec:
      replicas: 2
      selector:
        matchLabels:
          run: nginx
      template:
        metadata:
          labels:
            run: nginx
        spec:
          containers:
          - image: nginx
            name: nginx
$ kubectl apply -f 1-nginx-deployment.yaml
$ kubectl get event
$ kubectl describe pod nginx-XXXXX-XXXX | grep -i controlled
$ kubectl describe replicaset nginx-XXXXX | grep -i controlled
$ kubectl describe deployment nginx-deploy
$ kubectl describe deployment nginx-deploy -o yaml > /tmp/imsi-deployment.yaml
$ vi /tmp/imsi-deployment.yaml
$ kubectl apply -f /tmp/imsi-deployment.yaml
$ kubectl delete -f /tmp/imsi-deployment.yaml
$ kubectl delete deployment nginx-deploy
$ kubectl delete -f 1-nginx-deployment.yaml
```

## Test Pod kube-proxy-XXXX in Namespace kube-system
```
$ kubectl -n kube-system describe pod kube-proxy-XXXXX -o yaml > /tmp/imsi-proxy.yaml
$ vi /tmp/imsi-proxy.yaml
$ kubectl apply -f /tmp/imsi-proxy.yaml
$ kubectl get all --all-namespaces -o wide
$ kubectl delete -f /tmp/imsi-proxy.yaml
```

---
## command
```
$ watch kubectl get all -o wide

$ kubectl run myshell -it --image busybox -- sh
$ kubectl delete deploy myshell
$ kubectl run myshell --rm -it --image busybox -- sh

$ kubectl run mynginx --image nginx
$ kubectl delete deploy mynginx
$ kubectl run mynginx --image nginx
$ kubectl port-forward mynginx-dbddb74b8-xxxx 8888:80
{
    tunnel: ssh -p 22222 -L 8888:localhost:8888 kiea@grtlinux11.iptime.org
    browser url: http://localhost:8888/
}
$ kubectl logs mynginx-dbddb74b8-xxxx
$ kubectl delete pod mynginx-dbddb74b8-xxxx
$ kubectl delete deploy mynginx

$ kubectl run mynginx --image nginx --replicas 2
$ kubectl scale deploy mynginx --replicas 5

$ kubectl expose deploy mynginx --type NodePort --port 80
$ kubectl describe svc mynginx

$ kubectl get deploy mynginx -o yaml > /tmp/deployment-mynginx.yaml
$ kubectl get svc mynginx -o yaml > /tmp/service-mynginx.yaml
$ vi /tmp/deployment-mynginx.yaml
$ vi /tmp/service-mynginx.yaml
$ kubectl delete deploy mynginx
$ kubectl delete svc mynginx
$ kubectl create -f /tmp/deployment-mynginx.yaml
$ kubectl create -f /tmp/service-mynginx.yaml
$ kubectl delete -f /tmp/deployment-mynginx.yaml
$ kubectl delete -f /tmp/service-mynginx.yaml
$
$
$
$
$
$
$

```













---
## Poweroff and Delete the virtual machines
```
$ vboxmanage list vms
$ vboxmanage list runningvms
$ vagrant halt
$ vboxmanage list runningvms
$ vagrant destroy -f
$ vboxmanage list vms
$ vagrant status
```

## Remove vagrant box
```
$ vagrant box remove --all centos/7
$ vagrant box list
$ tree ~/.vagrant.d
$ cd ../../../..
$ rm -rf hello_kubernetes
```

#### Delete VM on VirtualBox
```
$ vboxmanage --version
$ vboxmanage list vms
$ vboxmanage list runningvms
$ vboxmanage controlvm <VM> poweroff
$ vboxmanage unregistervm <VM> --delete
```

---

Have Fun!!
