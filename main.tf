# --- Configure the AWS Provider ---
provider "aws" {
  region = "us-east-1" # Or your preferred region
}

# --- Define the EKS Cluster Itself ---
resource "aws_eks_cluster" "vllm_cluster" {
  name     = "vllm-prod-cluster"
  role_arn = "arn:aws:iam::390888050376:role/EKSClusterRole" # Placeholder - you would create this role  
  vpc_config {
    # You would typically create a VPC or use an existing one
    subnet_ids = ["subnet-01ee801f5cb4e23e6", "subnet-0e2f7509fe36e9b36"] # Placeholder
  }

  # Ensure the cluster version is recent
  version = "1.36"
}


# --- Define the GPU Node Group ---
# This is where we request the g4dn instances.
resource "aws_eks_node_group" "gpu_nodes" {
  cluster_name    = aws_eks_cluster.vllm_cluster.name
  node_group_name = "gpu-worker-nodes"
  node_role_arn   = "arn:aws:iam::390888050376:role/EKSNodeRole" # Placeholder - another IAM role
  subnet_ids      = ["subnet-01ee801f5cb4e23e6", "subnet-0e2f7509fe36e9b36"] # Placeholder - must be same as cluster

  # --- CRITICAL GPU CONFIGURATION ---
  instance_types = ["g4dn.xlarge"] # The exact instance type we need
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = 1 # Start with one GPU node
    max_size     = 2
    min_size     = 1
  
  }
}

  # Ensure the nodes can be reached
  # remote_access

  # Dependency to ensure the cluster is created before the nodes
  #depends_on

