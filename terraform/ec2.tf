# EC2 chạy k3s single-node + Jenkins native. Phần mềm do Ansible cài sau khi apply.

resource "aws_key_pair" "lab" {
  key_name   = "${var.project}-key"
  public_key = file(var.ssh_public_key_path)
}

resource "aws_security_group" "node" {
  name        = "${var.project}-node-sg"
  description = "k3s node: HTTP/HTTPS public; SSH + Jenkins chi tu my_ip"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP (Traefik + Lets Encrypt HTTP-01)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS (Traefik)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH cho Ansible"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    description = "Jenkins UI (native tren host)"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project}-node-sg" }
}

resource "aws_instance" "node" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.node.id]
  iam_instance_profile   = aws_iam_instance_profile.node.name
  key_name               = aws_key_pair.lab.key_name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  # BẮT BUỘC cho pod gọi IMDS (ESO + file/product-service MINIO_AUTH_TYPE=iam):
  # traffic từ pod đi qua bridge container = 2 hop; hop limit mặc định 1 sẽ chặn
  # IMDSv2 → IAM auth trong pod fail âm thầm.
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = { Name = "${var.project}-k3s" }
}

resource "aws_eip" "node" {
  instance   = aws_instance.node.id
  domain     = "vpc"
  tags       = { Name = "${var.project}-eip" }
  depends_on = [aws_internet_gateway.igw]
}
