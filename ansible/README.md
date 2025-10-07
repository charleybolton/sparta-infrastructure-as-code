
# 🤖 Intro to Ansible

- [🤖 Intro to Ansible](#-intro-to-ansible)
  - [❓ What is Ansible](#-what-is-ansible)
  - [⚙️ How Does it Work?](#️-how-does-it-work)
  - [🖥️ Control Node vs Target Nodes](#️-control-node-vs-target-nodes)
  - [🧰 Controller Setup](#-controller-setup)
    - [Installation](#installation)
    - [Prepare SSH Access (Controller)](#prepare-ssh-access-controller)
    - [Inventory (Hosts) Setup](#inventory-hosts-setup)
    - [Test Connectivity](#test-connectivity)
  - [🧠 Idempotence (Bash vs Ansible)](#-idempotence-bash-vs-ansible)
  - [⚡ Ad Hoc Commands](#-ad-hoc-commands)
    - [Using `--become` for Elevated Privileges](#using---become-for-elevated-privileges)
  - [🗂️ Working with Inventories](#️-working-with-inventories)
    - [View Help Information](#view-help-information)
    - [View the Inventory](#view-the-inventory)
  - [✅ Using Modules](#-using-modules)
    - [Why specify `state=present` if modules are already idempotent?](#why-specify-statepresent-if-modules-are-already-idempotent)
  - [🧾 Creating and Running a Playbook](#-creating-and-running-a-playbook)
    - [Testing with Ad Hoc Commands](#testing-with-ad-hoc-commands)
    - [General Structure of a Playbook](#general-structure-of-a-playbook)
  - [🧑‍💻 Deploying the App Using a Playbook](#-deploying-the-app-using-a-playbook)
    - [Difference Between “Run App” and “Run App with PM2” Playbooks](#difference-between-run-app-and-run-app-with-pm2-playbooks)
    - [Why Both Playbooks Are Still Idempotent (Even with Shell Commands)](#why-both-playbooks-are-still-idempotent-even-with-shell-commands)
    - [Why the Playbook Order Differs from the Bash Script](#why-the-playbook-order-differs-from-the-bash-script)
  - [💾 Deploying the App Using a DB](#-deploying-the-app-using-a-db)
    - [Pre-Testing the Database Before Connecting](#pre-testing-the-database-before-connecting)
    - [Why the Database Needs Manual Seeding in the Playbook (vs. Automatic in Bash)](#why-the-database-needs-manual-seeding-in-the-playbook-vs-automatic-in-bash)
  - [🪄 Master Playbooks](#-master-playbooks)

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

## 🧰 Controller Setup

### Installation
1. `sudo apt-get update -y`  
2. `sudo apt upgrade`  
3. `sudo apt-add-repository ppa:ansible/ansible`  
   ➤ Adds the official **Ansible Personal Package Archive (PPA)** to your system, allowing you to install the latest stable version of Ansible instead of the one from Ubuntu’s default repositories. 
4. Update again: `sudo apt update`  
5. `sudo apt install ansible -y`  
   ➤ Installs **Ansible** and all required dependencies (like Python modules) on your control machine.
6. `ansible --version`  
   ➤ Verifies that Ansible was installed correctly and shows version details, Python version, and config file paths.    
   - Example output snippet: `ansible [core 2.17.14]`  
   - Config file path example: `config file = /etc/ansible/ansible.cfg`

### Prepare SSH Access (Controller)
7.  `cd home`  
8.  `sudo mkdir .ssh`  
9.  `sudo nano tech511-charley-aws.pem`  
   ➤ Opens a text editor to paste your **private SSH key** (used for connecting securely to AWS instances).  
10. `sudo chmod 400 tech511-charley-aws.pem`  
   ➤ Restricts permissions so **only the owner** can read the key file — SSH requires this for security compliance.

### Inventory (Hosts) Setup
11.  `cd /etc/ansible`  
12.  `sudo nano hosts`  
   ➤ Opens Ansible’s **inventory file**, where you define all the remote machines Ansible should manage.
13. Write a group name at the top `[web]` and underneath this define the host entry `ec2-instance ansible_host=<app public IP> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/tech511-charley-aws.pem`  
 
   - `ec2-instance` → a custom alias you can use in playbooks or commands. Rename to fit the instance being used e.g. app, db etc.
   - `ansible_host` → the actual IP or hostname of the server  
   - `ansible_user` → the SSH username (e.g., `ubuntu` for AWS Ubuntu AMIs)  
   - `ansible_ssh_private_key_file` → the path to your SSH key used to authenticate

**Parent and Child Groups:**  

A more advanced inventory can define **group relationships**.  

For example:
```bash
[test:children]
web
db

[web]
app-instance ansible_host=172.31.37.223 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/tech511-charley-aws.pem

[db]
```

`[test:children]` creates a **parent group** called `test` that includes the two **child groups** `web` and `db`.

`[web]` and `[db]` define the individual host groups for the web and database servers.

This structure allows Ansible commands or playbooks to target either:

  - Individual groups (e.g. `ansible web -m ping`)  
  - Or the parent group (e.g. `ansible test -m ping`) to run against all child hosts at once.

### Test Connectivity
14. `ansible all -m ping`  
   ➤ Runs the **`ping` module** on all defined hosts to check SSH connectivity and Ansible control.  
   - It doesn’t use ICMP like the normal `ping` command — instead, it connects over SSH and runs a quick Python test to confirm communication.
   - Each host in your inventory should return something like this:

  ```bash
  ec2-instance | SUCCESS => {
      "changed": false,
      "ping": "pong"
  }
  ```

## 🧠 Idempotence (Bash vs Ansible)

- **Idempotent** means you can run something repeatedly and the system ends up in the same **desired state** (no duplicates, no extra changes). 
- Bash is **imperative**—it runs commands exactly as written, so without checks it can duplicate work (e.g. `echo "line" >> file` adds the line every time). Ansible is **declarative**—modules describe the state you want and only change things if needed (e.g. `apt: name=nginx state=present` installs Nginx if missing, otherwise does nothing; `service: name=nginx state=started` starts it only if it isn’t already). That’s why Ansible tasks are idempotent by default, while Bash usually needs manual guards to be idempotent.

## ⚡ Ad Hoc Commands

- **Ad hoc commands** are used for **one-off tasks** — quick, single-line operations that don’t require a full playbook.  
- These are useful for testing connections, updating packages, checking service status, or performing simple administrative actions.  
- ⚠️ **Ad hoc commands themselves are not automatically idempotent** — idempotence depends on the **module** being used (e.g. `apt` is idempotent, but raw shell commands are not).

### Using `--become` for Elevated Privileges

- In Ansible, the `--become` flag allows the command to be executed with **superuser privileges** (similar to using `sudo` in Bash).  
- Example of a non-idempotent ad hoc command:
  
  ```bash
  ansible web -a "apt-get update -y" --become
  ```

- This works but is not recommended — it directly runs a Bash command rather than using Ansible’s built-in modules.
- It lacks idempotence, meaning it will always run regardless of whether updates are needed.


## 🗂️ Working with Inventories

- The **inventory** in Ansible defines which hosts (servers) the controller can manage.  
- It can include groups (e.g. `[web]`, `[database]`) and connection details for each host.

### View Help Information

```bash
ansible --help
```

- Displays a list of all available options, flags, and usage examples for the `ansible` command.  
- Useful for checking syntax or discovering features such as `--become`, `--limit`, or `--module-name`.

### View the Inventory

List format:

```bash
ansible inventory --list
```

- Shows the inventory in JSON format, listing all groups and their associated hosts.
- Useful for verifying that Ansible can correctly read and interpret the inventory file.

Graph format:

```bash
ansible-inventory --graph
```

- Displays the inventory as a tree structure, showing how hosts are grouped.

Example output:

```bash
@all:
  |--@ungrouped:
  |--@web:
  |  |--ec2-instance
```

`@all` includes every host in the inventory.
`@ungrouped` includes any hosts not assigned to a specific group.
`@web` ia a group containing the host ec2-instance.

## ✅ Using Modules

- The **idempotent** way to perform the same action is by using the `apt` module:
  
  ```bash
  ansible web -m apt -a "update_cache=yes" --become
  ```

`-m` specifies the module to use (apt here).

The `apt` module is shorthand for ansible.builtin.apt (Ansible looks in that namespace by default).

- This approach ensures that Ansible checks the current system state and only performs changes when necessary.
<br>
<br>

  Example output:

```bash
ec2-instance | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.10"
    },
    "cache_update_time": 1759744564,
    "cache_updated": true,
    "changed": true
}
```
`CHANGED` means the task successfully updated the cache. If run again without changes required, the output will show "changed": false, demonstrating idempotence.

- Once package information has been updated on the target node, a full system upgrade can be run using the `apt` module.  
- This is still done with an **ad hoc command**, but it remains **idempotent** since the `apt` module checks system state before acting.

```bash
ansible web -m apt -a "upgrade=dist" --become
```

`-m apt` tells Ansible to use the APT module, which manages packages on Debian/Ubuntu systems.

`-a "upgrade=dist"` performs a distribution upgrade, updating all packages to the newest version (similar to sudo apt-get dist-upgrade).

`--become` runs the command with superuser privileges.
<br>
<br>

Example output:

```bash
ec2-instance | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.10"
    },
    "changed": false,.........
```

`"changed": false` means there were **no available upgrades** — the system was already fully up to date. If new packages had been available, the output would show `"changed": true`.  

- Like before, this demonstrates **idempotence** — the command only applies updates when necessary.
- Since this was run using the `apt` module`, it’s considered an **idempotent ad hoc command**.

### Why specify `state=present` if modules are already idempotent?

- **Modules are idempotent**, but they still require a definition of *the desired state* in order to determine what actions to take.  
- Idempotence means *only applying changes when the current system state does not match the desired one.*  
- The parameter `state=present` indicates that the specified package should exist on the system.  
- When executed, the module checks the host to ensure it matches the desired condition:
  - If Nginx **is already installed**, no changes are made → `changed: false`  
  - If Nginx **is not installed**, the module installs it → `changed: true`  

| Parameter | Desired State | Result (Idempotent Action) |
|------------|----------------|-----------------------------|
| `state=present` | Package should be installed | Installs only if missing |
| `state=absent` | Package should be removed | Removes only if present |
| `state=latest` | Package should be updated | Upgrades only if outdated |

🧩 Modules are idempotent *because* they check whether the existing state matches the desired one defined by the parameters. The `state` argument explicitly tells Ansible what condition to verify and enforce.

## 🧾 Creating and Running a Playbook

- A **playbook** is a YAML file that defines one or more tasks for Ansible to perform on specific hosts.  
- Anything that can be done with an **ad hoc command** can also be written as a **task** inside a playbook — and vice versa.

### Testing with Ad Hoc Commands

Before creating a playbook, an ad hoc command can be used to check whether a service (like Nginx) is running:

```bash
ansible web -a "systemctl status nginx" --become

or 

ansible db -a "systemctl status mongod" --become
```

If Nginx is not installed yet, the output may show:

```bash
app-instance | FAILED | rc=4 >>
Unit nginx.service could not be found. non-zero return code
```

This simply means the service does not exist on the target node.

### General Structure of a Playbook

```bash
- name: Name of the play (what this play does)
  hosts: target_hosts_group      # e.g. web, db, all
  gather_facts: yes | no         # whether to collect system info
  become: true | false           # whether to use sudo privileges

  vars:                          # optional — define variables for the play
    variable_name: value

  pre_tasks:                     # optional — tasks that run before main tasks
    - name: Description of pre-task
      module_name:
        option: value

  tasks:                         # main list of tasks to perform
    - name: Description of task 1
      module_name:
        option: value

    - name: Description of task 2
      module_name:
        option: value

  handlers:                      # optional — triggered via "notify" on change
    - name: restart service
      module_name:
        option: value

  post_tasks:                    # optional — tasks that run after main tasks
    - name: Cleanup or final steps
      module_name:
        option: value
```

**name:**  
A short, descriptive title explaining what the play does. Helps identify the play in Ansible’s output.

**hosts:**  
Specifies which group(s) or host(s) the play will run on, as defined in your inventory file. Examples: `web`, `db`, or `all`.

**gather_facts:**  
Determines whether Ansible should collect system information (facts) about the target hosts before running tasks. Useful when tasks depend on system details like OS version or network interfaces.

**become:**  
Indicates if privilege escalation (e.g., `sudo`) should be used for the tasks in this play. Set to `true` when tasks require elevated permissions.

**vars:**  
Defines variables that can be reused throughout the play. Useful for storing configuration values, file paths, or credentials.

**pre_tasks:**  
Tasks that run *before* the main task list. Commonly used to prepare the environment — for example, updating package caches or validating preconditions.

**tasks:**  
The main set of actions that Ansible will execute on the target hosts. Each task uses a module (e.g., `copy`, `service`, `yum`) and runs in order from top to bottom.

**handlers:**  
Special tasks that only run when “notified” by another task. Typically used for actions that should happen after changes — such as restarting a service when a configuration file is updated.

**post_tasks:**  
Tasks that run *after* all main tasks and handlers have completed. Commonly used for cleanup, validation, or reporting steps after the main configuration work is done.

## 🧑‍💻 Deploying the App Using a Playbook

### Difference Between “Run App” and “Run App with PM2” Playbooks

Both playbooks automate installing dependencies and deploying the Node.js application on the web server, but they differ in how the application process runs and is managed.

**“prov-app-with-npm-start.yml”**

- Starts the Node.js app in the foreground using:
  
```bash
  npm start
```
This command runs the app directly inside the SSH session.  

❗ However:  
- The process will hang (block) Ansible until you stop it manually.  
- If the SSH session ends, the app will stop too.  
- It doesn’t automatically restart after reboots or crashes.  

➡️ This is why PM2 is introduced in the next stage — to properly manage the process.

**"prov-app-with-pm2.yml"**

- Uses PM2, a Node.js process manager, to keep the app running continuously in the background.  
- PM2 provides:  
  - Automatic restarts if the app crashes.  
  - Startup configuration to launch on reboot.  
  - Centralised process management (start, stop, restart, logs).  
- This makes it far more reliable and production-ready compared to `npm start`.

### Why Both Playbooks Are Still Idempotent (Even with Shell Commands)

Both **`prov-app-with-npm-start.yml`** and **`prov-app-with-pm2.yml`** are designed to be *idempotent*, meaning they can be safely re-run multiple times without causing unwanted side effects.

Even though each contains a `shell` command, they remain **functionally idempotent** for these reasons:

1. **All system setup tasks use idempotent Ansible modules**  
   - Modules like `apt`, `git`, `npm`, and `get_url` automatically check current state before acting.  
   - For example, if Node.js or Nginx is already installed, the tasks are skipped.

2. **The shell commands are non-destructive**  
   - In the npm version, `npm start` simply runs the app again — it doesn’t overwrite files or system state.  
   - In the PM2 version, the command `pm2 start app.js --name app || pm2 restart app` ensures the app either starts or restarts cleanly without duplication.

3. **Resulting state is consistent**  
   - After each run, the same desired outcome is achieved:
     - App dependencies installed  
     - Repo cloned  
     - App running (via npm or PM2)  
   - So even if Ansible cannot *detect* the change, the system ends up in the same working state.

While `shell` commands aren’t inherently idempotent in Ansible terms, the way these playbooks are written makes their end result idempotent in behaviour — meaning repeated runs will not break or duplicate your app setup.

### Why the Playbook Order Differs from the Bash Script

Ansible and Bash operate differently in how they execute instructions.

A Bash script runs commands in a fixed sequence, while an Ansible playbook defines the *desired end state* of a system.

This difference affects how tasks are ordered.

| Aspect | **Bash Script** | **Ansible Playbook** |
|--------|------------------|----------------------|
| **Execution Type** | Procedural — executes commands line-by-line in exact order | Declarative — ensures each component reaches a defined state |
| **Dependency Handling** | Order must be manually managed (e.g. install before use) | Modules handle dependencies internally (e.g. `apt` updates cache before installing) |
| **System Setup vs. App Setup** | Often combined together | Clearly separated: system configuration first, then application setup |
| **Error Recovery** | If one command fails, execution stops unless handled manually | Ansible halts on failure and reports the failed task |
| **Re-runs (Idempotency)** | Re-running repeats every command | Re-running only changes what is out of sync with the defined state |

In a Bash script, repository cloning typically occurs before installing tools like PM2 because the script executes sequentially.  
In an Ansible playbook, Node.js and PM2 are installed first so that subsequent tasks such as repository cloning and dependency installation can rely on a fully prepared environment.  

This approach follows standard **configuration management best practices**, producing a more **modular, maintainable, and predictable** deployment process.

## 💾 Deploying the App Using a DB

### Pre-Testing the Database Before Connecting

Before linking the web app to MongoDB using the DB_HOST variable, it’s best practice to verify that MongoDB is running correctly and accessible.

1️⃣ Check that MongoDB is active

You can do this using ad hoc Ansible commands:

`ansible db -a "sudo systemctl status mongod" -u ubuntu`

This confirms the MongoDB service is installed, enabled, and running. If MongoDB isn’t active, the output will include a failure message like inactive (dead) or failed.

2️⃣ Check that the bind IP was updated

`ansible db -a "grep bindIp /etc/mongod.conf" -u ubuntu`

This confirms the database is configured to accept remote connections:

Expected output:

` bindIp: 0.0.0.0`

If it still shows 127.0.0.1, remote connections from your web server won’t work.

Once both tests pass, you can safely proceed to connect the web app to the db.

### Why the Database Needs Manual Seeding in the Playbook (vs. Automatic in Bash)

When deploying with Bash, the MongoDB seeding process appeared to happen automatically — whereas in the Ansible version, the database had to be seeded explicitly with a task:

```yaml
- name: seed MongoDB using app's seed script
  ansible.builtin.shell: node seeds/seed.js
```
This difference arises from how each tool executes commands and manages environments.

In the Bash Script:

- The Bash script executes **line-by-line in a single shell session**.  
- Commands such as `npm install` and `pm2 start app.js` run sequentially **within the same environment**.  
- During the same session, the app detects an empty MongoDB instance and **triggers its internal seed script automatically**.  
- The environment variable `DB_HOST` is already set globally (`export DB_HOST="mongodb://<public_ip>:27017/posts"`), so the Node.js application knows the database location immediately.

**Result:**  
When the application starts, it connects to MongoDB, finds no data, and seeds the database automatically — creating the appearance of “auto-seeding.”

In the Ansible Playbook:

- Each Ansible task executes in a **separate, isolated shell**, so environment variables do not persist between tasks.  
- The seeding step does not run automatically because:
  - The `DB_HOST` variable only exists during the specific task that defines it.  
  - PM2 starts the application in the background, preventing Ansible from detecting internal processes.  
- As a result, the MongoDB instance is deployed empty and must be populated manually through an explicit seeding step.

Adding a seeding task in Ansible makes the process **deterministic and idempotent**, ensuring that the database is consistently populated during deployment.

## 🪄 Master Playbooks

A master-playbook.yml is used to orchestrate provisioning across multiple hosts.
This approach separates concerns and maintains modularity by delegating configuration to smaller, task-specific playbooks.

prov-db.yml provisions and configures MongoDB on the database server.

prov-app.yml provisions the Node.js application and Nginx on the web server.

The master playbook executes the component playbooks sequentially to ensure proper dependency order.
Execution halts automatically if any playbook fails, preventing subsequent stages from running with incomplete configurations.

Do playbooks run simultaneously or one after another?
- Playbooks in a master playbook run sequentially, not in parallel.
- When multiple playbooks are included (e.g., prov-db.yml then prov-app.yml), Ansible completes the first before starting the next.

If a playbook fails, what happens to the others?
- If one playbook fails, Ansible stops execution and does not run the remaining playbooks.
- This behaviour ensures that dependent stages do not proceed when previous configurations are incomplete or unsuccessful.
- The behaviour can be overridden with options such as ignore_errors: true or conditional includes, although this is not recommended for provisioning workflows.
