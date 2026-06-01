
# Evidence — Terraform Day-01

Ngày: 2026-06-01

## 1) Kiểm tra phiên bản

```powershell
terraform -version
```

Kết quả (theo terminal của bạn):

```text
Terraform v1.15.5
on windows_amd64
```

## 2) `terraform init` khi thư mục chưa có file `.tf`

```powershell
terraform init
```

Kết quả (theo terminal của bạn):

```text
Terraform initialized in an empty directory!

The directory has no Terraform configuration files. You may begin working
with Terraform immediately by creating Terraform configuration files.
```

Ghi chú: Mục này là kết quả lúc thư mục chưa có `main.tf` (trước khi bạn tạo cấu hình).

## 3) Tạo cấu hình Terraform hiện tại (dùng provider `hashicorp/local`)

File [main.tf](main.tf) hiện tại:

- Khai báo `required_providers` cho `hashicorp/local` (constraint `~> 2.0`)
- Tạo resource `local_file.welcome` để sinh file `hello.txt` trong thư mục module

Ghi chú: lần đầu chạy `terraform init` có thể cần tải provider từ `registry.terraform.io` (nếu máy chưa có sẵn/cached).

## 4) Chạy init/validate/plan/apply

```powershell
terraform fmt
terraform init -input=false
terraform validate
terraform plan -out tfplan
terraform apply -auto-approve tfplan
terraform output
```

Kết quả (theo terminal của bạn):

```text
Initializing provider plugins found in the configuration...
- Reusing previous version of hashicorp/local from the dependency lock file
- Using previously-installed hashicorp/local v2.9.0

Initializing the backend...

Initializing provider plugins found in the state...
- Reusing previous version of hashicorp/local
- Using previously-installed hashicorp/local v2.9.0


Terraform has been successfully initialized!

Success! The configuration is valid.

local_file.welcome: Refreshing state... [id=d9d350f3a5e9311d3f678151e85b459495a4bff4]

No changes. Your infrastructure matches the configuration.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
╷
│ Warning: No outputs found
│ 
│ The state file either has no outputs defined, or all the defined outputs are
│ empty. Please define an output in your configuration with the `output`
│ keyword and run `terraform refresh` for it to become available.
╵
```

Xác nhận file được Terraform quản lý:

- `hello.txt` đang có nội dung:

```text
Chào mừng bạn đến với thế giới Terraform!
```

## 5) Ghi chú sự cố (nếu có)

Trong môi trường bị chặn mạng/không truy cập được `registry.terraform.io`, Terraform sẽ không tải được provider (nếu máy chưa có sẵn). Với cấu hình hiện tại (dùng `hashicorp/local`), bạn cần:

- Đã từng `init` thành công trước đó (provider có sẵn trong cache), hoặc
- Có cơ chế mirror/plugin cache nội bộ.

