[![Build Status](https://travis-ci.org/nginxinc/kubernetes-ingress.svg?branch=master)](https://travis-ci.org/nginxinc/kubernetes-ingress)  [![FOSSA Status](https://app.fossa.io/api/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress.svg?type=shield)](https://app.fossa.io/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress?ref=badge_shield)  [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)  [![Go Report Card](https://goreportcard.com/badge/github.com/nginxinc/kubernetes-ingress)](https://goreportcard.com/report/github.com/nginxinc/kubernetes-ingress)

# Ep16. Using Resource Quotas & Limits in Kubernetes Cluster

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
$ cd hello_kubernetes/Season01/Ep16/run0
```

## Make Vagrantfile and create machines
```
$ cd ubuntu18
$ cat Vagrantfile
    # -*- mode: ruby -*-
    # vi: set ft=ruby :

    ENV['VAGRANT_NO_PARALLEL'] = 'yes'

    Vagrant.configure(2) do |config|

      NodeCount = 1

      (1..NodeCount).each do |i|
        config.vm.define "ubuntuvm0#{i}" do |node|
          node.vm.box = "ubuntu/bionic64"
          node.vm.hostname = "ubuntuvm0#{i}.example.com"
          node.vm.network "private_network", ip: "172.42.42.10#{i}"
          node.vm.provider "virtualbox" do |v|
            v.name = "ubuntuvm0#{i}"
            v.memory = 4096
            v.cpus = 3
          end
        end
      end

    end
```
```
$ vagrant up
    < wait 1 or 2 minutes >
```

## microk8s
```
$ vagrant ssh
    vagrant@ubuntuvm01:~$ lsb_release -dirc
    vagrant@ubuntuvm01:~$ nproc
    vagrant@ubuntuvm01:~$ free -m
    vagrant@ubuntuvm01:~$ df -h
    vagrant@ubuntuvm01:~$ cat /etc/lsb-release
    vagrant@ubuntuvm01:~$ cat /proc/cpuinfo
    vagrant@ubuntuvm01:~$ sudo fdisk -l
    vagrant@ubuntuvm01:~$ ip a
    vagrant@ubuntuvm01:~$ netstat -lntp
    vagrant@ubuntuvm01:~$ ping google.com

    vagrant@ubuntuvm01:~$ sudo apt update && sudo apt upgrade -y
    vagrant@ubuntuvm01:~$ sudo apt install snapd
    vagrant@ubuntuvm01:~$ sudo snap install microk8s --classic --channel=1.13/stable
    vagrant@ubuntuvm01:~$ snap list
    vagrant@ubuntuvm01:~$ microk8s.kubectl cluster-info
    vagrant@ubuntuvm01:~$ microk8s.status
    vagrant@ubuntuvm01:~$ sudo usermod -a -G microk8s vagrant
    vagrant@ubuntuvm01:~$ cat >>~/.profile <<EOF
# ----- added by Kiea -----
alias kubectl='microk8s.kubectl'
alias docker='microk8s.docker'
alias status='microk8s.status'
# alias inspect='microk8s.inspect'
# alias reset='microk8s.reset'
EOF
    vagrant@ubuntuvm01:~$ logout

$ vagrant ssh
    vagrant@ubuntuvm01:~$ cat .profile
    vagrant@ubuntuvm01:~$ alias | grep microk8s
    vagrant@ubuntuvm01:~$ kubectl cluster-info
    vagrant@ubuntuvm01:~$ kubectl version --short
    vagrant@ubuntuvm01:~$ kubectl get nodes -o wide
    vagrant@ubuntuvm01:~$ kubectl get namespaces

    vagrant@ubuntuvm01:~$ dpkg -l | grep docker
    vagrant@ubuntuvm01:~$ ps -ef | grep docker
    vagrant@ubuntuvm01:~$ docker images
    vagrant@ubuntuvm01:~$ docker ps -a

$
```

## get hello_kubernetes
```
$ mkdir play && cd $_
$ git clone https://github.com/grtlinux/hello_kubernetes.git
$ cd hello_kubernetes/Season01/Ep16/run1
$ ls -l
    7-pod-quota-mem-exceed.yaml
    7-pod-quota-mem.yaml
    7-quota-count.yaml
    7-quota-limitrange.yaml
    7-quota-mem.yaml
$
```

## Force Deletion of terminating pods
```
$ kubectl get pods
    < Terminating Pods >
$ kubectl delete pods <pod> --grace-period=0 --force
```

## Create Namespace
```
$ kubectl create ns quota-demo-ns
$ kubectl get ns
$
```

## Quota Count
```
$ watch  microk8s.kubectl -n quota-demo-ns get po,deploy,replicaset,quota

$ cat 7-quota-count.yaml
    apiVersion: v1
    kind: ResourceQuota
    metadata:
      name: quota-demo1
      namespace: quota-demo-ns
    spec:
      hard:
        pods: "2"
        configmaps: "1"
$ kubectl create -f 7-quota-count.yaml
$ kubectl -n quota-demo-ns get quota quota-demo1 -o yaml
$ kubectl -n quota-demo-ns describe quota quota-demo1
$ kubectl -n quota-demo-ns create cm cm1 --from-literal=name="Kiea" --from-literal=age=50
$ kubectl -n quota-demo-ns create cm cm2 --from-literal=title="Hello World"
    < ERROR >
$ kubectl -n quota-demo-ns get cm
$ kubectl -n quota-demo-ns describe quota quota-demo1
$ kubectl -n quota-demo-ns run nginx --image=nginx --replicas=1
$ kubectl -n quota-demo-ns get deploy nginx -o yaml
$ kubectl -n quota-demo-ns scale deploy nginx --replicas=2
$ kubectl -n quota-demo-ns scale deploy nginx --replicas=3
$ kubectl -n quota-demo-ns describe deploy nginx | less
    < NO ERROR >
$ kubectl -n quota-demo-ns describe replicaset nginx-XXXXXXXXX | less
    < ERROR >
$ kubectl -n quota-demo-ns scale deploy nginx --replicas=2
$ kubectl -n quota-demo-ns scale deploy nginx --replicas=1
$ kubectl -n quota-demo-ns delete deploy nginx

$ kubectl -n quota-demo-ns describe quota quota-demo1
$
```

## Quota Memory
```
$ watch  microk8s.kubectl -n quota-demo-ns get po,deploy,replicaset,quota

$ cat 7-quota-mem.yaml
    apiVersion: v1
    kind: ResourceQuota
    metadata:
      name: quota-demo-mem
      namespace: quota-demo-ns
    spec:
      hard:
        limits.memory: "500Mi"
$ kubectl create -f 7-quota-mem.yaml
$ kubectl -n quota-demo-ns describe quota quota-demo-mem
$ cat 7-pod-quota-mem.yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx
      namespace: quota-demo-ns
    spec:
      containers:
      - image: nginx
        name: nginx
$ kubectl create -f 7-pod-quota-mem.yaml
    < ERROR >
$ vi 7-pod-quota-mem.yaml
    .....
        name: nginx
        resources:
          limits:
            memory: "100Mi"
    .....
$ kubectl create -f 7-pod-quota-mem.yaml
$ kubectl -n quota-demo-ns describe quota quota-demo-mem
$ kubectl -n quota-demo-ns delete po nginx
$ vi 7-pod-quota-mem.yaml
    .....
            memory: "800Mi"
    .....
$ kubectl create -f 7-pod-quota-mem.yaml
    < ERROR >
$ kubectl -n quota-demo-ns describe quota quota-demo-mem
$ kubectl -n quota-demo-ns delete po nginx

$ kubectl -n quota-demo-ns edit quota quota-demo-mem
    < change: 500 -> 900 >
$ kubectl -n quota-demo-ns describe quota quota-demo-mem
$ kubectl create -f 7-pod-quota-mem.yaml
$ kubectl -n quota-demo-ns describe quota quota-demo-mem
$ kubectl -n quota-demo-ns delete po nginx
$
```

## Quota Limitrange
```
$ watch  microk8s.kubectl -n quota-demo-ns get po,deploy,replicaset,limitrange,quota

$ cat 7-quota-mem.yaml
    apiVersion: v1
    kind: ResourceQuota
    metadata:
      name: quota-demo-mem
      namespace: quota-demo-ns
    spec:
      hard:
        limits.memory: "500Mi"
$ kubectl create -f 7-quota-mem.yaml
$ vi 7-quota-mem.yaml
    ....
        limits.memory: "500Mi"
        requests.memory: "100Mi"
$ kubectl apply -f 7-quota-mem.yaml
$ kubectl -n quota-demo-ns describe quota quota-demo-mem

$ vi 7-pod-quota-mem.yaml
    .....
    name: nginx
    resources:
      limits:
        memory: "200Mi"
$ kubectl create -f 7-pod-quota-mem.yaml
    < ERROR >
$ vi 7-pod-quota-mem.yaml
    .....
    name: nginx
    resources:
      limits:
        memory: "200Mi"
      requests:
        memory: "50Mi"
$ kubectl create -f 7-pod-quota-mem.yaml
$ kubectl -n quota-demo-ns describe pod nginx
$ kubectl delete -f 7-pod-quota-mem.yaml
$ vi 7-pod-quota-mem.yaml
    .....
    name: nginx
    resources:
      limits:
        memory: "200Mi"
      requests:
        memory: "150Mi"
$ kubectl -n quota-demo-ns describe quota quota-demo-mem
$ kubectl create -f 7-pod-quota-mem.yaml

$ cat 7-quota-limitrange.yaml
    apiVersion: v1
    kind: LimitRange
    metadata:
      name: mem-limitrange
      namespace: quota-demo-ns
    spec:
      limits:
      - default:
          memory: 300Mi
        defaultRequest:
          memory: 50Mi
        type: Container
$ kubectl create -f 7-quota-limitrange.yaml
$ kubectl -n quota-demo-ns describe limitrange mem-limitrange
$ kubectl create -f 7-pod-quota-mem.yaml
$ kubectl -n quota-demo-ns describe pod nginx
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
