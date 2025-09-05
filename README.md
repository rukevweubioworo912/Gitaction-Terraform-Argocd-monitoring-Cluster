### GitOps Deployment on AWS Kubernetes with Terraform, ArgoCD, Prometheus, Grafana, and CloudWatch

### Introduction
This project implements a GitOps workflow to automate the deployment of a Kubernetes cluster on AWS EC2 using Terraform and GitHub Actions. The cluster consists of one master node and two worker nodes, configured using bash scripts. ArgoCD manages application deployments by syncing Kubernetes manifests from a GitHub repository, ensuring consistency across environments. Prometheus and Grafana provide observability into cluster health, resource usage, and application performance, while AWS CloudWatch collects logs from the master node for centralized monitoring.
This setup addresses the challenges of manual Kubernetes management by automating infrastructure provisioning, application deployment, and monitoring, enabling a scalable, reliable, and observable system.
## Problem Statement
- Traditional Kubernetes workflows face several challenges:
- Manual Configuration: Using kubectl for deployments is error-prone and hard to scale.
- Configuration Drift: Environments may diverge without a single source of truth.
- Limited Visibility: Lack of centralized logging and metrics hinders troubleshooting.
- Inefficient Monitoring: Disconnected tools make it difficult to monitor cluster and application health.
## This project solves these issues by
- Using Terraform and GitHub Actions to automate infrastructure provisioning.
- Implementing ArgoCD for continuous deployment from a GitHub repository.
- Integrating CloudWatch for centralized logging.
- Leveraging Prometheus and Grafana for real-time metrics and visualization.

## Objectives
- Automated Infrastructure: Provision a Kubernetes cluster on AWS EC2 using Terraform and GitHub Actions.
- GitOps Workflow: Use ArgoCD to deploy applications automatically from a GitHub repository.
- Centralized Logging: Configure CloudWatch to collect and store logs from the master node.
- Cluster Monitoring: Deploy Prometheus to scrape metrics from nodes and pods.
- Visualization: Use Grafana dashboards to visualize CPU, memory, and application metrics.
- Scalability and Reliability: Ensure the cluster supports multiple applications across worker nodes.

## Project Structure
##Infrastructure:
- AWS EC2: 1 master node
- 2 worker nodes, provisioned via Terraform.
- VPC, subnets, security groups
- IAM roles for CloudWatch integration.
- Kubernetes Cluster:
- master node (control plane).
- 2 worker nodes for running applications.
- Configured using bash scripts with kubeadm.


## CI/CD:
- GitHub Actions automates Terraform provisioning and cluster setup.
- Deployment: ArgoCD on the master node syncs manifests from a GitHub repository.
- Monitoring and Logging
- Prometheus on worker nodes collects metrics.
- Grafana on worker nodes visualizes metrics.
- CloudWatch on the master node collects logs.

