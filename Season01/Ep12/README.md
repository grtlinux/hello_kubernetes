[![Build Status](https://travis-ci.org/nginxinc/kubernetes-ingress.svg?branch=master)](https://travis-ci.org/nginxinc/kubernetes-ingress)  [![FOSSA Status](https://app.fossa.io/api/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress.svg?type=shield)](https://app.fossa.io/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress?ref=badge_shield)  [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)  [![Go Report Card](https://goreportcard.com/badge/github.com/nginxinc/kubernetes-ingress)](https://goreportcard.com/report/github.com/nginxinc/kubernetes-ingress)

# Ep12. Init Containers in Kubernetes Cluster

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
$ cd hello_kubernetes/Season01/Ep12/run0
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
```

---
## Init Container
```
$
$ cat 3-init-container.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      labels:
        run: nginx
      name: nginx-deploy
    spec:
      replicas: 1
      selector:
        matchLabels:
          run: nginx
      template:
        metadata:
          labels:
            run: nginx

        spec:

          volumes:
          - name: shared-volume
            emptyDir: {}

          initContainers:
          - name: busybox
            image: busybox
            volumeMounts:
            - name: shared-volume
              mountPath: /nginx-data
            command: ["/bin/sh"]
            args: ["-c", "echo '<h1>Hello Kubernetes</h1>' > /nginx-data/index.html"]

          containers:
          - image: nginx
            name: nginx
            volumeMounts:
            - name: shared-volume
              mountPath: /usr/share/nginx/html
$ kubectl create -f 3-init-container.yaml
$ kubectl expose deploy nginx-deploy --type NodePort --target-port 30001 --port 80
$ curl http://kworker1:32567
$ curl http://kworker2:32567
$ kubectl delete svc nginx-deploy
$ kubectl delete deploy nginx-deploy
$ cat 3-init-container.yaml
    .....
            command: ["/bin/123456"]
            args: ["-c", "echo '<h1>Hello Kubernetes</h1>' > /nginx-data/index.html"]
    .....
$ kubectl create -f 3-init-container.yaml
    < ERROR: Init:RunContainerError >
$ kubectl describe deploy nginx-deploy | less
$ kubctl delete -f 3-init-container.yaml
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
