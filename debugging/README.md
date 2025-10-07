# 🐛 Debug Log – Fixing EC2 / Security Group VPC Mismatch

- [🐛 Debug Log – Fixing EC2 / Security Group VPC Mismatch](#-debug-log--fixing-ec2--security-group-vpc-mismatch)
  - [1️⃣ Fixing EC2 / Security Group VPC Mismatch](#1️⃣-fixing-ec2--security-group-vpc-mismatch)
  - [2️⃣ Fixing SSH Key Permission Error](#2️⃣-fixing-ssh-key-permission-error)
  - [3️⃣ Fixing MongoDB Downgrade Error During Ansible Install](#3️⃣-fixing-mongodb-downgrade-error-during-ansible-install)
  - [4️⃣ Fixing Missing `DB_HOST` Environment Variable in PM2](#4️⃣-fixing-missing-db_host-environment-variable-in-pm2)
  - [5️⃣ Fixing Missing Post Content (Unseeded MongoDB)](#5️⃣-fixing-missing-post-content-unseeded-mongodb)
  - [6️⃣ Cleaning Up Exports with Ansible Environment Variables](#6️⃣-cleaning-up-exports-with-ansible-environment-variables)

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

## 3️⃣ Fixing MongoDB Downgrade Error During Ansible Install

**Error Message**

```bash
TASK [Install MongoDB 7.0] *************************************************************************
fatal: [db-instance]: FAILED! => {"msg": "'/usr/bin/apt-get -y ... install 'mongodb-org=7.0.6'' failed: 
E: Packages were downgraded and -y was used without --allow-downgrades.\n"}
```

**Diagnosis**
Ansible attempted to install a specific MongoDB version (7.0.6).  
The target EC2 instance already had a newer or conflicting version of `mongodb-org` installed.  
APT blocked the operation because downgrading without the `--allow-downgrades` flag is unsafe.

**Cause**
The task explicitly pinned a version number (`mongodb-org=7.0.6`),  
which can cause version mismatches if the repository already provides a newer build.  
When Ansible runs `apt-get install` with `-y`, APT refuses to downgrade without extra flags.

**Fix**
- Allow APT to install the latest available MongoDB 7.0 release by removing the version pin.

Change this task:

```yaml
- name: Install MongoDB 7.0
  ansible.builtin.apt:
    name: mongodb-org=7.0.6
    state: present
```
to

```yaml
- name: Install MongoDB 7.0
  ansible.builtin.apt:
    name: mongodb-org
    state: present
```

**Explanation**
- This tells Ansible to install the **latest version available** from the MongoDB 7.0 repository.  
- Prevents downgrade conflicts and ensures smooth upgrades in future runs.  
- The task remains **idempotent** — Ansible won’t reinstall MongoDB unless a newer version is available.

✅ **Result**
- Ansible completed successfully without downgrade errors.  
- MongoDB installed or updated to the correct 7.0 release.  
- Playbook now runs cleanly across new and existing EC2 instances.

## 4️⃣ Fixing Missing `DB_HOST` Environment Variable in PM2

**Error Message**

```yaml
Use --update-env to update environment variables
[PM2][ERROR] Script already launched, add -f option to force re-execution
```

**Diagnosis**
The Node.js app runs via PM2, but cannot connect to MongoDB.  
PM2 does not automatically retain temporary environment variables set in shell sessions.  
The message above indicates the `DB_HOST` variable was not updated in PM2’s stored environment.

**Cause**
The Ansible task used `export DB_HOST=...` before starting the app.  
This `export` only exists for that one shell process and disappears after the task finishes.  
PM2 continued running the app with its previous (empty) environment, so the app couldn’t find MongoDB.

**Fix**
Replace the original PM2 start command with the following in your Ansible playbook:

```yaml
- name: start app with PM2 using DB_HOST environment variable
  ansible.builtin.shell: |
    export DB_HOST="mongodb://{{ hostvars[groups['db'][0]].ansible_host }}:27017/posts"
    pm2 start app.js --name app -f --update-env
  args:
    chdir: /home/ubuntu/repo/app
  become: false
```

- `-f` forces PM2 to restart the app even if it’s already running.  
- `--update-env` updates the environment variables stored by PM2.  
- The `export` ensures `DB_HOST` is available when PM2 restarts the process.  

**Verification**
Run this command on the web server:

✅ **Result**
- PM2 now correctly loads the DB_HOST variable.
- The app connects to MongoDB successfully, and the posts page loads as expected.
  
## 5️⃣ Fixing Missing Post Content (Unseeded MongoDB)

**Error Message**
No explicit error — the “Posts” page loaded but only displayed the header with no post content.

**Diagnosis**
- The app was connecting to MongoDB successfully (no crash or 500 error).  
- However, the database contained **no documents** in the `posts` collection.  
- The original bash setup automatically seeded data, but the Ansible deployment did not.

**Cause**
- The MongoDB instance was freshly provisioned with no seed data.  
- The seeding step (`node seeds/seed.js`) was never executed during the Ansible run.  
- As a result, the app rendered an empty list.

**Fix**
Added a new task to the web play to run the seeding script automatically:

```yaml
- name: seed MongoDB using app's seed script
  ansible.builtin.shell: |
    export DB_HOST="mongodb://{{ hostvars[groups['db'][0]].ansible_host }}:27017/posts"
    node seeds/seed.js
  args:
    chdir: /home/ubuntu/repo/app
  become: false
```

**Verification**
After redeploying, the “Posts” page now displays seeded posts instead of just the header.

✅ **Result**
- MongoDB is automatically populated during deployment.  
- The app displays full post content on page load.

## 6️⃣ Cleaning Up Exports with Ansible Environment Variables

**Observation**
Originally, both the PM2 and seed tasks exported the `DB_HOST` variable manually using `export DB_HOST=...` in each shell block.

**Diagnosis**
- Each `shell` task runs in its own environment, so exports don’t persist between tasks.  
- Repeating `export` is functional but verbose and not best practice.

**Fix**
Refactored both tasks to use the `environment:` key instead of inline exports:

```yaml
- name: start app with PM2 using DB_HOST environment variable
  ansible.builtin.shell: pm2 start app.js --name app -f --update-env
  args:
    chdir: /home/ubuntu/repo/app
  environment:
    DB_HOST: "mongodb://{{ hostvars[groups['db'][0]].ansible_host }}:27017/posts"
  become: false

- name: seed MongoDB using app's seed script
  ansible.builtin.shell: node seeds/seed.js
  args:
    chdir: /home/ubuntu/repo/app
  environment:
    DB_HOST: "mongodb://{{ hostvars[groups['db'][0]].ansible_host }}:27017/posts"
  become: false
```

**Verification**
- Both tasks successfully connect to the MongoDB instance.  
- The playbook is cleaner, more readable, and aligns with Ansible best practices.

✅ **Result**
- Environment variables are handled properly without redundant exports.  
- Deployment remains fully automated and idempotent.
