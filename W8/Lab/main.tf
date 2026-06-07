locals {
  common_tags = merge(
    {
      Project = var.name
    },
    var.tags
  )
}

resource "random_id" "suffix" {
  byte_length = 4
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_s3_bucket" "site" {
  bucket        = "${var.name}-${random_id.suffix.hex}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "site_root" {
  for_each = {
    "index.html" = "${path.module}/index.html"
    "style.css"  = "${path.module}/style.css"
  }

  bucket = aws_s3_bucket.site.id
  key    = "site/${each.key}"
  source = each.value
  etag   = filemd5(each.value)

  content_type = lookup(
    {
      "index.html" = "text/html"
      "style.css"  = "text/css"
    },
    each.key,
    null
  )
}

resource "aws_s3_object" "site_imgs" {
  for_each = fileset(path.module, "imgs/*")

  bucket = aws_s3_bucket.site.id
  key    = "site/${each.value}"
  source = "${path.module}/${each.value}"
  etag   = filemd5("${path.module}/${each.value}")

  # Basic mapping; SVG is enough for this repo's assets
  content_type = "image/svg+xml"
}

resource "aws_iam_role" "ec2" {
  name = "${var.name}-ec2-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "s3_read" {
  name = "${var.name}-s3read"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [aws_s3_bucket.site.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = ["${aws_s3_bucket.site.arn}/*"]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name}-profile-${random_id.suffix.hex}"
  role = aws_iam_role.ec2.name
}

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-${random_id.suffix.hex}"
  description = "ALB security group"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group" "ec2" {
  name        = "${var.name}-ec2-${random_id.suffix.hex}"
  description = "EC2 security group"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "NodePort from ALB"
    from_port       = var.nodeport
    to_port         = var.nodeport
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_lb" "this" {
  name               = substr("${var.name}-${random_id.suffix.hex}", 0, 32)
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids

  tags = local.common_tags
}

resource "aws_lb_target_group" "web" {
  name        = substr("${var.name}-tg-${random_id.suffix.hex}", 0, 32)
  port        = var.nodeport
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    matcher             = "200-399"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    bucket_name = aws_s3_bucket.site.bucket
    nodeport    = var.nodeport
    aws_region  = var.aws_region
  })

  tags = merge(local.common_tags, {
    Name = "${var.name}-ec2"
  })

  depends_on = [
    aws_s3_object.site_root,
    aws_s3_object.site_imgs,
  ]
}

resource "aws_lb_target_group_attachment" "ec2" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.this.id
  port             = var.nodeport
}
