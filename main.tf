# main.tf
/*
This Terraform configuration file creates an AWS EC2 instance and an S3 bucket with ownership controls.

The EC2 instance is created with the following specifications:
- VPC ID: vpc-095a1ee516e12f7ba
- AWS REGION: eu-2-west
- AMI ID: ami-0505148b3591e4c07
- Instance type: t2.micro
- Subnet ID: subnet-0394725cdbfd85d65 
- Tags: Name = "UbuntuServerS3"
- key_name = "cpdevopsew-eu-west-2"
The S3 bucket is created with the following specifications:
- Bucket name: "vegasterraforms3"
*/


resource "aws_security_group" "my_sg" {
  name        = "ubuntu_server_sg"
  description = "Allow SSH, HTTP, and HTTPS"
  vpc_id      = "vpc-095a1ee516e12f7ba"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "vegasterraforms3"
  acl    = "private"
}

resource "aws_s3_bucket_object" "index_html" {
  bucket       = aws_s3_bucket.my_bucket.id
  key          = "index.html"
  content      = <<EOF
<html>
<head><title>Welcome</title></head>
<body><h1>Welcome to Vegas Terraform S3!</h1></body>
</html>
EOF
  content_type = "text/html"
}

resource "aws_iam_role" "ec2_s3_access" {
  name = "ec2_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
      },
    ]
  })
}

resource "aws_iam_policy" "s3_read_policy" {
  name        = "s3_read_policy"
  description = "A policy that allows read access to a specific S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Effect = "Allow",
        Resource = [
          "${aws_s3_bucket.my_bucket.arn}",
          "${aws_s3_bucket.my_bucket.arn}/*"
        ],
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_read_policy" {
  role       = aws_iam_role.ec2_s3_access.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}

resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "ec2_s3_profile"
  role = aws_iam_role.ec2_s3_access.name
}

resource "aws_instance" "ubuntu_server" {
  ami                    = "ami-0505148b3591e4c07"
  instance_type          = "t2.micro"
  subnet_id              = "subnet-0394725cdbfd85d65"
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_s3_profile.name
  key_name               = "cpdevopsew-eu-west-2"

  tags = {
    Name = "UbuntuServerS3"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y apache2
              sudo systemctl start apache2
              sudo systemctl enable apache2
              
              # Install AWS CLI
              sudo apt install -y awscli
              
              # Try to copy the file with a retry mechanism
              for i in {1..5}; do
                  aws s3 cp s3://${aws_s3_bucket.my_bucket.bucket}/index.html /var/www/html/index.html && break || sleep 10
              done
              EOF
}

output "ec2_instance_ip" {
  value = aws_instance.ubuntu_server.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.my_bucket.bucket
}







