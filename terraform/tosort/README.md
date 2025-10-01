## ⚙️ Terraform Commands Overview

### terraform plan

- **Purpose:** Previews the changes Terraform *would* make without applying them.  
- **Output Example:**  
  Plan: 1 to add, 0 to change, 0 to destroy  
- **Key Point:**  
  Non-destructive — it **does not** modify your infrastructure.  
  Use it to review and confirm changes before applying.

---

### terraform apply

- **Purpose:** Executes the plan — **creates, updates, or deletes** resources based on your configuration.  
- **Usage:**  
  terraform apply  
- **Key Point:**  
  Destructive — it **does** modify your infrastructure.  
- **Tip:**  
  Always review the plan summary carefully before typing “yes” to confirm.

---

### terraform destroy

- **Purpose:** Removes **all** infrastructure defined in your Terraform configuration.  
- **Usage:**  
  terraform destroy  
- **Key Point:**  
  Destructive — it **does** modify your infrastructure.  
- **Warning:**  
  This action is **irreversible** — it permanently deletes all managed resources.

---

### Manual vs Terraform Management

- Avoid switching between manual AWS Console changes and Terraform management.  
- Doing so can cause **drift** — where real infrastructure no longer matches your Terraform state.  
- Always update and apply changes through Terraform for consistency and accuracy.

---

## 🔐 Security Groups in Terraform

### Removing All Ingress and Egress Rules

The `ingress` and `egress` arguments are processed in **attributes-as-blocks** mode.  
Because of this, simply deleting these arguments from your configuration will **not** automatically remove existing rules.

To remove all default managed ingress and egress rules and start with a blank security group:

```bash
resource "aws_security_group" "example" {
  name   = "sg"
  vpc_id = aws_vpc.example.id

  ingress = []
  egress  = []
}
```

This clears all default rules, allowing you to define your own explicitly.

### Protocols

- `protocol = "tcp"` → allows TCP traffic (used for SSH, HTTP, etc.)  
- `protocol = "-1"` → allows **all** protocols (used for full outbound access)

### Creating Rules Manually (AWS Console)

The **Type** dropdown in the AWS Console is a shortcut — it automatically fills in the protocol and port range for you.

| Type (Console) | Protocol | Port | Equivalent in Terraform |
|----------------|-----------|------|--------------------------|
| SSH | TCP | 22 | `protocol = "tcp"`, `from_port = 22`, `to_port = 22` |
| HTTP | TCP | 80 | `protocol = "tcp"`, `from_port = 80`, `to_port = 80` |
| Custom TCP | TCP | Custom | `protocol = "tcp"`, `from_port = <port>`, `to_port = <port>` |

Terraform doesn’t use a `type` field — you must define each protocol and port range explicitly.






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

  # Allow SSH from personal IP only
  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.personal_ip]
  }

  # Allow port 3000 from anywhere
  ingress {
    description = "Allow 3000 from all"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow port 80 (HTTP) from anywhere
  ingress {
    description = "Allow 80 from all"
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
}