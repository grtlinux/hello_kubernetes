#!/bin/bash

# initialize kubernetes
echo "[TASK 1] initialize kubernetes cluster"
kubeadm init --apiserver-advertise-address=172.42.42.100 --pod-network-cidr=192.168.0.0/16 >> /root/kubeinit.log 2>/dev/null

# copy kube admin config
echo "[TASK 2] copy kube admin config to Vagrant user .kube directory"
mkdir /home/vagrant/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

# deploy calio network
echo "[TASK 3] deploy calico network"
su - vagrant -c "kubectl create -f https://docs.projectcalico.org/v3.11/manifests/calico.yaml"

# generate cluster join command
echo "[TASK 4] generate and save cluster join command to /joincluster.sh"
kubeadm token create --print-join-command > /joincluster.sh
