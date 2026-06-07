variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-1"
}

variable "name" {
  description = "Name prefix for resources"
  type        = string
  default     = "k8s-minikube-1click"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "nodeport" {
  description = "Fixed NodePort exposed on the EC2 host (ALB forwards here)"
  type        = number
  default     = 30080
}

variable "tags" {
  description = "Extra tags"
  type        = map(string)
  default     = {}
}
