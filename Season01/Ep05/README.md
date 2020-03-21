[![Build Status](https://travis-ci.org/nginxinc/kubernetes-ingress.svg?branch=master)](https://travis-ci.org/nginxinc/kubernetes-ingress)  [![FOSSA Status](https://app.fossa.io/api/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress.svg?type=shield)](https://app.fossa.io/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress?ref=badge_shield)  [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)  [![Go Report Card](https://goreportcard.com/badge/github.com/nginxinc/kubernetes-ingress)](https://goreportcard.com/report/github.com/nginxinc/kubernetes-ingress)

# Ep05. Install Kubernetes Dashboard Web UI
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
$ cd hello_kubernetes/Season01/Ep05/run0
```

## Make Vagrantfile and create machines

```
    # -*- mode: ruby -*-
    # vi: set ft=ruby :

    ENV['VAGRANT_NO_PARALLEL'] = 'yes'

    Vagrant.configure(2) do |config|

        config.vm.provision "shell", path: "bootstrap.sh"

        # kubernetes master server
        config.vm.define "kmaster" do |kmaster|
            kmaster.vm.box = "centos/7"
            kmaster.vm.hostname = "kmaster.example.com"
            kmaster.vm.network "private_network", ip: "172.42.42.100"
            kmaster.vm.provider "virtualbox" do |v|
                v.name = "kmaster"
                v.memory = 2048
                v.cpus = 2
                # prevent virtualbox from interfering with host audio stack
                v.customize ["modifyvm", :id, "--audio", "none"]
            end
            kmaster.vm.provision "shell", path: "bootstrap_kmaster.sh"
        end

        NodeCount = 2
        # kubernetes worker node
        (1..NodeCount).each do |i|
            config.vm.define "kworker#{i}" do |workernode|
                workernode.vm.box = "centos/7"
                workernode.vm.hostname = "kworker#{i}.example.com"
                workernode.vm.network "private_network", ip: "172.42.42.10#{i}"
                workernode.vm.provider "virtualbox" do |v|
                    v.name = "kworker#{i}"
                    v.memory = 1024
                    v.cpus = 1
                    # prevent virtualbox from interfering with host audio stack
                    v.customize ["modifyvm", :id, "--audio", "none"]
                end
                workernode.vm.provision "shell", path: "bootstrap_kworker.sh"
            end
        end

    end
```

```
$ vagrant up
    < wait 1 or 2 minutes >
```

---

```
$ cd ../dashbaord
$ watch kubectl get all --all-namespaces
$ kubectl create -f influxdb.yaml
$ kubectl create -f heapster.yaml
$ kubectl create -f dashboard.yaml
$ kubectl create -f sa_cluster_admin.yaml

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
