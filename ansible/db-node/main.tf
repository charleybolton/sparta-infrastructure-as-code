# In this folder, create Terraform code to create an Ansible 'target node' instance (will run the DB eventually):

provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "ansible_target_node_db" {

  ami = var.default_ami

  instance_type = var.instance_type

  key_name = var.key_name

  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.allow_22_27017.id]

  tags = {
    Name = var.target_node_db_name
  }
}

# --------------------------------------------------------

data "external" "personal_ip" {
  program = ["bash", "-c", "curl -s 'https://api.ipify.org?format=json'"]
}

# --------------------------------------------------------


resource "aws_security_group" "allow_22_27017" {
  name        = var.node_db_sg_name
  description = "Allow SSH (22) from personal IP; allow 27017 from all"
}

resource "aws_security_group_rule" "controller_allow_22_personal_ip" {
  type              = "ingress"
  description       = "SSH from personal IP only"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${data.external.personal_ip.result.ip}/32"]
  security_group_id = aws_security_group.allow_22_27017.id
}

resource "aws_security_group_rule" "db_allow_27017_all" {
  type              = "ingress"
  description       = "Allow 27017 from all"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  cidr_blocks       = [var.cidr_block_open]
  security_group_id = aws_security_group.allow_22_27017.id
}

resource "aws_security_group_rule" "db_allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.cidr_block_open]
  security_group_id = aws_security_group.allow_22_27017.id
}