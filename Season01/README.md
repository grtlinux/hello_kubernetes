
# Hello Kubernetes Season 01

- [Ep00. XXX](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep00/README.md)

- [Ep01. Setup Kubernetes Cluster using kubeadm on CentOS 7](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep01/README.md)
- [Ep02. Setup Kubernetes Cluster with Vagrant](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep02/README.md)
- [Ep03. Kubernetes single node cluster using microk8s](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep03/README.md)
- [Ep04. Single node Kubernetes Cluster with Minikube](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep04/README.md)
- [Ep05. Install Kubernetes Dashboard Web UI](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep05/README.md)
- [Ep06. Running Docker Containers in Kubernetes Cluster](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep06/README.md)
- [Ep07. Kubernetes Pods Replicasets & Deployments](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep07/README.md)
- [Ep08. Kubernetes Namespaces & Contexts](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep08/README.md)
- [Ep09. How to use Node Selector in Kubernetes](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep09/README.md)
- [Ep10. Kubernetes DaemonSets](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep10/README.md)
- [Ep11. Jobs & Cronjobs in Kubernetes Cluster](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep11/README.md)
- [Ep12. Init Containers in Kubernetes Cluster](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep12/README.md)
- [Ep13. Using Persistent Volumes and Claims in Kubernetes Cluster](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep13/README.md)
- [Ep14. Using Secrets in Kubernetes](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep14/README.md)
- [Ep15. Using ConfigMaps in Kubernetes Cluster](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep15/README.md)
- [Ep16. Using Resource Quotas & Limits in Kubernetes Cluster](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep16/README.md)
- [Ep17. Renaming Kubernetes Nodes](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep17/README.md)
- [Ep18. How to setup Rancher to manage your Kubernetes Cluster](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep18/README.md)
- [Ep19. Performing Rolling Updates in Kubernetes](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep19/README.md)
- [Ep20. NFS Persistent Volume in Kubernetes Cluster](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep20/README.md)
- [Ep21. How to use Statefulsets in Kubernetes Cluster](https://github.com/grtlinux/hello_kubernetes/blob/master/Season01/Ep21/README.md)

---

# Install Kubernetes Cluster using kubeadm
Follow this documentation to set up a Kubernetes cluster on __CentOS 7__ Virtual machines.

This documentation guides you in setting up a cluster with one master node and one worker node.

## Assumptions
|Role|FQDN|IP|OS|RAM|CPU|
|----|----|----|----|----|----|
|Master|kmaster.example.com|172.42.42.100|CentOS 7|2G|2|
|Worker|kworker.example.com|172.42.42.101|CentOS 7|1G|1|

## On both Kmaster and Kworker
Perform all the commands as root user unless otherwise specified
### Pre-requisites
##### Update /etc/hosts
So that we can talk to each of the nodes in the cluster
```
cat >>/etc/hosts<<EOF
172.42.42.100 kmaster.example.com kmaster
172.42.42.101 kworker.example.com kworker
EOF
```
##### Install, enable and start docker service
Use the Docker repository to install docker.
> If you use docker from CentOS OS repository, the docker version might be old to work with Kubernetes v1.13.0 and above
```
yum install -y -q yum-utils device-mapper-persistent-data lvm2 > /dev/null 2>&1
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > /dev/null 2>&1
yum install -y -q docker-ce >/dev/null 2>&1

systemctl enable docker
systemctl start docker
```
##### Disable SELinux
```
setenforce 0
sed -i --follow-symlinks 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux
```
##### Disable Firewall
```
systemctl disable firewalld
systemctl stop firewalld
```
##### Disable swap
```
sed -i '/swap/d' /etc/fstab
swapoff -a
```
##### Update sysctl settings for Kubernetes networking
```
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
```
### Kubernetes Setup
##### Add yum repository
```
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
```
##### Install Kubernetes
```
yum install -y kubeadm kubelet kubectl
```
##### Enable and Start kubelet service
```
systemctl enable kubelet
systemctl start kubelet
```
## On kmaster
##### Initialize Kubernetes Cluster
```
kubeadm init --apiserver-advertise-address=172.42.42.100 --pod-network-cidr=192.168.0.0/16
```
##### Copy kube config
To be able to use kubectl command to connect and interact with the cluster, the user needs kube config file.

In my case, the user account is venkatn
```
mkdir /home/venkatn/.kube
cp /etc/kubernetes/admin.conf /home/venkatn/.kube/config
chown -R venkatn:venkatn /home/venkatn/.kube
```
##### Deploy Calico network
This has to be done as the user in the above step (in my case it is __venkatn__)
```
kubectl create -f https://docs.projectcalico.org/v3.11/manifests/calico.yaml
```

##### Cluster join command
```
kubeadm token create --print-join-command
```
## On Kworker
##### Join the cluster
Use the output from __kubeadm token create__ command in previous step from the master server and run here.

## Verifying the cluster
##### Get Nodes status
```
kubectl get nodes
```
##### Get component status
```
kubectl get cs
```

Have Fun!!
