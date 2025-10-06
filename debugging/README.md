# 🐛 Debug Log – Fixing EC2 / Security Group VPC Mismatch

- [🐛 Debug Log – Fixing EC2 / Security Group VPC Mismatch](#-debug-log--fixing-ec2--security-group-vpc-mismatch)
  - [1️⃣ Fixing EC2 / Security Group VPC Mismatch](#1️⃣-fixing-ec2--security-group-vpc-mismatch)
  - [2️⃣ Fixing SSH Key Permission Error](#2️⃣-fixing-ssh-key-permission-error)

## 1️⃣ Fixing EC2 / Security Group VPC Mismatch

**Error Message**

```bash
Error: creating EC2 Instance: operation error EC2: RunInstances, 
https response error StatusCode: 400, RequestID: 2f7118c5-28d1-448b-bf7f-1fc5d7e7a17f, 
api error InvalidParameter: Security group sg-0a04a9472be6f4c71 and subnet subnet-0314db0f0470b807f belong to different networks.
```

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

## 2️⃣ Fixing SSH Key Permission Error

**Error Message**

```bash
Failed to connect to the host via ssh: Load key "/home/ubuntu/.ssh/tech511-charley-aws.pem": Permission denied
ubuntu@63.35.185.31: Permission denied (publickey).
```

**Diagnosis**
- Ansible or SSH could not read the `.pem` key file.  
- This usually happens when:
  - The file is **owned by root**, not the `ubuntu` user.
  - The permissions are too open (e.g. `644` or `777`).
  - Ansible is being run by a different user than the one who owns the key.

**Cause**
- When files are copied, created with `sudo`, or transferred from another machine, they can end up being owned by the root user instead of ubuntu.
- For security reasons, SSH will refuse to use a private key file that the current user doesn’t own — even if the file is readable.
- Essentially: Only the user who owns the private key can use it for SSH authentication.

To see who owns the .pem file and what its permissions are:

`ls -l /home/ubuntu/.ssh/tech511-charley-aws.pem`

Example output if owned by root (❌ incorrect):

`-r-------- 1 root root 1696 Oct 3  /home/ubuntu/.ssh/tech511-charley-aws.pem`

Expected output if owned by ubuntu (✅ correct):

`-r-------- 1 ubuntu ubuntu 1696 Oct 3  /home/ubuntu/.ssh/tech511-charley-aws.pem`

**Fix**
1. Change file ownership so the correct user (`ubuntu`) owns the key:

```bash
sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/tech511-charley-aws.pem
```
2. Restrict file permissions so only the owner can read it:

```bash
chmod 400 /home/ubuntu/.ssh/tech511-charley-aws.pem
```
3. Verify file ownership and permissions again:

```bash
ls -l /home/ubuntu/.ssh/tech511-charley-aws.pem
```

✅ Result

- SSH and Ansible can now connect successfully using the .pem key.
- The “Permission denied (publickey)” error is resolved.