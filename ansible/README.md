
# 🤖 Intro to Ansible

- [🤖 Intro to Ansible](#-intro-to-ansible)
  - [❓ What is Ansible](#-what-is-ansible)
  - [⚙️ How Does it Work?](#️-how-does-it-work)
  - [🖥️ Control Node vs Target Nodes](#️-control-node-vs-target-nodes)
  - [🧰 Setup \& Installation (Controller)](#-setup--installation-controller)
  - [🔑 Prepare SSH Access (Controller)](#-prepare-ssh-access-controller)
  - [📂 Inventory (Hosts) Setup](#-inventory-hosts-setup)
  - [✅ Test Connectivity](#-test-connectivity)

## ❓ What is Ansible
- A configuration management tool  
- Red Hat leads development  
- Open-source  
- Written in Python  
- Started with a few core modules that managed Linux servers  
- Works with almost any system:
  - Linux & Windows servers  
  - Routers and switches  
  - Cloud services  

## ⚙️ How Does it Work?
- Recipe (code)  
- Ansible (robot) follows the recipe  
- Recipes (the actions/tasks/instructions) are written in YAML called “playbooks”  
- Ansible control node tells the target nodes what to do  
- Agentless:
  - No need to install Ansible on target nodes  
  - Uses SSH to access target nodes + requires a Python interpreter on target nodes  

## 🖥️ Control Node vs Target Nodes

**Control Node**  
- This is the machine where **Ansible is installed** and from which you execute commands or playbooks.  
- It’s responsible for connecting to all the target nodes via SSH and sending configuration instructions.  
- Examples: your **local laptop**, a **dedicated management server**, or a **controller VM** in the cloud.

**Target Nodes (Managed Hosts)**  
- These are the **machines you want to configure or manage** — for example:  
  - A web server (e.g. NGINX or Apache)  
  - A database server (e.g. PostgreSQL or MySQL)  
  - A load balancer, cache, or any other infrastructure component  
- They don’t need Ansible installed — only **SSH access** and **Python**.

![Diagram Demonstrating How the Control and Target Nodes Connect](../images/how-ansible-works.png)

On the **Controller Node**, there are two important components:
1. **Playbooks** — YAML files that define what tasks Ansible should perform (like “install nginx” or “create a user”).  
2. **Inventory (hosts)** — a file listing all the target nodes and their connection details (IP addresses, usernames, and SSH keys).  
   - Found at `/etc/ansible/hosts` by default.  
   - You can group hosts (e.g. `[web_servers]`, `[databases]`) for easier management.  

You’ll also need:  
- A **private SSH key** that matches the **public key** stored on each target node.  
- SSH access must be **allowed from the controller** to the target nodes (via their security groups or firewall rules).  

## 🧰 Setup & Installation (Controller)
1. `sudo apt update`  
2. `sudo apt upgrade`  
3. `sudo apt-add-repository ppa:ansible/ansible`  
4. Update again: `sudo apt update`  
5. `sudo apt install ansible -y`  
6. Verify: `ansible --version`  
   - Example output snippet: `ansible [core 2.17.14]`  
   - Config file path example: `config file = /etc/ansible/ansible.cfg`

## 🔑 Prepare SSH Access (Controller)
1. `cd home`  
2. `sudo mkdir .ssh`  
3. `sudo nano tech511-charley-aws.pem` (copy over key)  
4. `sudo chmod 400 tech511-charley-aws.pem`

## 📂 Inventory (Hosts) Setup
1. `cd /etc/ansible`  
2. `sudo nano hosts`  
3. Add host entries (examples): 
   - `ec2-instance ansible_host=<app public IP> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/tech241.pem`

## ✅ Test Connectivity
1. `ansible all -m ping`

