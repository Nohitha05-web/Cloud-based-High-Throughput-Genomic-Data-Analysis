terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Change if needed
}

# Data source for latest Amazon Linux 2 AMI (dynamic, always latest)
data "aws_ssm_parameter" "amazon_linux_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# S3 Bucket for dataset
resource "aws_s3_bucket" "genomics_data" {
  bucket = "nohitha-genomics-hpc-${random_string.bucket_suffix.result}"  # Unique
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_ownership_controls" "genomics_data" {
  bucket = aws_s3_bucket.genomics_data.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "genomics_data" {
  depends_on = [aws_s3_bucket_ownership_controls.genomics_data]
  bucket     = aws_s3_bucket.genomics_data.id
  acl        = "private"
}

# IAM Role for EC2 to access S3
resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "ec2-s3-policy"
  role = aws_iam_role.ec2_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.genomics_data.arn,
          "${aws_s3_bucket.genomics_data.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "ec2-s3-profile"
  role = aws_iam_role.ec2_s3_role.name

  depends_on = [aws_iam_role_policy.ec2_s3_policy]
}

# EC2 Instance for HPC Analysis
resource "aws_security_group" "genomics_sg" {
  name_prefix = "genomics-hpc-"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["157.51.58.186/32"]  
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "genomics_ec2" {
  ami                    = data.aws_ssm_parameter.amazon_linux_ami.value  # Latest AMI
  instance_type          = "t3.micro"  # Good for high-throughput: 2 vCPU, 8GB RAM
  key_name               = "your-ec2-keypair"  # Create this in AWS Console first (EC2 > Key Pairs)

  vpc_security_group_ids = [aws_security_group.genomics_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_s3_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3 pip3 git
              pip3 install pandas scipy matplotlib seaborn
              EOF

  tags = {
    Name = "Genomics-HPC-Instance"
  }

  depends_on = [aws_iam_instance_profile.ec2_s3_profile]
}

# Output important values
output "s3_bucket_name" {
  value = aws_s3_bucket.genomics_data.bucket
}

output "ec2_public_ip" {
  value = aws_instance.genomics_ec2.public_ip
}

output "latest_ami_id" {
  value     = data.aws_ssm_parameter.amazon_linux_ami.value
  sensitive = true
}