![Architecture Diagram](https://github.com/rukevweubioworo912/Gitaction-Terraform-Argocd-monitoring-Cluster/blob/main/Untitled%20Diagram%20(1).jpg)

## Project Setup / Installation Steps
Follow these steps to reproduce the project from scratch. Ensure you have a
- AWS account
- GitHub repository
- necessary tools installed.
### Prerequisites
- AWS Account: With programmatic access (Access Key ID, Secret Access Key).
- Terraform (>= 1.5.0)
- AWS CLI
- kubectl
- Helm
- Git

1. GitHub Repository:
- ensure you  install  and  enabled  secrets configured (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION).
- System Requirements: Linux/macOS/Windows with SSH access.
- Clone the Repository
- git clone https://github.com/rukevweubioworo912/Gitaction-Terraform-Argocd-monitoring-Cluster
- cd Gitaction-Terraform-Argocd-monitoring-Cluster

2. Configure AWS Credentials
- Set up AWS credentials in ~/.aws/credentials or as environment variables:
- export AWS_ACCESS_KEY_ID=<your-access-key>
- export AWS_SECRET_ACCESS_KEY=<your-secret-key>
- export AWS_DEFAULT_REGION=<your-region> # e.g., us-east-1

3. Terraform Infrastructure Setup
- The Terraform configuration in the terraform/ directory provisions the AWS infrastructure (VPC, subnets, security groups, EC2 instances).
- Navigate to the Terraform directory:cd terraform
- Initialize Terraform:terraform init
- Review and customize variables in variables.tf (e.g., region, instance type, AMI ID).

```
Example variables.tf:variable "region" {
  default = "us-east-1"
}
variable "instance_type" {
  default = "t3.medium"
}
variable "ami_id" {
  default = "ami-0c55b159cbfafe1f0" # Update with the latest Amazon Linux 2 AMI
}
```

- Apply the Terraform configuration:terraform apply
- Confirm with yes when prompted. This creates:
- VPC with public/private subnets.
- Security groups allowing ports 22, 6443, 2379-2380, 10250, 30000-32767.
- 1 master EC2 instance and 2 worker EC2 instances.

4. Kubernetes Cluster Setup
- Bash scripts in the scripts/ directory configure the Kubernetes cluster.
- Master Node Setup
- SSH into the master node:ssh -i <key.pem> ec2-user@<master-public-ip>
- Run the master setup script (scripts/master-setup.sh):chmod +x scripts/master-setup.sh
```
Example master-setup.sh:#!/bin/bash
sudo apt update && sudo apt install -y docker.io kubelet kubeadm kubectl
sudo systemctl enable docker && sudo systemctl start docker
sudo swapoff -a
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
Save the kubeadm join command output for worker nodes.
```

4.2 Worker Node Setup
- SSH into each worker node:ssh -i <key.pem> ec2-user@<worker-public-ip>
- Run the worker setup script (scripts/worker-setup.sh):chmod +x scripts/worker-setup.sh
-  ./scripts/worker-setup.sh

```
Example worker-setup.sh:#!/bin/bash
sudo apt update && sudo apt install -y docker.io kubelet kubeadm
sudo systemctl enable docker && sudo systemctl start docker
sudo swapoff -a
# Replace with the kubeadm join command from the master node
sudo kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash>
Verify the cluster:kubectl get nodes
```
4.3 Copy kubeconfig
- Copy the kubeconfig file to your local machine:
- scp -i <key.pem> ec2-user@<master-public-ip>:~/.kube/config ~/.kube/config

5. Deploy CloudWatch for Logging
- CloudWatch is configured on the master node to collect logs.
- SSH into the master node:ssh -i <key.pem> ec2-user@<master-public-ip>
- Install the CloudWatch agent:sudo yum install -y amazon-cloudwatch-agent
- Create a CloudWatch configuration file (cloudwatch/cloudwatch-agent-config.json)
```
{
  "agent": {
    "metrics_collection_interval": 60,
    "logfile": "/var/log/amazon-cloudwatch-agent.log"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/kube-apiserver.log",
            "log_group_name": "kubernetes-master",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
Start the CloudWatch agent:sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/path/to/cloudwatch-agent-config.json -s

```

6. Deploy ArgoCD
- ArgoCD is deployed on the master node for GitOps-based application deployment.
- Create the ArgoCD namespace:kubectl create namespace argocd
- Install ArgoCD:kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
- Access the ArgoCD UI:kubectl port-forward svc/argocd-server -n argocd 8080:443
- Open https://localhost:8080 in your browser.
- Get the initial admin password:kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
- Log in to ArgoCD (default username: admin)
- Configure ArgoCD to sync with your GitHub repository:
- Create an ArgoCD application manifest (argocd-apps/app.yaml)
-
```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: <your-github-repo-url>
    targetRevision: main
    path: kubernetes-manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
Apply the manifest:kubectl apply -f argocd-apps/app.yaml

```
7. Deploy Prometheus and Grafana
- Prometheus and Grafana are deployed on the worker nodes for monitoring.
- Add Helm repositories:helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
- helm repo add grafana https://grafana.github.io/helm-charts
- helm repo update
- Install Prometheus:helm install prometheus prometheus-community/prometheus --namespace monitoring --create-namespace
- Install Grafana:helm install grafana grafana/grafana --namespace monitoring
- Get the Grafana admin password:kubectl get secret grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode
- Access Grafana:kubectl port-forward svc/grafana -n monitoring 3000:80
- Open http://localhost:3000 (default username: admin).
- Configure Prometheus as a data source in Grafana:
- URL: http://prometheus-server.monitoring.svc.cluster.local:80
- Add dashboards for CPU, memory, and pod metrics.

8. Application Deployment
- Applications are deployed to worker nodes via ArgoCD.
- Commit and push manifests to the GitHub repository.
- ArgoCD automatically syncs and deploys the application.
```
Create Kubernetes manifests in your GitHub repository under kubernetes-manifests/ (e.g., a simple Nginx deployment):apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: default
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
  type: NodePort
```
9. GitHub Actions Workflow
- The GitHub Actions workflow automates infrastructure provisioning and cluster setup.
-  The workflow is defined in .github/workflows/deploy.yml.
-  Add AWS secrets to your GitHub repository settings.
-  Push changes to trigger the workflow.
```
Example deploy.yml:
name: Deploy Kubernetes Cluster
on:
  push:
    branches:
      - main
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Set up Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.5.0
    - name: Terraform Init
      run: terraform init
      working-directory: ./terraform
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AWS_DEFAULT_REGION: ${{ secrets.AWS_DEFAULT_REGION }}
    - name: Terraform Apply
      run: terraform apply -auto-approve
      working-directory: ./terraform
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AWS_DEFAULT_REGION: ${{ secrets.AWS_DEFAULT_REGION }}
    - name: Configure Kubernetes
      run: |
        ssh -i <key.pem> ec2-user@<master-ip> 'bash scripts/master-setup.sh'
        ssh -i <key.pem> ec2-user@<worker1-ip> 'bash scripts/worker-setup.sh'
        ssh -i <key.pem> ec2-user@<worker2-ip> 'bash scripts/worker-setup.sh'
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```


10. Monitoring and Logging
- CloudWatch: View logs in the AWS Console under the kubernetes-master log group.
- Prometheus: Scrapes metrics from nodes and pods (accessible at http://prometheus-server.monitoring.svc.cluster.local:80).
- Grafana: Visualize metrics at http://localhost:3000 with dashboards for CPU, memory, and pod health.

