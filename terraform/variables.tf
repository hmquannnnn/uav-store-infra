variable "region" {
  description = "AWS region (Singapore)."
  type        = string
  default     = "ap-southeast-1"
}

variable "project" {
  description = "Prefix cho tên resource + tag."
  type        = string
  default     = "uav-store"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "my_ip" {
  description = "IP public của bạn dạng x.x.x.x/32 (SSH 22 + Jenkins 8080). Lấy: curl -4 ifconfig.me"
  type        = string
  # bắt buộc điền qua terraform.tfvars
}

variable "instance_type" {
  description = <<-EOT
    EC2 chạy k3s + Jenkins native. t3.large (8GB) là mức an toàn cho full stack.
    ⚠️ AWS FREE PLAN (account plan mới) CHẶN mọi type ngoài free-tier (t3.micro...) —
    muốn dùng t3.large phải upgrade account lên Paid plan (Billing console; credit
    khuyến mãi vẫn được trừ vào bill). t3.micro 1GB KHÔNG đủ chạy stack này.
  EOT
  type        = string
  default     = "t3.large"
}

variable "ssh_public_key_path" {
  description = "Public key cho Ansible SSH. Tạo: ssh-keygen -t ed25519 -f ~/.ssh/uav-lab"
  type        = string
  default     = "~/.ssh/uav-lab.pub"
}

variable "domain" {
  description = "Domain chính của app (dùng cho CORS S3)."
  type        = string
  default     = "uav-store.io.vn"
}
