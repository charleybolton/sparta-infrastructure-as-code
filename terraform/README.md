# 🧩 Terraform

- [IaC Setup Notes](#iac-setup-notes)
  - [Tools Installed](#tools-installed)
  - [Verification](#verification)

## 🧱 IaC Setup Guide (Terraform + VS Code)

**1. Create Your IaC Folder / Repo**

**2. Install terraform**

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

or if you already have it installed, update to the newest version

brew update
brew upgrade hashicorp/tap/terraform
```

*Note: Homebrew automatically adds Terraform to your PATH, so you can run it from anywhere in the terminal. No manual folder setup is required on macOS. However, if you are a Windows user, it is recommended to create a shared folder for all your command-line tools — for example `C:\my-cmd-line-tools`. Then move `terraform.exe` (and any other tools you install in the future) into that folder, and add it to your **PATH** environment variable. This ensures you can run Terraform and other CLI tools from any directory without needing to specify their full file paths*

**3.  Set Up VS Code**

- Open VS Code
- Go to Extensions (`⇧⌘X` on macOS or `Ctrl + Shift + X` on Windows)
- Search for “Terraform” → install the official one by HashiCorp
- (Optional) Install the “Ansible” extension by Red Hat

**4. Verify Everything Works**

- Run `terraform --version` to check that Terraform is installed correctly.  
- **Expected output:** `Terraform v1.13.3 on windows_amd64`  
- Open a **new PowerShell or Git Bash** window and run `terraform --version` again.  

✅ If it works there too, your **PATH** is correctly configured.  
This step confirms Terraform is installed **system-wide**, meaning you can run Terraform commands from **any directory** — not just the folder where it was installed.  

⚠️ If the command only works in one specific folder, Terraform isn’t in your PATH and needs to be added manually.

---

## ☁️ Setting AWS Environment Variables

**1. Open your terminal**

**2. Open your shell configuration file**

Run the following command to open your `.zshrc` file in the nano text editor:

`nano ~/.zshrc`

*💻 Windows users:* open **Git Bash** instead, and use the same command to edit your `.bash_profile`:

`nano ~/.bash_profile`


**3. Add your AWS credentials**

Scroll to the bottom of the file and add these two lines (replace with your actual keys):

```bash
export AWS_ACCESS_KEY_ID=your_access_key_here
export AWS_SECRET_ACCESS_KEY=your_secret_key_here
```

**4. Save and exit**

- Press `CTRL + O` → `Enter` to save  
- Then press `CTRL + X` to exit nano

**5. Reload your shell configuration**

This applies your changes immediately without restarting your terminal:

`source ~/.zshrc`

*💻 Windows users:* run the same command but replace `.zshrc` with `.bash_profile`:

`source ~/.bash_profile`

**6. Verify the variables are set**

Check that both variables are available:

```bash
printenv AWS_ACCESS_KEY_ID
printenv AWS_SECRET_ACCESS_KEY
```

✅ If both commands display your keys, the setup worked correctly.

--

## 🌍 What Is Terraform & What Is It Used For?

* Orchestration tool
* Best for infrastructure provisioning
* Originally inspired by AWS CloudFormation
* Sees infrastructure as immutable (i.e. disposable)
  * Compare this to CM tools which usually see infrastructure as mutable/reusable
* Code in Hashicopr Configuration Language (HCL)
  * Aims to give a balance between human- and machine-readability
  * HCL can be converted to JSON and vice versa

---

## ✨ What Are the Benefits of Terraform?

+ Easy to use  
  + Terraform uses a simple configuration language (HCL) that's easy to learn and read.  
  + It clearly defines what you want to create (e.g. S3 bucket, EC2 instance) without complex scripting.  

+ Sort of open-source  
  + Since 2023, Terraform uses a **Business Source License (BSL)** — this means it’s still free to use, but **cannot be used to build competing products**.  
  + Because of this, some organisations have started using **OpenTofu**, an open-source, drop-in alternative maintained by the Linux Foundation.  

+ Declarative  
  + You describe **what** infrastructure you want (e.g. “I want an EC2 instance”), and Terraform figures out **how** to make it happen.  
  + This contrasts with **imperative** tools (like Bash scripts) where you must manually tell the system **how** to do each step.  

+ Cloud-agnostic  
  + Terraform works across **many cloud providers** (AWS, Azure, GCP, etc.), as well as other services like GitHub or Datadog.  
  + To use a specific cloud, you need to **download the “provider”** (a plug-in) for that cloud provider.  
  + Each cloud vendor maintains its own provider, so Terraform can communicate with it using APIs.  
  + This makes Terraform very **flexible, expressive, and extendible** — one tool to manage everything, even in multi-cloud setups.  

---

## 🧭 Alternatives To Terraform

- **Pulumi** – Similar to Terraform but **imperative**, meaning you use real programming languages (like Python, TypeScript, or Go) to write your infrastructure code.  
  
- **AWS CloudFormation**, **GCP Deployment Manager**, **Azure Resource Manager** – Cloud-specific IaC products. These are managed by the individual cloud vendors and only work within their own ecosystems.

---

## 🎼 In IaC, What Is Orchestration?

Process of automating and managing the entire lifecycle of infrastructure resources.

### How Does Terraform Act as an Orchestrator?

Takes care of order in which to create/modify/destroy

---

## 🔐 Best Practice: Supplying AWS Credentials to Terraform

Terraform looks for credentials in this order:

1. **Environment variables:**  
   `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
   ➡️ (okay if for local use is restricted to your user)

2. **Terraform variables:**  
   ❌ Should **never** be used — we **never hard-code credentials** in `.tf` files or variable definitions.

3. **AWS CLI configuration:**  
   When you run `aws configure`, Terraform can automatically read credentials from the AWS CLI’s config and credentials files. ➡️ (good way of doing it)

4. **If using Terraform on EC2 instance**, we can give an IAM role ➡️ (absolutely best practice)

---

## ⛔ How Should AWS Credentials Never Be Passed to Terraform?

- **NEVER hard-code them** in `.tf` files or variables.  
- Credentials must **never end up in a public Git repo** — this is a major security risk.

---

## 🌍 Why Use Terraform for Different Environments? (e.g. Production, Testing)

Examples:

- **Testing environment**  
  - Easily/quickly spin up infrastructure for testing purposes that mirrors production.  
  - Easily/quickly bring it down at COB (close of business).  

  - **Consistency between environments**, reducing bugs caused by my environment discrepancies. 

---

## 🧠 How Does Terraform Work?

On Our Local Machine:

![Infrastructure as Code cartoon](../images/how-terraform-works.png)

- Installed Terraform (`terraform --version`)
- Folder contains:
  - `main.tf` → stores main configuration code  
  - `variable.tf` → stores variable definitions  
  - `.terraform.lock.hcl` → locks your provider version  
  - `terraform.tfstate` → can contain credentials (stores infrastructure state in backend)  
  - `terraform.tfstate.backup` → backup of the state file (can contain credentials)  
  - `.terraform/` folder → stores provider files and modules

Terraform checks what’s stored in the state folders, downloads providers, and sets up the backend.

- `terraform plan` → non-destructive; shows what changes will be made  
- `terraform apply` / `terraform destroy` → connects to APIs using the provider file and applies or removes resources

---

## Configuration Drift
- Example: Load balancer on several app VMs  
- Changes may occur on individual VMs  
- Problem: Things not running properly between machines (something out of date)  

**Solution:**  
- Configuration management tools like **Ansible** can handle these issues.  
- If the drift is minor (e.g., a name change or infrastructure out of alignment), re-running Terraform (an orchestration tool) will fix it.

---

### Adding a `.gitignore`
- You can select this when creating a repo on GitHub  
- Or, if already created and working locally, run:

```bash
curl -s https://raw.githubusercontent.com/github/gitignore/main/Terraform.gitignore
 -o .gitignore
 ```