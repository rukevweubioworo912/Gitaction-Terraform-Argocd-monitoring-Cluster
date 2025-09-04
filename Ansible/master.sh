master bsh 
#!/bin/bash
set -e

# Update system packages
yum update -y

# Install Docker
yum install -y docker
systemctl enable --now docker
systemctl start docker

# Set SELinux to permissive
setenforce 0 || true
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Add Kubernetes repo
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

# Install Kubelet, Kubeadm, Kubectl
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet

# Set your control plane private IP here
CONTROL_PLANE_PRIVATE_IP=$(hostname -I | awk '{print $1}')

# Initialize Kubernetes master
kubeadm init --apiserver-advertise-address=${CONTROL_PLANE_PRIVATE_IP} --pod-network-cidr=192.168.0.0/16

# Set up kubeconfig for ec2-user
mkdir -p /home/ec2-user/.kube
cp -i /etc/kubernetes/admin.conf /home/ec2-user/.kube/config
chown ec2-user:ec2-user /home/ec2-user/.kube/config

# Show node status
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl get nodes

# Deploy Calico network plugin
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.29.0/manifests/calico.yaml
kubectl apply -f calico.yaml

echo "Kubernetes master node setup complete."