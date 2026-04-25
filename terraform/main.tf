# ════════════════════════════════════════════
# DEVOPS PIPELINE - AWS INFRASTRUCTURE
# Built with Terraform by John Jonah
# ════════════════════════════════════════════

# ── Data Sources ─────────────────────────────
# Fetch available AZs in our region
data "aws_availability_zones" "available" {
  state = "available"
}

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── VPC ──────────────────────────────────────
# Virtual Private Cloud = your private network on AWS
# Like having your own isolated data center
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ── Internet Gateway ─────────────────────────
# Connects your VPC to the internet
# Without this, nothing can reach the outside world
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ── Public Subnet ────────────────────────────
# A subnet is a segment of the VPC network
# Public subnet = resources here can reach internet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true  # EC2s get public IPs automatically

  tags = {
    Name = "${var.project_name}-public-subnet"
    Type = "public"
  }
}

# ── Route Table ──────────────────────────────
# Rules for routing network traffic
# This route sends all internet traffic to the IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"          # All traffic
    gateway_id = aws_internet_gateway.main.id  # Goes to IGW
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ── Security Group ───────────────────────────
# Firewall rules for your EC2 instance
# Whitelist what traffic is allowed IN and OUT
resource "aws_security_group" "app_server" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for app server"
  vpc_id      = aws_vpc.main.id

  # Allow SSH only from YOUR IP
  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.your_ip}/32"]
  }

  # Allow HTTP from anywhere
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS from anywhere
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow app port
  ingress {
    description = "App port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ALL outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

# ── SSH Key Pair ─────────────────────────────
# Generate SSH key to connect to EC2
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.main.public_key_openssh

  tags = {
    Name = "${var.project_name}-key"
  }
}

# Save private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.main.private_key_pem
  filename        = "${path.module}/devops-key.pem"
  file_permission = "0600"
}

# ── EC2 Instance ─────────────────────────────
# Your actual server on AWS
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app_server.id]
  key_name               = aws_key_pair.main.key_name

  # User data = script that runs when server first boots
  # This installs Docker and runs your app automatically
  user_data = <<-USERDATA
    #!/bin/bash
   

    # Log everything
    exec > /var/log/user-data.log 2>&1

    echo "=== Starting server setup ==="
    echo "Date: $(date)"

    # Update system
    dnf update -y

    # Install Docker
    dnf install -y docker git curl
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user

    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
      -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Run your app from DockerHub
    docker run -d \
      --name devops-app \
      --restart unless-stopped \
      -p 80:80 \
      -e APP_NAME="John's DevOps App on AWS" \
      -e APP_ENV="production" \
      jaybrain/devops-php-app:latest

    echo "=== Setup complete ==="
    echo "App running at: http://$(curl -s ifconfig.me)"
  USERDATA

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-app-server"
    Role = "app-server"
  }
}

# ── Elastic IP ───────────────────────────────
# Static IP that stays the same even if EC2 restarts
resource "aws_eip" "app_server" {
  instance = aws_instance.app_server.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

# ── S3 Bucket ────────────────────────────────
# Object storage - for app assets, logs, backups
resource "aws_s3_bucket" "app_storage" {
  bucket = "${var.project_name}-storage-${var.environment}-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "${var.project_name}-storage"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Block all public access to S3 (security best practice)
resource "aws_s3_bucket_public_access_block" "app_storage" {
  bucket = aws_s3_bucket.app_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning on S3
resource "aws_s3_bucket_versioning" "app_storage" {
  bucket = aws_s3_bucket.app_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Upload a test file to S3
resource "aws_s3_object" "app_config" {
  bucket  = aws_s3_bucket.app_storage.id
  key     = "config/app.conf"
  content = <<-EOT
    APP_NAME=devops-pipeline
    ENVIRONMENT=${var.environment}
    DEPLOYED_BY=terraform
    DEPLOYED_AT=${timestamp()}
  EOT

  tags = {
    Name = "app-config"
  }
}
