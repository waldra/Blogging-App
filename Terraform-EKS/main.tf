# VPC
module "vpc" {
  source             = "./modules/vpc"
  vpc_name           = "EKS-VPC"
  vpc_cidr           = "10.0.0.0/16"
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets     = ["10.0.3.0/24", "10.0.4.0/24"]
  availability_zones = ["eu-west-1a", "eu-west-1b"]
}

# EKS
module "eks" {
  source              = "./modules/eks"
  cluster_name        = "eks-dev"
  cluster_version     = "1.30"
  node_group_name     = "eks-dev-nodegroup"
  ssh_key_name        = "DevOps"
  eks_sg_id           = module.vpc.eks_sg_id
  public_subnets_ids  = module.vpc.public_subnets_ids
  private_subnets_ids = module.vpc.private_subnets_ids
}
