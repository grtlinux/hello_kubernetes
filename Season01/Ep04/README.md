[![Build Status](https://travis-ci.org/nginxinc/kubernetes-ingress.svg?branch=master)](https://travis-ci.org/nginxinc/kubernetes-ingress)  [![FOSSA Status](https://app.fossa.io/api/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress.svg?type=shield)](https://app.fossa.io/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress?ref=badge_shield)  [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)  [![Go Report Card](https://goreportcard.com/badge/github.com/nginxinc/kubernetes-ingress)](https://goreportcard.com/report/github.com/nginxinc/kubernetes-ingress)

# Ep04. Single node Kubernetes Cluster with Minikube
Follow this documentation to set up a Kubernetes cluster on __CentOS 7__ Virtual machines.

This documentation guides you in setting up a cluster with one master node and one worker node.

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

## Get Git information
```
$ mkdir play && cd $_
$ git clone https://github.com/grtlinux/hello_kubernetes.git
$ cd hello_kubernetes/Season01/Ep04/run
```

## Installation of kubectl

Search 'install kubectl' on Google Chrome

#### install kubectl with curl

```
$ sudo apt-get update && sudo apt-get install -y apt-transport-https
$ curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s \
    https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.17.0/bin/linux/amd64/kubectl
$ chmod +x ./kubectl
$ sudo mv ./kubectl /usr/local/bin/kubectl
$ which kubectl
$ kubectl version --client
```

#### install kubectl with apt-get

```
$ sudo apt-get update && sudo apt-get install -y apt-transport-https
$ curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
$ echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" \
    | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
$ sudo apt-get update
$ sudo apt-get install -y kubectl
$ which kubectl
$ kubectl version --client
```

## Installation of minikube

Search 'install minikube' on Google Chrome

#### install minikube with curl

```
$ curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
$ chmod +x minikube
$ sudo mv ./minikube /usr/local/bin/minikube
$ which minikube
$ minikube version
```

## Create minikube-cluster

```
$ minikube help | less
$ minikube status
$ minikube start [--kubernetes-version v1.13.0] [--cpus 1] [--memory 1024]
$ minikube status
$ minikube ip
$ minikube logs | less
$ minikube ssh
    $ sudo docker images
    $ sudo docker ps -a
    $ logout

$ kubectl cluster-info
$ kubectl version --short
$ kubectl get nodes -o wide
$ kubectl get namespaces
$ kubectl get all --all-namespaces

< window 1 >
$ watch kubectl get all -o wide

< window 2 >
$ kubectl run myshell --rm -it --image busybox -- sh
    / # ping google.com
    / # exit
$ kubectl config view

$ minikube stop
$ minikube status
$ minikube delete
$ cd ~/.minikube
$ ls -al
$ cd ..
$ rm -rf .minikube
```

```
$ minikube start [--kubernetes-version v1.13.0] [--cpus 1] [--memory 1024]
$ minikube status
$ minikube ip
$ kubectl cluster-info
$ kubectl version --short
$ kubectl get no
$ kubectl get ns

< window 1 >
$ minikube dashboard

< window 2 >
$ curl http://127.0.0.1:35035/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy/

$ minikube delete
$ rm -rf ~/.minikube
$ rm -rf ~/.kube
$ sudo rm -rf /usr/local/bin/minikube
$ sudo rm -rf /usr/local/bin/kubectl
```

## Single node kubernetes with Minikube

```
$ mkdir play && cd $_
$ git clone https://github.com/grtlinux/hello_kubernetes.git
$ cd hello_kubernetes/Season01/Ep04/run0
$ vagrant up

$ vagrant ssh
    $
    $ sudo apt-get update && sudo apt-get install -y apt-transport-https
    $ curl -LO \
        https://storage.googleapis.com/kubernetes-release/release/v1.17.0/bin/linux/amd64/kubectl
    $ chmod +x ./kubectl
    $ sudo mv ./kubectl /usr/local/bin/kubectl
    $ which kubectl
    $ kubectl version --client

    $ curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    $ chmod +x minikube
    $ sudo mv ./minikube /usr/local/bin/minikube
    $ which minikube
    $ minikube version




```




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
