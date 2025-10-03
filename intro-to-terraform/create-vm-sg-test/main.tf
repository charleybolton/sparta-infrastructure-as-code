# Cloud provider name (provider block)

provider "aws" {
  # Where to create - which region
  region = var.aws_region
}

# On terraform init, terraform creates a hidden terraform folder. At this point it contains the providers.

# --------------------------------------------------------

# Create the VPC

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = var.vpc_name
  }
}

# --------------------------------------------------------

# Create the subnets

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.availability_zone_1
  cidr_block              = var.cidr_block_public
  map_public_ip_on_launch = var.auto_assign

  tags = {
    Name = var.pub_subnet_name
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  availability_zone = var.availability_zone_2
  cidr_block        = var.cidr_block_private

  tags = {
    Name = var.priv_subnet_name
  }
}

# --------------------------------------------------------

# Create the intenet gateway

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.ig_name
  }
}

# --------------------------------------------------------

# Create the route table

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  # No need for default local route or can cause duplicate issues

  route {
    cidr_block = var.cidr_block_open
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = var.rt_name
  }
}

# --------------------------------------------------------

# Associate the public subnet with the route table

resource "aws_route_table_association" "subnet_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# --------------------------------------------------------

# Specify resource to create an ec2 instance (resource block)

# Create the db ec2 instance

resource "aws_instance" "db_instance" {

  # AMI ID
  ami = var.db_ami_id

  # Type of instance
  instance_type = var.instance_type

  # Set Subnet to the private subnet
  subnet_id = aws_subnet.private_subnet.id

  # Attach the key to be used with EC2 instance
  key_name = var.key_name

  # Specify the security group 
  vpc_security_group_ids = [aws_security_group.allow_22_27017.id]

  # Name of the instance
  tags = {
    Name = var.db_name
  }
}

# --------------------------------------------------------

# Create the app ec2 instance

resource "aws_instance" "app_instance" {

  depends_on = [aws_instance.db_instance]

  ami = var.app_ami_id

  instance_type = var.instance_type

  subnet_id = aws_subnet.public_subnet.id

  key_name = var.key_name

  vpc_security_group_ids = [aws_security_group.allow_22_3000_80.id]

  user_data = templatefile(var.user_data_path, {
    db_ip = aws_instance.db_instance.private_ip
  })

  tags = {
    Name = var.app_name
  }
}

# --------------------------------------------------------

# Retrieve local IP address

data "external" "personal_ip" {
  program = ["bash", "-c", "curl -s 'https://api.ipify.org?format=json'"]
}

# --------------------------------------------------------

# DB security Group

resource "aws_security_group" "allow_22_27017" {
  name        = var.db_sg_name
  description = "Allow SSH (22) from personal IP; allow 27017 from all"
  vpc_id      = aws_vpc.main.id
}

# Allow SSH from app only
resource "aws_security_group_rule" "db_allow_ssh_jumpbox" {
  type              = "ingress"
  description       = "SSH from app only"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.cidr_block_public]
  security_group_id = aws_security_group.allow_22_27017.id
}

# Allow port 27017 from anywhere
resource "aws_security_group_rule" "db_allow_27017_all" {
  type              = "ingress"
  description       = "Allow 27017 from all"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  cidr_blocks       = [var.cidr_block_public]
  security_group_id = aws_security_group.allow_22_27017.id
}

# Allow all outbound traffic
resource "aws_security_group_rule" "db_allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.cidr_block_open]
  security_group_id = aws_security_group.allow_22_27017.id
}

# --------------------------------------------------------

# App security Group

resource "aws_security_group" "allow_22_3000_80" {
  name        = var.app_sg_name
  description = "Allow SSH (22) from personal IP; allow 3000 and 80 from all"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group_rule" "app_allow_ssh_personal_ip" {
  type              = "ingress"
  description       = "SSH from my IP only"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${data.external.personal_ip.result.ip}/32"]
  security_group_id = aws_security_group.allow_22_3000_80.id
}

resource "aws_security_group_rule" "app_allow_3000_all" {
  type              = "ingress"
  description       = "Allow 3000 from all"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = [var.cidr_block_open]
  security_group_id = aws_security_group.allow_22_3000_80.id
}

resource "aws_security_group_rule" "app_allow_80_all" {
  type              = "ingress"
  description       = "Allow 80 from all"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.cidr_block_open]
  security_group_id = aws_security_group.allow_22_3000_80.id
}

resource "aws_security_group_rule" "app_allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.cidr_block_open]
  security_group_id = aws_security_group.allow_22_3000_80.id
}