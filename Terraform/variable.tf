# AWS region
variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

# EC2 instance type for master
variable "master_instance_type" {
  description = "EC2 instance type for the master node"
  type        = string
  default     = "t3.medium"
}

# EC2 instance type for worker
variable "worker_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.small"
}

# SSH key name for EC2 instances
variable "key_name" {
  description = "Name of the SSH key to access EC2 instances"
  type        = string
  default     = "mykeyname"
}



# Number of worker nodes
variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}