# ============================================================================
# Hạ tầng AWS cho uav-store — EC2 (k3s) + 4×RDS + S3 + Secrets Manager.
# Độc lập với lab học tập (interview-devops/cloud-engineer/aws-lab) — state riêng.
# Phần mềm trên EC2 do ANSIBLE cài (aws-lab/ansible/playbook.yml), tf này chỉ lo hạ tầng.
# ============================================================================
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
    }
  }
}

data "aws_caller_identity" "me" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
