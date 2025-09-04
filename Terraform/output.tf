
output "master_public_ip" {
  description = "Public IP of the master node"
  value       = aws_instance.k8s_master.public_ip
}


output "worker_public_ips" {
  description = "Public IPs of the worker nodes"
  value       = [for w in aws_instance.k8s_worker : w.public_ip]
}


output "kubeadm_join_command" {
  description = "Command to join worker nodes to the master"
  value       = "kubeadm join ${aws_instance.k8s_master.private_ip}:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>"
}

output "ecr_uri" {
  value = aws_ecr_repository.my_ecr_repo.repository_url
}