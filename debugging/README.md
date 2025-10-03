# 🐛 Debug Log – Fixing EC2 / Security Group VPC Mismatch

- [🐛 Debug Log – Fixing EC2 / Security Group VPC Mismatch](#-debug-log--fixing-ec2--security-group-vpc-mismatch)
  - [1️⃣ Fixing EC2 / Security Group VPC Mismatch](#1️⃣-fixing-ec2--security-group-vpc-mismatch)

## 1️⃣ Fixing EC2 / Security Group VPC Mismatch

**Error Message**
Error: creating EC2 Instance: operation error EC2: RunInstances, 
https response error StatusCode: 400, RequestID: 2f7118c5-28d1-448b-bf7f-1fc5d7e7a17f, 
api error InvalidParameter: Security group sg-0a04a9472be6f4c71 and subnet subnet-0314db0f0470b807f belong to different networks.

**Diagnosis**
- Terraform was trying to launch an EC2 instance in my **custom VPC**,  
  but the **security group** being attached was created in the **default VPC**.  
- This caused a mismatch error because security groups and subnets must belong to the same VPC.

**Cause**
- The `vpc_id` argument was **missing** from both security group resources:

  resource "aws_security_group" "allow_22_27017" {
    name        = "tech511-charley-tf-allow-port-22-27017"
    description = "Allow SSH (22) from personal IP; allow 27017 from all"
  }

  Without `vpc_id`, Terraform defaults to the **default AWS VPC**.

**Fix**
- Added `vpc_id = aws_vpc.main.id` to both security group resources:

  resource "aws_security_group" "allow_22_27017" {
    name        = "tech511-charley-tf-allow-port-22-27017"
    description = "Allow SSH (22) from personal IP; allow 27017 from all"
    vpc_id      = aws_vpc.main.id
  }

  resource "aws_security_group" "allow_22_3000_80" {
    name        = "tech511-charley-tf-allow-port-22-3000-80"
    description = "Allow SSH (22) from personal IP; allow 3000 and 80 from all"
    vpc_id      = aws_vpc.main.id
  }

**Reapply**
- Recreated both SGs in the correct VPC using:

  terraform apply -replace=aws_security_group.allow_22_27017 -replace=aws_security_group.allow_22_3000_80

✅ **Result**
- Terraform successfully deployed the EC2 instances with matching subnets and security groups.
- Error resolved.