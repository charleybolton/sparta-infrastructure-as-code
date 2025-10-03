# In this folder, create Terraform code to create an Ansible 'target node' instance (will run the app eventually)


provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "ansible_target_node_app" {

  ami = var.default_ami

  instance_type = var.instance_type

  key_name = var.key_name

  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.allow_22_3000_80.id]

  tags = {
    Name = var.target_node_name
  }
}

# --------------------------------------------------------

data "external" "personal_ip" {
  program = ["bash", "-c", "curl -s 'https://api.ipify.org?format=json'"]
}

# --------------------------------------------------------

resource "aws_security_group" "allow_22_3000_80" {
  name        = var.node_app_sg_name
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