[![Build Status](https://travis-ci.org/nginxinc/kubernetes-ingress.svg?branch=master)](https://travis-ci.org/nginxinc/kubernetes-ingress)  [![FOSSA Status](https://app.fossa.io/api/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress.svg?type=shield)](https://app.fossa.io/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress?ref=badge_shield)  [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)  [![Go Report Card](https://goreportcard.com/badge/github.com/nginxinc/kubernetes-ingress)](https://goreportcard.com/report/github.com/nginxinc/kubernetes-ingress)

# Ep02. Setup Kubernetes Cluster with Vagrant
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
|Worker2|kworker2.example.com|172.42.42.102|CentOS 7|1G|1|

## Get Git information
```
$ mkdir play && cd $_
$ git clone https://github.com/grtlinux/hello_kubernetes.git
$ cd hello_kubernetes/Season01/Ep02/run
```

## Make Vagrantfile and create machines

#### Check installation files

- Vagrantfile
```
$ cat Vagrantfile
    # -*- mode: ruby -*-
    # vi: set ft=ruby :

    ENV['VAGRANT_NO_PARALLEL'] = 'yes'

    Vagrant.configure(2) do |config|

      config.vm.provision "shell", path: "bootstrap.sh"

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
        kmaster.vm.provision "shell", path: "bootstrap_kmaster.sh"
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
          workernode.vm.provision "shell", path: "bootstrap_kworker.sh"
        end
      end

    end
```
- bootstrap.sh
```
$ cat bootstrap.sh
    #!/bin/bash

    # update hosts file
    echo "[TASK 1] update /etc/hosts file"
    cat >>/etc/hosts<<EOF
    172.42.42.100 kmaster.example.com kmaster
    172.42.42.101 kworker1.example.com kworker1
    172.42.42.102 kworker2.example.com kworker2
    EOF

    # Install docker from docker-ce repository
    echo "[TASK 2] install docker container engine"
    yum install -y -q yum-utils device-mapper-persistent-data lvm2 > /dev/null 2>&1
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > /dev/null 2>&1
    yum install -y -q docker-ce >/dev/null 2>&1

    # enable docker service
    echo "[TASK 3] enable and start docker service"
    systemctl enable docker >/dev/null 2>&1
    systemctl start docker

    # disable SELinux
    echo "[TASK 4] disable SELinux"
    setenforce 0
    sed -i --follow-symlinks 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux

    # stop and disable firewalld
    echo "[TASK 5] stop and disable firewalld"
    systemctl disable firewalld >/dev/null 2>&1
    systemctl stop firewalld

    # add sysctl settings
    echo "[TASK 6] add sysctl settings"
    cat >>/etc/sysctl.d/kubernetes.conf<<EOF
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    EOF
    sysctl --system >/dev/null 2>&1

    # disable swap
    echo "[TASK 7] disable and turn off swap"
    sed -i '/swap/d' /etc/fstab
    swapoff -a

    # add yum repo file fro kubernetes
    echo "[TASK 8] add yum repo file for kubernetes"
    cat >>/etc/yum.repos.d/kubernetes.repo<<EOF
    [kubernetes]
    name=Kubernetes
    baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
    enabled=1
    gpgcheck=1
    repo_gpgcheck=1
    gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
           https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
    EOF

    # install kubernetes
    echo "[TASK 9] install kubernetes (kubeadm, kubelet and kubectl)"
    yum install -y -q kubeadm kubelet kubectl >/dev/null 2>&1

    # start and enable kubelet service
    echo "[TASK 10] enable and start kubelet service"
    systemctl enable kubelet >/dev/null 2>&1
    systemctl start kubelet >/dev/null 2>&1

    # enable ssh password authentication
    echo "[TASK 11] enable ssh password authentication"
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl reload sshd

    # set root password
    echo "[TASK 12] set root password"
    echo "kubeadmin" | passwd --stdin root >/dev/null 2>&1

    # update vagrant user's bashrc file
    echo "[TASK 13] update vagrant user's bashrc file"
    echo "export TERM=xterm" >> /etc/bashrc
```
- bootstrap_kmaster.sh
```
$ cat bootstrap_kmaster.sh
    #!/bin/bash

    # initialize kubernetes
    echo "[TASK 1] initialize kubernetes cluster"
    kubeadm init --apiserver-advertise-address=172.42.42.100 --pod-network-cidr=192.168.0.0/16 \
        >> /root/kubeinit.log 2>/dev/null

    # copy kube admin config
    echo "[TASK 2] copy kube admin config to Vagrant user .kube directory"
    mkdir /home/vagrant/.kube
    cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
    chown -R vagrant:vagrant /home/vagrant/.kube

    # deploy flannel network
    #echo "[TASK 3] deploy flannel network"
    #su - vagrant -c "kubectl create -f https://github.com/coreos/flannel/blob/master/Documentation/kube-flannel.yml"

    # deploy calio network
    echo "[TASK 3] deploy calico network"
    su - vagrant -c "kubectl create -f https://docs.projectcalico.org/v3.11/manifests/calico.yaml"

    # generate cluster join command
    echo "[TASK 4] generate and save cluster join command to /joincluster.sh"
    kubeadm token create --print-join-command > /joincluster.sh
```
- bootstrap_kworker.sh
```
$ cat bootstrap_kworker.sh
    #!/bin/bash

    # join worker nodes to the kubernetes cluster
    echo "[TASK 1] join node to kubernetes cluster"
    yum install -q -y sshpass >/dev/null 2>&1
    sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        kmaster.example.com:/joincluster.sh /joincluster.sh 2>/dev/null
    bash /joincluster.sh >/dev/null 2>&1
```

#### Installation by __vagrant up__

```
$ vagrant up
    < wait 1 or 2 minutes >

```

#### Check nodes
```
$ vagrant ssh kmaster
    [vagrant@kmaster ~]$ nproc
    [vagrant@kmaster ~]$ free -m
    [vagrant@kmaster ~]$ df -h
    [vagrant@kmaster ~]$ cat /etc/redhat-release
    [vagrant@kmaster ~]$ cat /proc/cpuinfo
    [vagrant@kmaster ~]$ fdisk -l
    [vagrant@kmaster ~]$ ip a
    [vagrant@kmaster ~]$ netstat -lntp
    [vagrant@kmaster ~]$ ping google.com
    [vagrant@kmaster ~]$ kubectl cluster-info
    [vagrant@kmaster ~]$ kubectl version --short
    [vagrant@kmaster ~]$ kubectl get nodes
    [vagrant@kmaster ~]$ kubectl get namespaces
    [vagrant@kmaster ~]$ logout

$ vagrant ssh kworker1
    [vagrant@kworker1 ~]$ nproc
    [vagrant@kworker1 ~]$ free -m
    [vagrant@kworker1 ~]$ df -h
    [vagrant@kworker1 ~]$ cat /etc/redhat-release
    [vagrant@kworker1 ~]$ cat /proc/cpuinfo
    [vagrant@kworker1 ~]$ fdisk -l
    [vagrant@kworker1 ~]$ ip a
    [vagrant@kworker1 ~]$ netstat -lntp
    [vagrant@kworker1 ~]$ ping google.com
    [vagrant@kworker1 ~]$ logout

$ vagrant ssh kworker2
    [vagrant@kworker2 ~]$ nproc
    [vagrant@kworker2 ~]$ free -m
    [vagrant@kworker2 ~]$ df -h
    [vagrant@kworker2 ~]$ cat /etc/redhat-release
    [vagrant@kworker2 ~]$ cat /proc/cpuinfo
    [vagrant@kworker2 ~]$ fdisk -l
    [vagrant@kworker2 ~]$ ip a
    [vagrant@kworker2 ~]$ netstat -lntp
    [vagrant@kworker2 ~]$ ping google.com
    [vagrant@kworker2 ~]$ logout
```


## Copy cluster config file to local

```
$ rm ~/.ssh/known_hosts
$ mkdir ~/.kube
$ scp vagrant@kmaster:.kube/config ~/.kube/config

$ kubectl cluster-info
$ kubectl version --short
$ kubectl get nodes
$ kubectl get namespaces
```

## about snapshot

```
$ vagrant help snapshot
$ vagrant snapshot list
$ vagrant snapshot save kmaster kubernetes-kmaster-base
$ vagrant snapshot save kworker1 kubernetes-kworker1-base
$ vagrant snapshot save kworker2 kubernetes-kworker2-base
$ vagrant snapshot list
$ vagrant snapshot restore kmaster kubernetes-kmaster-base
$ vagrant snapshot list
$ vagrant snapshot delete kubernetes-kmaster-base
$ vagrant snapshot list
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
