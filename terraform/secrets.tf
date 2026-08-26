# Secrets Manager — nguồn secret cho ESO (đọc bằng IAM role node).
#
# 1 secret DB duy nhất (4 database chung instance + chung user postgres → chung password).
# ExternalSecret map cả 4 key *-db-password về cùng secret này.
#
# APP secret (uav-store/app: jwt + PayOS): KHÔNG để trong tf — tạo 1 lần bằng CLI,
# lệnh mẫu trong `terraform output create_app_secret_cmd`.

resource "aws_secretsmanager_secret" "db" {
  name = "uav-store/db"

  # destroy là xoá NGAY (mặc định AWS giữ tên 7-30 ngày → apply lại bị trùng tên)
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    host     = aws_db_instance.main.address
    port     = 5432
    username = "postgres"
    password = random_password.db.result
  })
}
