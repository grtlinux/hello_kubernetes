[![Build Status](https://travis-ci.org/nginxinc/kubernetes-ingress.svg?branch=master)](https://travis-ci.org/nginxinc/kubernetes-ingress)  [![FOSSA Status](https://app.fossa.io/api/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress.svg?type=shield)](https://app.fossa.io/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress?ref=badge_shield)  [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)  [![Go Report Card](https://goreportcard.com/badge/github.com/nginxinc/kubernetes-ingress)](https://goreportcard.com/report/github.com/nginxinc/kubernetes-ingress)

# Ep01. Setup Kubernetes Cluster using kubeadm on CentOS 7
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
$ cd hello_kubernetes/Season01/Ep01/run
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

    NodeCount = 1
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
$ vagrant up
    < wait 1 or 2 minutes >

```

## Confirm the virtual machines

```
$ vagrant status
$ vagrant box list
$ tree ~/.vagrant.d
$ vboxmanage list vms
$ vboxmanage list runningvms
```

## SSH connection and check machine information respectivly

```
$ vagrant ssh kmaster
    [vagrant@kmaster ~]$ cat /etc/redhat-release
    [vagrant@kmaster ~]$ nproc
    [vagrant@kmaster ~]$ free -m
    [vagrant@kmaster ~]$ df -h
    [vagrant@kmaster ~]$ hostname -a
    [vagrant@kmaster ~]$ ip a
    [vagrant@kmaster ~]$ logout
$ vagrant ssh kworker1
    [vagrant@kworker1 ~]$ cat /etc/redhat-release
    [vagrant@kworker1 ~]$ nproc
    [vagrant@kworker1 ~]$ free -m
    [vagrant@kworker1 ~]$ df -h
    [vagrant@kworker1 ~]$ hostname -a
    [vagrant@kworker1 ~]$ ip a
    [vagrant@kworker1 ~]$ logout
```

## On both machines jobs (kmaster/kworker1)

#### Change /etc/hosts file

```
    $ sudo -i
    # cat >>/etc/hosts<<EOF
        172.42.42.100 kmaster.example.com kmaster
        172.42.42.101 kworker1.example.com kworker1
EOF
    # ping kmaster
    # ping kworker1
```

#### Install docker and start service

Use the Docker repository to install docker
> If you use docker from CentOS OS repository, the docker version might be old to work with Kubernetes v1.13.0 and above
```
    # yum install -y -q yum-utils device-mapper-persistent-data lvm2 > /dev/null 2>&1
    # yum-config-manager --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo > /dev/null 2>&1
    # yum install -y -q docker-ce >/dev/null 2>&1
    # systemctl enable docker
    # systemctl start docker
    # systemctl status docker
```

#### Disable SELinux

```
    # setenforce 0
    # sed -i --follow-symlinks 's/^SELINUX=enforcing/SELINUX=disabled/' \
        /etc/sysconfig/selinux
```

#### Disabel Firewall

```
    # systemctl disable firewalld
    # systemctl stop firewalld
    # systemctl status firewalld
```

#### Disable swap

```
    # sed -i '/swap/d' /etc/fstab
    # swapoff -a
```

#### Update sysctl settings for Kubernetes networking

```
    # cat >>/etc/sysctl.d/kubernetes.conf<<EOF
        net.bridge.bridge-nf-call-ip6tables = 1
        net.bridge.bridge-nf-call-iptables = 1
EOF
    # sysctl --system
```

## Kubernetes Setup

#### Add yum repository

```
    # cat >>/etc/yum.repos.d/kubernetes.repo<<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
```

#### Install Kubernetes

```
    # yum install -y kubeadm kubelet kubectl
```

#### Enable and Start kubelet service

```
    # systemctl enable kubelet
    # systemctl start kubelet
    # systemctl status kubelet
```

#### Enable ssh password authentication
```
    # sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' \
        /etc/ssh/sshd_config
    # systemctl reload sshd
```

## On kmaster

#### Initialize Kubernetes Cluster

```
    # kubeadm init --apiserver-advertise-address=172.42.42.100 \
        --pod-network-cidr=192.168.0.0/16
```

#### Copy kube config

To be able to use kubectl command to connect and interact with the cluster, the user needs kube config file.
In my case, the user account is __vagrant__
```
    $ mkdir /home/vagrant/.kube
    $ sudo cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
    $ sudo chown -R vagrant:vagrant /home/vagrant/.kube

    $ kubectl cluster-info
    $ kubectl version --short
    $ kubectl get nodes
```

#### Deploy Calico network

This has to be done as the user in the above step (in my case it is __vagrant__)
```
    $ kubectl create -f https://docs.projectcalico.org/v3.11/manifests/calico.yaml
```

#### Cluster join command

```
    # kubeadm token create --print-join-command
```



## On kworker1

Join the cluster
Use the output from __kubeadm token create__ command in previous step from the master server and run here.

## Verifying the cluster

#### Get Nodes status

```
    # kubectl get nodes
```

#### Get component status

```
    # kubectl get cs
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

---

Have Fun!!
