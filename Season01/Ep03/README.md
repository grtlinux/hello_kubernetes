[![Build Status](https://travis-ci.org/nginxinc/kubernetes-ingress.svg?branch=master)](https://travis-ci.org/nginxinc/kubernetes-ingress)  [![FOSSA Status](https://app.fossa.io/api/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress.svg?type=shield)](https://app.fossa.io/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress?ref=badge_shield)  [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)  [![Go Report Card](https://goreportcard.com/badge/github.com/nginxinc/kubernetes-ingress)](https://goreportcard.com/report/github.com/nginxinc/kubernetes-ingress)

# Ep03. Kubernetes single node cluster using microk8s
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
$ cd hello_kubernetes/Season01/Ep03/run
```

## Ubuntu18

#### check vagrant file
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
            v.memory = 2048
            v.cpus = 1
          end
        end
      end

    end
```

#### Create VM of Ubuntu 18.04
```
$ vagrant up
    < wait 1 or 2 minutes >

```

#### test vm
```
$ vagrant ssh
    vagrant@ubuntuvm01:~$ lsb_release -dirc
    vagrant@ubuntuvm01:~$ nproc
    vagrant@ubuntuvm01:~$ free -m
    vagrant@ubuntuvm01:~$ df -h
    vagrant@ubuntuvm01:~$ cat /etc/redhat-release
    vagrant@ubuntuvm01:~$ cat /proc/cpuinfo
    vagrant@ubuntuvm01:~$ fdisk -l
    vagrant@ubuntuvm01:~$ ip a
    vagrant@ubuntuvm01:~$ netstat -lntp
    vagrant@ubuntuvm01:~$ ping google.com

    vagrant@ubuntuvm01:~$ sudo apt install snapd
    vagrant@ubuntuvm01:~$ sudo snap install microk8s --classic --channel=1.13/stable
    vagrant@ubuntuvm01:~$ snap list
    vagrant@ubuntuvm01:~$ microk8s.kubectl cluster-info
    vagrant@ubuntuvm01:~$ microk8s.kubectl version --short
    vagrant@ubuntuvm01:~$ alias kubectl='microk8s.kubectl'
    vagrant@ubuntuvm01:~$ kubectl version --short
    vagrant@ubuntuvm01:~$ kubectl get nodes -o wide
    vagrant@ubuntuvm01:~$ kubectl get namespaces

    vagrant@ubuntuvm01:~$ dpkg -l | grep docker
    vagrant@ubuntuvm01:~$ ps -ef | grep docker
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$ sudo apt install docker.io
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$ sudo usermod -a -G microk8s vagrant
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$ kubectl cluster-info
    vagrant@ubuntuvm01:~$ kubectl version --short
    vagrant@ubuntuvm01:~$ kubectl get nodes
    vagrant@ubuntuvm01:~$ kubectl get namespaces
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$
    vagrant@ubuntuvm01:~$ logout

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
