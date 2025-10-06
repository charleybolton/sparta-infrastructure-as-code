# 🚀 Terraform GitHub Provider

- [🚀 Terraform GitHub Provider](#-terraform-github-provider)
  - [📦 provider](#-provider)
  - [🧩 resource](#-resource)
  - [🔑 Environment Variable Setup](#-environment-variable-setup)
    - [Why This Is Better Than Storing the Token Directly in `.zshrc`](#why-this-is-better-than-storing-the-token-directly-in-zshrc)

## 📦 provider

```bash
provider "github" {
  owner = var.github_owner
}
```

- Provider block defines which API Terraform connects to (in this case, GitHub).  
- `owner` specifies the GitHub account or organisation that owns the repositories.  
- The token is not defined here — Terraform automatically retrieves it from the `$GITHUB_TOKEN` environment variable (loaded via .zshrc and macOS Keychain).  

## 🧩 resource

```bash
resource "github_repository" "charley_tf_repo" {
  name        = var.repo_name         # Repository name on GitHub
  description = var.repo_description  # Repository description text
  visibility  = var.repo_visibility   # Options: "private" or "public"
  auto_init   = var.repo_readme       # Creates the repo with an initial README if true
}
```

- `resource` block defines what Terraform will create within the GitHub provider.  
- `github_repository` specifies that the resource type is a GitHub repository.  
- The local name `charley_tf_repo` is used internally within Terraform for referencing.  
- Repository details such as name, description, visibility, and README initialisation are defined through variables for flexibility and reusability.  

## 🔑 Environment Variable Setup

Terraform automatically reads the GitHub token from the `$GITHUB_TOKEN` environment variable.  

This section explains how the token is securely stored, retrieved, and used without ever being written in plain text.

1. Add the token to macOS Keychain (run once)

```bash
security add-generic-password -a $USER -s github_pat -w "<your_personal_access_token>"
```

Explanation:
- `security add-generic-password` → Adds a generic secret entry to the macOS Keychain.  
- `-a $USER` → Associates the token with the current macOS username.  
- `-s github_pat` → Defines a “service” name that identifies this secret for later retrieval.  
- `-w "<your_personal_access_token>"` → Writes the actual GitHub Personal Access Token value.  

This command stores the token **encrypted at rest** within the Keychain and links it to the user’s login credentials.  

Only the logged-in macOS user can retrieve or modify it.

2. Export the encrypted token into the `.zshrc` file

```bash
nano ~/.zshrc

export GITHUB_TOKEN=$(security find-generic-password -a $USER -s github_pat -w)
```

Explanation:
 
- `security find-generic-password` → Retrieves the GitHub token stored in the macOS Keychain.  
- `-a $USER` → Filters for the Keychain entry linked to the current macOS username.  
- `-s github_pat` → Specifies the service name used when the token was first added.  
- `-w` → Outputs only the stored password or token value.   

By including this line in `.zshrc`, the token is automatically pulled from the encrypted Keychain and loaded securely into memory each time a terminal opens.  

Terraform can then access `$GITHUB_TOKEN` instantly for authentication, without any secrets being stored in plain text or hardcoded in files.

1. Reload the terminal configuration

```bash
source ~/.zshrc
```

### Why This Is Better Than Storing the Token Directly in `.zshrc`

Storing tokens directly inside `.zshrc` (for example, `export GITHUB_TOKEN="ghp_abc123..."`) exposes sensitive data in plain text.  

Anyone with access to the machine or shell configuration could read, copy, or commit the token accidentally.  
By contrast, this method uses **macOS Keychain encryption** and **on-demand retrieval**, meaning:

- The token is **never stored in plaintext** on disk.  
- Access to the token is **restricted to the logged-in macOS user**.  
- The token is **only loaded into memory when a terminal session is active**, reducing exposure time.  
- It aligns with the principle of **least privilege**, as Terraform only receives the token at runtime.  

This approach combines convenience (automatic loading) with security (no hardcoded secrets), making it the most reliable local setup for Terraform and other CLI-based tools.

🚨 Note: While **AWS Secrets Manager** is considered best practice in production environments — offering centralised management, secret rotation, and IAM-based access control — it was not used in this case due to **permission constraints** and the fact that the work was performed **locally on macOS**.  

For personal or non-production workflows, the macOS Keychain provides an equally secure and lightweight alternative.






