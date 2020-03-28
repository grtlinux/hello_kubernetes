[![Build Status](https://travis-ci.org/nginxinc/kubernetes-ingress.svg?branch=master)](https://travis-ci.org/nginxinc/kubernetes-ingress)  [![FOSSA Status](https://app.fossa.io/api/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress.svg?type=shield)](https://app.fossa.io/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress?ref=badge_shield)  [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)  [![Go Report Card](https://goreportcard.com/badge/github.com/nginxinc/kubernetes-ingress)](https://goreportcard.com/report/github.com/nginxinc/kubernetes-ingress)

# Ep15. Using ConfigMaps in Kubernetes Cluster

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
$ cd hello_kubernetes/Season01/Ep15/run0
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
$ cd hello_kubernetes/Season01/Ep15/run1
$ ls -l
    6-configmap-1.yaml
    6-configmap-2.yaml
    6-pod-configmap-env.yaml
    6-pod-configmap-mysql-volume.yaml
    6-pod-configmap-volume.yaml
    misc/
$
```

## create demo-configmap
```
$ kubectl get comfigmaps
$ kubectl get cm
$ cat 6-configmap-1.yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: demo-configmap
    data:
      channel.name: "justmeandopensource"
      channel.owner: "Venkat Nagappan"
$ kubectl create -f 6-configmap-1.yaml
$ kubectl get cm
$ kubectl get cm -o yaml
$ kubectl get cm demo-configmap
$ kubectl get cm demo-configmap -o yaml
$ kubectl describe cm demo-configmap
$ kubectl edit cm demo-configmap
    .....
      channel.name: just me and open source
    .....
$
```

## create demo-configmap-1
```
$ kubectl create cm demo-configmap-1 \
    --from-literal=channel.name="Hello world" \
    --from-literal=channel.owner="Kiea Seok Kang"
$ kubectl get cm
$ kubectl get cm demo-configmap-1 -o yaml
$ kubectl describe cm demo-configmap-1
```

## use the configmaps in pod.
```
$ cat 6-pod-configmap-env.yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: busybox
    spec:
      containers:
      - image: busybox
        name: busybox
        command: ["/bin/sh"]
        args: ["-c", "sleep 600"]
        env:
        - name: CHANNELNAME
          valueFrom:
            configMapKeyRef:
              name: demo-configmap
              key: channel.name
        - name: CHANNELOWNER
          valueFrom:
            configMapKeyRef:
              name: demo-configmap
              key: channel.owner
$ kubectl get pods
$ kubectl create -f 6-pod-configmap-env.yaml
$ kubectl get pods
$ kubectl exec -it busybox sh
    / # echo $CHANNELNAME
    / # echo $CHANNELOWNER
    / # env | grep -i channel
    / # exit
$ kubectl delete pod busybox
$ kubectl get po
```

## pod using configmap volume
```
$ cat 6-pod-configmap-volume.yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: busybox
    spec:
      volumes:
      - name: demo
        configMap:
          name: demo-configmap
      containers:
      - image: busybox
        name: busybox
        command: ["/bin/sh"]
        args: ["-c", "sleep 600"]
        volumeMounts:
        - name: demo
          mountPath: /mydata
$ kubectl create -f 6-pod-configmap-volume.yaml
$ kubectl get po
$ kubectl exec -it busybox sh
    / # env | grep -i channel
    / # cd /mydata
    / # ls
        channel.name    channel.owner
    / # exit
$ kubectl edit cm demo-configmap
    .....
      channel.date: "2020-03-20"
      channel.name: "justmeandopensource"
    .....
$ kubectl get cm demo-configmap
$ kubectl exec -it busybox sh
    / # cd /mydata
    / # ls
        channel.date   channel.name   channel.owner
    / # exit
$ kubectl delete cm demo-configmap
$ kubectl get cm
$ kubectl delete po busybox
$ kubectl get po
```

## misc/my.cnf
```
$ cat misc/my.cnf
    [mysqld]
    pid-file	= /var/run/mysqld/mysqld.pid
    socket		= /var/run/mysqld/mysqld.sock
    port		  = 9999
    datadir		= /var/lib/mysql
    default-storage-engine  = InnoDB
    character-set-server    = utf8
    bind-address		        = 127.0.0.1
    general_log_file        = /var/log/mysql/mysql.log
    log_error               = /var/log/mysql/error.log
$ kubectl create configmap mysql-demo-config --from-file=misc/my.cnf
$ kubectl get cm mysql-demo-config -o yaml
$ kubectl describe cm mysql-demo-config
$ kubectl delete cm mysql-demo-config
```

## 6-comfigmap-2.yaml
```
$ cat 6-comfigmap-2.yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: mysql-demo-config
   data:
     my.cnf: |
       [mysqld]
       pid-file        = /var/run/mysqld/mysqld.pid
       socket          = /var/run/mysqld/mysqld.sock
       port            = 3306
       datadir         = /var/lib/mysql
       default-storage-engine  = InnoDB
       character-set-server    = utf8
       bind-address            = 127.0.0.1
       general_log_file        = /var/log/mysql/mysql.log
       log_error               = /var/log/mysql/error.log
$ kubectl create -f 6-configmap-2.yaml
$ kubectl get cm
$ kubectl get cm mysql-demo-config -o yaml
$ kubectl describe cm mysql-demo-config
$ cat 6-pod-configmap-mysql-volume.yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: busybox
    spec:
      volumes:
      - name: mysql-config
        configMap:
          name: mysql-demo-config
          items:
            - key: my.cnf
              path: my.cnf
      containers:
      - image: busybox
        name: busybox
        command: ["/bin/sh"]
        args: ["-c", "sleep 600"]
        volumeMounts:
        - name: mysql-config
          mountPath: /mydata
$ kubectl create -f 6-pod-configmap-mysql-volume.yaml
$ kubectl get po,cm
$ kubectl exec -it busybox sh
    / # cd /mydata
    / # ls
    / # cat my.cnf
    / # exit
$ vi 6-comfigmap-2.yaml
    .....
       port            = 9999
    .....
$ kubectl apply -f 6-configmap-2.yaml
$ kubectl exec -it busybox sh
    / # cd /mydata
    / # ls
    / # cat my.cnf
    / # exit
$ kubectl delete cm mysql-demo-config
$ kubectl delete po busybox
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
