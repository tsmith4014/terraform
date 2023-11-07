# EC2 Ubuntu Server Setup with Terraform and AWS CLI

Below is a `README.md` file formatted in Markdown, containing the necessary AWS CLI and Terraform commands to set up the specified EC2 Ubuntu server, configure security groups, SSH into the server, install Apache, and serve an HTML file. The Terraform configuration will output the IPv4 address of the instance. Additionally, it includes a bonus step that demonstrates how to display the server's IP address in the static HTML file served by Apache.

````markdown
# EC2 Ubuntu Server Setup with Terraform and AWS CLI

## Prerequisites

- Install [AWS CLI](https://aws.amazon.com/cli/)
- Install [Terraform](https://www.terraform.io/downloads.html)
- Configure AWS CLI with `aws configure`

## Step 1: Create Terraform Configuration

Create a file `main.tf` with the following content:

```hcl
provider "aws" {
  region = "us-east-1" # or your preferred region
}

resource "aws_security_group" "webserver_sg" {
  name        = "webserver-sg"

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

resource "aws_instance" "ubuntu_server" {
  ami                    = "ami-12345678" # Replace with the AMI ID of Ubuntu
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]
  key_name               = "your-key-name" # Replace with your key name

  tags = {
    Name = "UbuntuServer"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install apache2 -y
              echo 'Hello- YOURNAME' > /var/www/html/index.html
              EOF
}

output "public_ip" {
  value = aws_instance.ubuntu_server.public_ip
}
```
````

Replace `ami-12345678` with the actual AMI ID for Ubuntu and `your-key-name` with the name of your key pair.

## Step 2: Initialize Terraform

```sh
terraform init
```

## Step 3: Apply Terraform Configuration

```sh
terraform apply
```

Confirm the actions by typing `yes` when prompted.

## Step 4: SSH into the Server

Once the Terraform script has successfully run, SSH into the server using the public IP address outputted by Terraform:

```sh
ssh -i /path/to/your-key.pem ubuntu@<public-ip-address>
```

## Step 5: Install Apache (if not using user_data)

In case `user_data` doesn't work, you can manually install Apache by running:

```sh
sudo apt update && sudo apt install apache2 -y
```

## Step 6: Serve HTML File

Create an HTML file:

```sh
echo 'Hello- My name is Chad' | sudo tee /var/www/html/index.html
```

## Step 7: Bonus Step - Show IP Address on the Served Page

Use the following command to append the server's IP address to the HTML file:

```sh
echo "Server IP Address: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)" | sudo tee -a /var/www/html/index.html
```

The Apache server will serve the updated HTML file at your EC2 public IP address.

```

Replace `YOURNAME` with your actual name and `/path/to/your-key.pem` with the path to your SSH key. Make sure that the security group `webserver-sg` allows inbound traffic on ports 22, 80, and 443, and all outbound traffic. After creating this `README.md` file, follow the instructions step by step to set up and access your server.
```
