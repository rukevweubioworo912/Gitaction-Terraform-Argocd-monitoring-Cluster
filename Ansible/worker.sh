
#!/bin/bash
# Kubernetes Worker Node Setup Script

set -e

echo "[Step 1] Updating system..."
yum update -y

echo "[Step 2] Installing Docker..."
yum install -y docker
systemctl enable --now docker

echo "[Step 3] Disabling SELinux..."
setenforce 0 || true
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

echo "[Step 4] Adding Kubernetes repo..."
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

echo "[Step 5] Installing Kubernetes components..."
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet

echo "[Step 6] Now paste the kubeadm join command from the master here!"

