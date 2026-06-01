Infrastructure as Code (IaC) là các công cụ cho phép bạn quản lý hạ tầng bằng file cấu hình thay vì sử dụng giao diện đồ họa. IaC giúp bạn xây dựng, thay đổi và quản lý hạ tầng một cách an toàn, nhất quán và có thể lặp lại bằng cách định nghĩa cấu hình tài nguyên mà bạn có thể version, tái sử dụng và chia sẻ.

Terraform là công cụ Infrastructure as Code của HashiCorp. Nó cho phép bạn định nghĩa tài nguyên và hạ tầng bằng các file cấu hình dạng khai báo (declarative), dễ đọc đối với con người, và quản lý toàn bộ vòng đời của hạ tầng.

Việc sử dụng Terraform có một số lợi ích so với quản lý thủ công:

Terraform có thể quản lý hạ tầng trên nhiều nền tảng cloud khác nhau.
Ngôn ngữ cấu hình dễ đọc giúp bạn viết code hạ tầng nhanh chóng.
Cơ chế state của Terraform cho phép theo dõi các thay đổi tài nguyên trong suốt quá trình triển khai.
Bạn có thể lưu trữ cấu hình trong hệ thống quản lý phiên bản (version control) để cộng tác một cách an toàn.

Quản lý hạ tầng
Terraform dùng providers để kết nối với API của các nền tảng như Amazon Web Services, Microsoft Azure, Google Cloud Platform…
Có hơn 1000 providers, có thể tự viết nếu chưa có.
Tìm providers trong Terraform Registry.
🔹 Chuẩn hóa workflow
Hạ tầng được chia thành resource (VM, network…).
Gom nhiều resource thành module để tái sử dụng.
Dùng ngôn ngữ declarative (mô tả trạng thái mong muốn).
Terraform tự xử lý dependency giữa các resource.
🔹 Quy trình deploy
Scope – Xác định hạ tầng
Author – Viết config
Initialize – Cài plugin
Plan – Xem trước thay đổi
Apply – Áp dụng thay đổi
🔹 Theo dõi hạ tầng
Terraform dùng state file làm “source of truth”.
So sánh state với config để quyết định thay đổi.
🔹 Cộng tác
Dùng remote state để làm việc nhóm.
HCP Terraform hỗ trợ:
Chia sẻ state an toàn
Tránh xung đột khi nhiều người cùng sửa
Tích hợp với VCS như GitHub, GitLab để tự động cập nhật hạ tầng khi commit code.