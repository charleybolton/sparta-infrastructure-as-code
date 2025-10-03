# Write Terraform code so that:
# If the environment specified is "dev", one app instance is created
# If the environment specified is "prod", two app instances are created


provider "aws" {
  region = var.aws_region
}

locals {
  instance_count = var.environment == "dev" ? 1 : 2
}

resource "aws_instance" "app_instance" {

  ami = var.default_ami

  instance_type = var.instance_type

  key_name = var.key_name

  vpc_security_group_ids = [aws_security_group.allow_22_3000_80.id]

  tags = {
    Name = "${var.app_name}-${var.environment}"
  }
}

# --------------------------------------------------------

data "external" "personal_ip" {
  program = ["bash", "-c", "curl -s 'https://api.ipify.org?format=json'"]
}

# --------------------------------------------------------

resource "aws_security_group" "allow_22_3000_80" {
  name        = "${var.app_sg_name}-${var.environment}"
  description = "Allow SSH (22) from personal IP; allow 3000 and 80 from all"
}

resource "aws_security_group_rule" "app_node_allow_22_personal_ip" {
  type              = "ingress"
  description       = "SSH from my IP only"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${data.external.personal_ip.result.ip}/32"]
  security_group_id = aws_security_group.allow_22_3000_80.id
}

resource "aws_security_group_rule" "app_node_allow_3000_all" {
  type              = "ingress"
  description       = "Allow 3000 from all"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = [var.cidr_block_open]
  security_group_id = aws_security_group.allow_22_3000_80.id
}

resource "aws_security_group_rule" "app_node_allow_80_all" {
  type              = "ingress"
  description       = "Allow 80 from all"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.cidr_block_open]
  security_group_id = aws_security_group.allow_22_3000_80.id
}

resource "aws_security_group_rule" "app_node_allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.cidr_block_open]
  security_group_id = aws_security_group.allow_22_3000_80.id
}