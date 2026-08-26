output "web_eip" {
  description = "Điền vào ansible/inventory.ini + DNS A record (@, www, api → IP này)."
  value       = aws_eip.node.public_ip
}

output "rds_endpoint" {
  description = "1 endpoint cho CẢ 4 service — điền vào DB_HOST + migration.dbHost trên branch aws-deploy."
  value       = aws_db_instance.main.address
}

output "s3_bucket" {
  description = "Điền vào STORAGE_BUCKET_NAME trong helm values."
  value       = aws_s3_bucket.data.bucket
}

output "jenkins_url" {
  value = "http://${aws_eip.node.public_ip}:8080 (mật khẩu: Ansible tự in, hoặc /var/lib/jenkins/secrets/initialAdminPassword)"
}

output "app_url" {
  value = "https://${var.domain} (sau khi trỏ DNS về EIP + Let's Encrypt cấp cert)"
}

output "ssh_hint" {
  value = "ssh -i ~/.ssh/uav-lab ec2-user@${aws_eip.node.public_ip}"
}

output "ansible_inventory_line" {
  value = "uav-k3s ansible_host=${aws_eip.node.public_ip}"
}

output "create_app_secret_cmd" {
  description = "Chạy 1 lần, thay giá trị thật (jwt tự sinh: openssl rand -base64 32; PayOS lấy từ dashboard)."
  value       = <<-EOT
    aws secretsmanager create-secret --region ${var.region} --name uav-store/app --secret-string '{
      "jwt-secret": "<openssl rand -base64 32>",
      "payos-client-id": "<tu PayOS dashboard>",
      "payos-api-key": "<tu PayOS dashboard>",
      "payos-checksum-key": "<tu PayOS dashboard>"
    }'
  EOT
}
