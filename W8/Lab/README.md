# K8s on AWS — Terraform 1-Click (EC2 + Minikube + ALB)

Mục tiêu: 1 lệnh Terraform sẽ dựng **1 EC2**, bật **minikube** trong EC2, deploy **app tĩnh** (dùng `index.html/style.css/imgs` trong repo), và **expose ra AWS ALB**.

## Yêu cầu
- AWS credentials đã cấu hình (ví dụ: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, hoặc AWS profile)
- Terraform `>= 1.5`

## Chạy (1-click)
```bash
terraform init
terraform apply -auto-approve
```

Terraform sẽ output:
- `alb_url`: URL public của ALB (mở trên browser)

## Dọn hạ tầng
```bash
terraform destroy -auto-approve
```

## Kiến trúc (tóm tắt)
- Terraform tạo S3 bucket để upload asset web từ repo
- EC2 bootstrap bằng `user_data`: cài docker + kubectl + minikube, tải asset từ S3, build image nginx, deploy vào K8s
- App chạy trong K8s và expose bằng **NodePort 30080**
- ALB forward HTTP(80) -> EC2:30080

## Tại sao chọn kiến trúc này? (Design Decisions)

Dự án này lựa chọn sự kết hợp giữa **Terraform + S3 + EC2 (Minikube) + ALB** dựa trên các tiêu chí sau:

1. **Minikube trên EC2 vs AWS EKS (Elastic Kubernetes Service)**
   * **Tiết kiệm chi phí:** EKS có chi phí quản lý cluster tối thiểu khoảng $73/tháng (chưa tính worker nodes). Việc chạy Minikube trên 1 instance EC2 (`t3.small`) giúp giảm thiểu chi phí tối đa, cực kỳ phù hợp cho môi trường Lab, Test, Demo hoặc PoC.
   * **Đơn giản hóa hạ tầng:** Việc cài đặt cụm EKS hoàn chỉnh yêu cầu nhiều cấu hình VPC phức tạp, IAM Roles, Node Groups. Chạy Minikube giúp gói gọn toàn bộ cụm K8s chỉ trong 1 node duy nhất, dễ dàng kiểm soát và dọn dẹp.

2. **Truyền tải mã nguồn qua S3 vs Terraform Provisioners (SSH)**
   * **Bảo mật và Tin cậy:** Thay vì sử dụng `remote-exec` bằng SSH keys (yêu cầu mở cổng 22 ra ngoài internet công cộng và dễ gặp lỗi timeout kết nối), dự án đẩy code lên S3 trước.
   * **Cloud-Native:** EC2 sử dụng IAM Instance Profile để xác thực an toàn và kéo code từ S3 về thông qua AWS CLI. Điều này đảm bảo quá trình chạy tự động 100% không phụ thuộc vào SSH key.

3. **Expose ứng dụng qua NodePort + ALB**
   * **Bảo mật mạng:** EC2 Instance nằm sau ALB và chỉ mở duy nhất cổng `30080` (NodePort) cho địa chỉ IP của ALB. Người dùng cuối không thể truy cập trực tiếp vào EC2, giảm thiểu bề mặt tấn công mạng.
   * **Khả năng mở rộng:** Cấu hình ALB phía trước giúp dễ dàng bổ sung HTTPS (SSL/TLS), cấu hình Web Application Firewall (WAF) hoặc mở rộng thêm nhiều EC2 nodes sau này mà không thay đổi URL truy cập của người dùng.

## Providers
- `hashicorp/aws`: dựng hạ tầng AWS
- `hashicorp/random`: tạo suffix tránh trùng tên bucket/resource
