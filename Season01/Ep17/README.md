[![Build Status](https://travis-ci.org/nginxinc/kubernetes-ingress.svg?branch=master)](https://travis-ci.org/nginxinc/kubernetes-ingress)  [![FOSSA Status](https://app.fossa.io/api/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress.svg?type=shield)](https://app.fossa.io/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress?ref=badge_shield)  [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)  [![Go Report Card](https://goreportcard.com/badge/github.com/nginxinc/kubernetes-ingress)](https://goreportcard.com/report/github.com/nginxinc/kubernetes-ingress)

# Ep17. Renaming Kubernetes Nodes

## Ready
|Preinstall|Version|
|----|----|
|Vagrant|1.0|
|VirtualBox|6.0|
|Kubernetes|1.17.0|

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
$ cd hello_kubernetes/Season01/Ep17/run0
```

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
$ rm ~/.ssh/known_hosts
$ scp vagrant@kmaster:.kube/config ~/.kube/config
$ kubectl cluster-info
$ kubectl version --short
$ kubectl get nodes
$ kubectl delete pods --all
$ kubectl api-resources
```

---
## 1st
```
$ watch -x kubectl get all -o wide

$ kubectl get nodes
$ kubectl run nginx1 --image nginx
$ kubectl run nginx2 --image nginx
$ kubectl delete pod nginx1 --force
$ kubectl delete pod nginx2 --force

$ ssh root@kworker2
    # hostname
    # hostnamectl set-hostname kubeworker2.example.com
    # vi /etc/hosts
        .....
        172.42.42.102 kubeworker2.example.com kubeworker2
    # reboot
$ ssh root@kworker1
    # vi /etc/hosts
        .....
        172.42.42.102 kubeworker2.example.com kubeworker2
    # logout
$ ssh root@kmaster
    # vi /etc/hosts
        .....
        172.42.42.102 kubeworker2.example.com kubeworker2
    # kubeadm token create --print-join-command
        kubeadm .....(token).....
    # logout
$ sudo vi /etc/hosts
    .....
    172.42.42.102 kubeworker2.example.com kubeworker2
$ ssh root@kubeworker2
    # journalctl --unit=kubelet
        .....
        ... node "kubeworker2.example.com" not found
    # systemctl status kubelet
        .....
    #
$ kubectl edit no kworker2.example.com
    :%s/kworker2/kubeworker2/
$ kubectl delete no kworker2.example.com
    < ERROR>

$ ssh root@kubeworker2
    # kubeadm reset
    # kubeadm .....(token).....
$ kubectl drain kworker1.example.com
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
