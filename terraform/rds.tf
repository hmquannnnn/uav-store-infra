# 1 RDS PostgreSQL chứa CẢ 4 database (user_db, product_db, order_db, payment_db).
# Gộp instance để tiết kiệm + vì AWS Free plan (account plan mới) giới hạn RDS.
# database-per-service vẫn giữ về LOGIC (mỗi service 1 database riêng) — chỉ chung instance.
# Trade-off nói được khi phỏng vấn: mất cô lập tài nguyên giữa các service.
#
# Terraform chỉ tạo được 1 database lúc provision (user_db). 3 database còn lại do
# Ansible task tag `dbinit` tạo (CREATE DATABASE, idempotent) — aws-lab/ansible/playbook.yml.

resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-db"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id] # RDS đòi >=2 AZ
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg"
  description = "Postgres chi nhan tu node k3s"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Postgres tu EC2 node"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.node.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project}-rds-sg" }
}

resource "random_password" "db" {
  length  = 20
  special = false # tránh ký tự phá vỡ URL/DSN trong migration job
}

resource "aws_db_instance" "main" {
  identifier             = "${var.project}-db"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t4g.micro" # free-tier eligible
  allocated_storage      = 20
  storage_encrypted      = true
  db_name                = "user_db" # 3 database còn lại: Ansible --tags dbinit
  username               = "postgres"
  password               = random_password.db.result
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az               = false

  # Paid plan (đã upgrade 26/08): retention 7 ngày → automated backup + PITR.
  backup_retention_period = 7
  skip_final_snapshot     = true
  apply_immediately       = true
}
