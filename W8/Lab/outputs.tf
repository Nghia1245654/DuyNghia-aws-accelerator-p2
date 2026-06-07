output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.this.public_ip
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "alb_url" {
  description = "URL to open in browser"
  value       = "http://${aws_lb.this.dns_name}/"
}

output "s3_bucket" {
  description = "S3 bucket that holds the site assets"
  value       = aws_s3_bucket.site.bucket
}
