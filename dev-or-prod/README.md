# 🚀 Terraform Expressions & Interpolation

- [🚀 Terraform Expressions \& Interpolation](#-terraform-expressions--interpolation)
  - [🧮 Conditional Expressions](#-conditional-expressions)
    - [Syntax](#syntax)
    - [Common Use Case – Default Fallbacks](#common-use-case--default-fallbacks)
  - [🧩 String Interpolation \& Concatenation](#-string-interpolation--concatenation)
    - [Alternative Syntax (Terraform 0.12+)](#alternative-syntax-terraform-012)
  - [🧱 Workspaces Overview](#-workspaces-overview)
    - [Why Use Workspaces](#why-use-workspaces)
    - [Basic Commands](#basic-commands)

## 🧮 Conditional Expressions

Conditional expressions let Terraform choose between two values depending on whether a condition is true or false.

### Syntax

`condition ? true_val : false_val`

If the condition is `true`, Terraform returns `true_val`.  
If the condition is `false`, Terraform returns `false_val`.

### Common Use Case – Default Fallbacks

`var.a == "" ? "default-a" : var.a`

Explanation:
- If `var.a` is an empty string, Terraform substitutes `"default-a"`.  
- Otherwise, it uses the actual value of `var.a`.

Terraform’s syntax always follows:  

`<attribute> = <condition> ? <true value> : <false value>`
`count = var.environment == "dev" ? 1 : 2`

Explanation:  
You’re setting the `count` argument **equal to** a conditional expression.  


---

## 🧩 String Interpolation & Concatenation

Terraform uses `${}` for **interpolation**, allowing you to combine variables, expressions, and strings.

`name = "myapp_${var.environment}_sg"`

✅ Terraform reads this as:  
> “Insert the value of `var.app_name`, add an underscore, and then add the value of `var.environment`.”

Even when combining only variables, the interpolation ensures Terraform **evaluates** the values instead of treating them as literal text.

### Alternative Syntax (Terraform 0.12+)

Interpolation can be replaced with built-in functions:

`name = format("%s_%s", var.app_name, var.environment)`

or

`name = join("_", [var.app_name, var.environment])`

These all produce the same results

---

## 🧱 Workspaces Overview

### Why Use Workspaces

Workspaces let you manage **multiple environments** (e.g. `dev`, `staging`, `prod`) from a single Terraform configuration **without overwriting previous state files**.

Each workspace has its **own state**, meaning:  
- Deploying `prod` won’t destroy your `dev` environment.  
- You can safely test or modify resources independently.
- There’s no need to create a separate environment variable — you can simply reference `terraform.workspace` directly in your code to adapt resource names, counts, or settings based on the current workspace.

### Basic Commands

List existing workspaces:
`terraform workspace list`

Create a new workspace:
`terraform workspace new <workspace name>`

Switch between workspaces:
`terraform workspace select <workspace name>`

Show the current workspace
`terraform workspace show`

**Tip:**  
Use `terraform.workspace` inside configurations to dynamically name resources:

```bash
resource "aws_s3_bucket" "example" {
bucket = "my-bucket-${terraform.workspace}"
}
```

This automatically appends the current workspace name (e.g. `my-bucket-dev`, `my-bucket-prod`).
