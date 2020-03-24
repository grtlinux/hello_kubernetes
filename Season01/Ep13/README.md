[![Build Status](https://travis-ci.org/nginxinc/kubernetes-ingress.svg?branch=master)](https://travis-ci.org/nginxinc/kubernetes-ingress)  [![FOSSA Status](https://app.fossa.io/api/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress.svg?type=shield)](https://app.fossa.io/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress?ref=badge_shield)  [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)  [![Go Report Card](https://goreportcard.com/badge/github.com/nginxinc/kubernetes-ingress)](https://goreportcard.com/report/github.com/nginxinc/kubernetes-ingress)

# Ep13. Using Persistent Volumes and Claims in Kubernetes Cluster

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
$ cd hello_kubernetes/Season01/Ep13/run0
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
## Sequence about the Persistent Volume
1. create PV
2. create PVC
3. Pod that uses the PVC -> PV

## ReclaimPolicy
1. Retain
2. Recycle
3. Delete

## Access Mode
1. RWO (Read Write Once)
2. RWM (Read Write Many)
3. RO (Read Only)


---
## PersistentVolume, PersistentVolumeClaim and Hostpath
```
$ watch -x kubectl get pv -o wide

$ cat 4-pv-hostpath.yaml
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: pv-hostpath
      labels:
        type: local
    spec:
      storageClassName: manual
      capacity:
        storage: 1Gi
      accessModes:
        - ReadWriteOnce
      hostPath:
        path: "/kube"
$ ssh root@kworker1
    # mkdir /kube
    # chmod 0777 /kube
    # logout
$ kubectl craete -f 4-pv-hostpath.yaml

$ cat 4-pvc-hostpath.yaml
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: pvc-hostpath
    spec:
      storageClassName: manual
      accessModes:
        - ReadWriteOnce            # ReadWriteMany
      resources:
        requests:
          storage: 100Mi
$ kubectl create -f 4-pvc-hostpath.yaml

$ cat 4-busybox-pv-hostpath.yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: busybox
    spec:
      volumes:
      - name: host-volume
        persistentVolumeClaim:
          claimName: pvc-hostpath
      containers:
      - image: busybox
        name: busybox
        command: ["/bin/sh"]
        args: ["-c", "sleep 600"]
        volumeMounts:
        - name: host-volume
          mountPath: /mydata
$ kubectl create -f 4-busybox-pv-hostpath.yaml
$ kubectl exec busybox ls
$ kubectl exec busybox ls /mydata
$ kubectl exec busybox touch /mydata/hello
$ kubectl exec busybox ls /mydata
$ kubectl delete pod busybox
$ kubectl delete pvc pvc-hostpath
$ ssh root@kworker1                   # ssh root@kworker2
    # cd /kube
    # ls
    # logout
$ kubectl create -f 4-pvc-hostpath.yaml

$ kubectl delete pvc pvc-hostpath
$ kubectl delete pv pv-hostpath
```

```
$ kubectl create -f 4-pv-hostpath.yaml
$ kubectl create -f 4-pvc-hostpath.yaml
$ cat 4-busybox-pv-hostpath.yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: busybox
    spec:
      volumes:
      - name: host-volume
        persistentVolumeClaim:
          claimName: pvc-hostpath
      containers:
      - image: busybox
        name: busybox
        command: ["/bin/sh"]
        args: ["-c", "sleep 600"]
        volumeMounts:
        - name: host-volume
          mountPath: /mydata
      nodeSelector:
        demoserver: "true"
$ kubectl get nodes -l demoserver=true
$ kubectl label node kworker1.example.com demoserver=true
$ kubectl get nodes -l demoserver=true
$ kubectl create -f 4-busybox-pv-hostpath.yaml
$ kubectl exec busybox touch /mydata/hello2
$ kubectl delete pod busybox
$ kubectl delete pvc pvc-hostpath
$ kubectl delete pv pv-hostpath
$ ssh root@kworker1
    # cd /kube
    # ls
    # logout
$
```

```
$ watch -x kubectl get pv,pvc,pod -o wide

$ cat 4-pv-hostpath.yaml
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: pv-hostpath
      labels:
        type: local
    spec:
      storageClassName: manual
      persistentVolumeReclaimPolicy: Delete    # add
      capacity:
        storage: 1Gi
      accessModes:
        - ReadWriteOnce
      hostPath:
        path: "/tmp/kube"               # change
$ cat 4-pvc-hostpath.yaml
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: pvc-hostpath
    spec:
      storageClassName: manual
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 100Mi
$ cat 4-busybox-pv-hostpath.yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: busybox
    spec:
      volumes:
      - name: host-volume
        persistentVolumeClaim:
          claimName: pvc-hostpath
      containers:
      - image: busybox
        name: busybox
        command: ["/bin/sh"]
        args: ["-c", "sleep 600"]
        volumeMounts:
        - name: host-volume
          mountPath: /mydata
$ kubectl create -f 4-pv-hostpath.yaml
$ kubectl create -f 4-pvc-hostpath.yaml
$ kubectl create -f 4-busybox-pv-hostpath.yaml
$ kubectl exec busybox touch /mydata/hello1
$ kubectl exec busybox touch /mydata/hello2
$ kubectl delete po busybox
$ kubectl delete pvc pvc-hostpath
$ kubectl delete pv pv-hostpath
$ ssh root@kworker1               root@kworker2
    # cd /tmp/kube
    # ls
        hello1  hello2
    # logout
$
```

## PersistentVolume, PersistentVolumeClaim and Hostpath
```
$ sudo apt update && sudo apt upgrade
$ sudo apt install nfs-kernel-server
$ sudo cat /proc/fs/nfsd/versions
    -2 +3 +4 +4.1 +4.2
$ sudo mkdir /srv/nfs/kube -p
$ sudo chmod 0777 /srv/nfs/kube
$ sudo vi /etc/exports
    /srv/nfs/kube    172.42.42.0/24(rw,sync)
$ sudo exportfs -r
$ sudo showmount -e
$ sudo systemctl restart nfs-server
$ sudo systemctl status nfs-server
$ ssh root@kworker1
    # mount 172.42.42.1:/srv/nfs/kube /mnt
    # umount /mnt
    # logout
$
```

```
$ watch -x kubectl get pv -o wide

$ cat 4-pv-nfs.yaml
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: pv-nfs-pv1
      labels:
        type: local
    spec:
      storageClassName: manual
      capacity:
        storage: 1Gi
      accessModes:
        - ReadWriteMany
      nfs:
        server: 172.42.42.1
        path: "/srv/nfs/kube"
$ cat 4-pvc-nfs.yaml
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: pvc-nfs-pv1
    spec:
      storageClassName: manual
      accessModes:
        - ReadWriteMany
      resources:
        requests:
          storage: 500Mi
$ cat 4-nfs-nginx.yaml
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
          - name: www
            persistentVolumeClaim:
              claimName: pvc-nfs-pv1
          containers:
          - image: nginx
            name: nginx
            volumeMounts:
            - name: www
              mountPath: /usr/share/nginx/html
$ kubectl create -f 4-pv-nfs.yaml
$ kubectl create -f 4-pvc-nfs.yaml
$ kubectl create -f 4-nfs-nginx.yaml
$
$ kubectl delete -f 4-nfs-nginx.yaml
$ kubectl delete -f 4-pvc-nfs.yaml
$ kubectl delete -f 4-pv-nfs.yaml
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
