# Khai báo provider cục bộ
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# Yêu cầu tạo một file text tên là "hello.txt"
resource "local_file" "welcome" {
  filename = "${path.module}/hello.txt"
  content  = "Chào mừng bạn đến với thế giới Terraform!"
}