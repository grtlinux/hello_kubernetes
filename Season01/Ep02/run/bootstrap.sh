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
echo "kubeadmin" | password --stdin root >/dev/null 2>&1

# update vagrant user's bashrc file
echo "[TASK 13] update vagrant user's bashrc file"
echo "export TERM=xterm" >> /etc/bashrc
