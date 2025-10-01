# Create an ec2 instance

# Cloud provider name (provider block)

provider "aws" {
  # Where to create - which region
  region = var.aws_region
}

# On terraform init, terraform creates a hidden terraform folder. At this point it contains the providers.

# Specify resource to create an ec2 instance (resource block)

resource "aws_instance" "test_instance" {

  # AMI ID
  ami = var.app_ami_id

  # Type of instance
  instance_type = var.app_instance_type

  # Public ip of this instance
  associate_public_ip_address = var.app_ip

  # Attach the key to be used with EC2 instance
  key_name = var.key_name

  # Specify the security group 
  vpc_security_group_ids = [aws_security_group.allow_22_3000_80.id]

  # Name of the instance
  tags = {
    Name = var.app_name
  }
}

# Security Group
resource "aws_security_group" "allow_22_3000_80" {
  name        = "tech511-charley-tf-allow-port-22-3000-80"
  description = "Allow SSH (22) from personal IP; allow 3000 and 80 from all"
}

# Allow SSH from personal IP only
resource "aws_security_group_rule" "allow_ssh_personal_ip" {
  type              = "ingress"
  description       = "SSH from my IP only"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.personal_ip]
  security_group_id = aws_security_group.allow_22_3000_80.id
}

# Allow port 3000 from anywhere
resource "aws_security_group_rule" "allow_3000_all" {
  type              = "ingress"
  description       = "Allow 3000 from all"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_22_3000_80.id
}

# Allow port 80 from anywhere
resource "aws_security_group_rule" "allow_80_all" {
  type              = "ingress"
  description       = "Allow 80 from all"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_22_3000_80.id
}

# Allow all outbound traffic
resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_22_3000_80.id
}