[![Build Status](https://travis-ci.org/nginxinc/kubernetes-ingress.svg?branch=master)](https://travis-ci.org/nginxinc/kubernetes-ingress)  [![FOSSA Status](https://app.fossa.io/api/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress.svg?type=shield)](https://app.fossa.io/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress?ref=badge_shield)  [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)  [![Go Report Card](https://goreportcard.com/badge/github.com/nginxinc/kubernetes-ingress)](https://goreportcard.com/report/github.com/nginxinc/kubernetes-ingress)

# Ep14. Using Secrets in Kubernetes

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
$ cd hello_kubernetes/Season01/Ep14/run0
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
## Secret
```
$ kubectl get secrets
$ echo -n "kubeadmin" | base64
$ echo -n "mypassword" | base64
$ cat 5-secrets.yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: secret-demo
    type: Opaque
    data:
      username: XXXXX
      password: XXXXXX
$ kubectl create -f 5-secrets.yaml
$ kubectl get secret secret-demo -o yaml
$ kubectl describe secret secret-demo
$ kubectl delete secret secret-demo
```

```
$ kubectl create secret generic secret-demo \
    --from-literal=username=kubeadmin \
    --from-literal=password=mypassword
$ kubectl get secret
$ kubectl delete secret secret-demo
```

```
$ cat username
    kubeadmin
$ cat password
    mypassword
$ kubectl create secret generic secret-demo \
    --from-file=./username \
    --from-file=./password
$ kubectl get secret
$ kubectl delete secret secret-demo
```

```
$ kubectl create secret generic secret-demo \
    --from-literal=username=kubeadmin \
    --from-literal=password=mypassword
$ cat 5-pod-secret-env.yaml
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
        - name: myusername
          valueFrom:
            secretKeyRef:
              name: secret-demo
              key: username
$ kubectl create -f 5-pod-secret-env.yaml
$ kubectl exec -it busybox -- sh
    # env | grep myusername
    # echo $myusername
    # exit
$ kubectl delete pod busybox
```

```
$ kubectl create secret generic secret-demo \
    --from-file=./username \
    --from-file=./password
$ cat 5-pod-secret-volume.yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: busybox
    spec:
      volumes:
      - name: secret-volume
        secret:
          secretName: secret-demo
      containers:
      - name: busybox
        image: busybox
        command: ["/bin/sh"]
        args: ["-c", "sleep 600"]
        volumeMounts:
        - name: secret-volume
          mountPath: /mydata
$ kubectl create -f 5-pod-secret-volume.yaml
$ kubectl exec -it busybox -- sh
    # cd /mydata
    # ls
    # cat username; echo
    # cat password; echo
    # exit
$ kubectl delete pod busybox
$
```

#### change the secret files after 'kubectl apply -f ...'
```
$ kubectl create secret generic secret-demo \
    --from-literal=username=kubeadmin \
    --from-literal=password=mypassword
$ kubectl create -f 5-pod-secret-volume.yaml
$ kubectl exec -it busybox -- sh
    # cd /mydata
    # ls
        username   password
    # exit
$ echo -n "kubeadmin" | base64
$ echo -n "myrandompassword" | base64
$ echo -n "kiea" | base64
$ cat 5-secrets.yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: secret-demo
    type: Opaque
    data:
      name: XXXXX
      username: XXXXX
      password: XXXXXX
$ kubectl apply -f 5-secrets.yaml
$ kubectl exec -it busybox -- sh
    # cd /mydata
    # ls
        kiea   username   password
    # exit
$ kubectl get secret secret-demo -o yaml
$ kubectl describe secret secret-demo
$ kubectl delete secret secret-demo
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
