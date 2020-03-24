[![Build Status](https://travis-ci.org/nginxinc/kubernetes-ingress.svg?branch=master)](https://travis-ci.org/nginxinc/kubernetes-ingress)  [![FOSSA Status](https://app.fossa.io/api/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress.svg?type=shield)](https://app.fossa.io/projects/custom%2B1062%2Fgithub.com%2Fnginxinc%2Fkubernetes-ingress?ref=badge_shield)  [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)  [![Go Report Card](https://goreportcard.com/badge/github.com/nginxinc/kubernetes-ingress)](https://goreportcard.com/report/github.com/nginxinc/kubernetes-ingress)

# Ep11. Jobs & Cronjobs in Kubernetes Cluster

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
$ cd hello_kubernetes/Season01/Ep11/run0
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
## Job
- Default run
- Killing pod restarts pod
- Completions
- Parallelism
- Backofflimit
- ActionDeadlineSeconds

#### Deault run
```
$ watch -x kubectl get all
$ cat 2-job.yaml
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: helloworld
    spec:
      template:
        spec:
          containers:
            - name: busybox
              image: busybox
              command: ["echo", "Hello Kubernetes by Job. !!!"]
              # command: ["sleep", "60"]
          restartPolicy: Never
$ kubectl create -f 2-job.yaml
$ kubectl logs helloworld-xxxx
$ kubectl describe job helloworld
$ kubectl delete job hellowlrld
```

#### Killing pod restarts pod
```
$ cat 2-job.yaml
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: helloworld
    spec:
      template:
        spec:
          containers:
            - name: busybox
              image: busybox
              # command: ["echo", "Hello Kubernetes by Job. !!!"]
              command: ["sleep", "60"]
          restartPolicy: Never
$ kubectl create -f 2-job.yaml
$ kubectl delete pod helloworld-xxxx
$ kubectl delete job hellowlrld
```

#### Completions
```
$ cat 2-job.yaml
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: helloworld
    spec:
      complitions: 2
      template:
        spec:
          containers:
            - name: busybox
              image: busybox
              command: ["echo", "Hello Kubernetes by Job. !!!"]
              # command: ["sleep", "60"]
          restartPolicy: Never
$ kubectl create -f 2-job.yaml
$ kubectl describe job helloworld
$ kubectl delete job hellowlrld
```

#### Parallelism
```
$ cat 2-job.yaml
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: helloworld
    spec:
      complitions: 2
      parallelism: 2
      template:
        spec:
          containers:
            - name: busybox
              image: busybox
              command: ["echo", "Hello Kubernetes by Job. !!!"]
              # command: ["sleep", "60"]
          restartPolicy: Never
$ kubectl create -f 2-job.yaml
$ kubectl describe job helloworld
$ kubectl delete job hellowlrld
```

#### Backofflimit
```
$ cat 2-job.yaml
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: helloworld
    spec:
      template:
        spec:
          containers:
            - name: busybox
              image: busybox
              command: ["ls", "/kiea"]
          restartPolicy: Never
$ kubectl create -f 2-job.yaml
$ kubectl delete job hellowlrld
$ cat 2-job.yaml
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: helloworld
    spec:
      backoffLimit: 2
      template:
        spec:
          containers:
            - name: busybox
              image: busybox
              command: ["ls", "/kiea"]
          restartPolicy: Never
$ kubectl create -f 2-job.yaml
$ kubectl describe job helloworld | less
$ kubectl delete job hellowlrld
```

#### ActionDeadlineSeconds
```
$ cat 2-job.yaml
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: helloworld
    spec:
      activeDeadlineSeconds: 10
      parallelism: 2
      template:
        spec:
          containers:
            - name: busybox
              image: busybox
              command: ["sleep", "60"]
          restartPolicy: Never
$ kubectl create -f 2-job.yaml
$ kubectl describe job helloworld
$ kubectl delete job hellowlrld
```

---
## CronJob
- Default run
- Cron wiki @hourly, @weekly, @monthly
- Deleting cronjobs
- SuccessfulJobsHistoryLimit
- FailedJobsHistoryLimit
- Suspending cron jobs (kubectl apply, patch)
- ConcurrencyPolicy (Allow, Forbid & Replace)
- Idempotency
```
      schedule: "* * * * *"
        # minute (0 - 59)
        # hour (0 - 23)
        # day of month (1 - 31)
        # month (1 - 12)
        # day of week (0 - 6) (Sunday to Saturday)

```

#### Default run
```
$ watch -x kubectl get all
$ cat 2-cronjob.yaml
    apiVersion: batch/v1beta1
    kind: CronJob
    metadata:
      name: helloworld-cron
    spec:
      schedule: "* * * * *"
      jobTemplate:
        spec:
          template:
            spec:
              containers:
              - name: busybox
                image: busybox
                command: ["echo", "Hello Kubernetes by CronJob.!!!"]
              restartPolicy: Never
$ kubectl create -f 2-cronjob.yaml
$ kubectl logs pod helloworld-cron-xxxxx
$ kubectl describe cronjob helloworld-cron
$ kubectl delete cronjob helloworld-cron
```

#### Deleting all pods and cronjobs
```
$ watch -x kubectl get all
$ cat 2-cronjob.yaml
    apiVersion: batch/v1beta1
    kind: CronJob
    metadata:
      name: helloworld-cron
    spec:
      schedule: "* * * * *"
      jobTemplate:
        spec:
          template:
            spec:
              containers:
              - name: busybox
                image: busybox
                command: ["echo", "Hello Kubernetes by CronJob.!!!"]
              restartPolicy: Never
$ kubectl create -f 2-cronjob.yaml
$ kubectl delete pod --all
$ kubectl delete cronjob helloworld-cron
```

#### SuccessfulJobsHistoryLimit and FailedJobsHistoryLimit
```
$ watch -x kubectl get all
$ cat 2-cronjob.yaml
    apiVersion: batch/v1beta1
    kind: CronJob
    metadata:
      name: helloworld-cron
    spec:
      schedule: "* * * * *"
      successfulJobsHistoryLimit: 0     # 2
      failedJobHistoryLimit: 0          # 5
      jobTemplate:
        spec:
          template:
            spec:
              containers:
              - name: busybox
                image: busybox
                command: ["echo", "Hello Kubernetes by CronJob.!!!"]
              restartPolicy: Never
$ kubectl create -f 2-cronjob.yaml
$ kubectl describe cronjob helloworld-cron
$ kubectl delete cronjob helloworld-cron
```

#### Suspending cron jobs (kubectl apply, patch)
```
$ watch -x kubectl get all
$ cat 2-cronjob.yaml
    apiVersion: batch/v1beta1
    kind: CronJob
    metadata:
      name: helloworld-cron
    spec:
      schedule: "* * * * *"
      jobTemplate:
        spec:
          template:
            spec:
              containers:
              - name: busybox
                image: busybox
                command: ["echo", "Hello Kubernetes by CronJob.!!!"]
              restartPolicy: Never
$ kubectl create -f 2-cronjob.yaml
$ cat 2-cronjob.yaml
    apiVersion: batch/v1beta1
    kind: CronJob
    metadata:
      name: helloworld-cron
    spec:
      schedule: "* * * * *"
      suspend: true
      jobTemplate:
        spec:
          template:
            spec:
              containers:
              - name: busybox
                image: busybox
                command: ["echo", "Hello Kubernetes by CronJob.!!!"]
              restartPolicy: Never
$ kubectl create -f 2-cronjob.yaml
$ kubectl apply -f 2-cronjob.yaml
$ kubectl describe cronjob helloworld-cron
$ cat 2-cronjob.yaml
    .....
    suspend: false
    .....
$ kubectl apply -f 2-cronjob.yaml
$ kubectl patch cronjob helloworld-cron -p '{"spec":{"suspend":true}}'
$ kubectl patch cronjob helloworld-cron -p '{"spec":{"suspend":false}}'
$ kubectl delete cronjob helloworld-cron
```

#### ConcurrencyPolicy (Allow, Forbid & Replace)
```
$ watch -x kubectl get all
$ cat 2-cronjob.yaml
    apiVersion: batch/v1beta1
    kind: CronJob
    metadata:
      name: helloworld-cron
    spec:
      schedule: "* * * * *"
      concurrencyPolicy: Allow   # Allow Forbid Replace
      jobTemplate:
        spec:
          template:
            spec:
              containers:
              - name: busybox
                image: busybox
                command: ["echo", "Hello Kubernetes by CronJob.!!!"]
              restartPolicy: Never
$ kubectl create -f 2-cronjob.yaml
$ kubectl describe cronjob helloworld-cron
$ kubectl delete cronjob helloworld-cron
```

#### Idempotency
```
$ watch -x kubectl get all
$ cat 2-cronjob.yaml
    apiVersion: batch/v1beta1
    kind: CronJob
    metadata:
      name: helloworld-cron
    spec:
      schedule: "* * * * *"
      jobTemplate:
        spec:
          template:
            spec:
              containers:
              - name: busybox
                image: busybox
                command: ["echo", "Hello Kubernetes by CronJob.!!!"]
              restartPolicy: Never
$ kubectl create -f 2-cronjob.yaml
$ kubectl describe cronjob helloworld-cron
$ kubectl delete cronjob helloworld-cron
```


---
## Usecases
- MySQL Backup
- Sending Emails
- Any Backups
- Checking out sources periodically


## Deleting Jobs in Kubernetes after completion using feature gate TTLAfterFinished
```
$ ssh root@kmaster
    # cd /etc/kubernetes/manifests
    # cat kube-apiserver.yaml
        ....
        - --authorization-mode=Node,RBAC
        - --feature-gates=TTLAfterFinished=true    # add a line
        ....
    # cat kube-controller-manager.yaml
        ....
        - --bind-address=127.0.0.1
        - --feature-gates=TTLAfterFinished=true    # add a line
        ....
    # logout
$ cat 2-job.yaml
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: helloworld
    spec:
      ttlSecondsAfterFinished: 20
      template:
        spec:
          containers:
            - name: busybox
              image: busybox
              command: ["echo", "Hello workd by Job...."]
          restartPolicy: Never
$ kubectl create -f 2-job.yaml
$ kubectl describe job helloworld
$ kubectl delete job hellowlrld
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
