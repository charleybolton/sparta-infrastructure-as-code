# 🚀 Terraform Expressions & Interpolation

- [🚀 Terraform Expressions \& Interpolation](#-terraform-expressions--interpolation)
  - [🧮 Conditional Expressions](#-conditional-expressions)
    - [Syntax](#syntax)
    - [Common Use Case – Default Fallbacks](#common-use-case--default-fallbacks)
  - [🧱 Workspaces](#-workspaces)
    - [Basic Commands](#basic-commands)
  - [🌍 Locals](#-locals)
    - [Syntax](#syntax-1)
  - [📦 .tfvars Files](#-tfvars-files)
    - [Syntax](#syntax-2)
    - [Running with .tfvars Files](#running-with-tfvars-files)
  - [🧩 String Interpolation \& Concatenation](#-string-interpolation--concatenation)
    - [Alternative Syntax (Terraform 0.12+)](#alternative-syntax-terraform-012)

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

## 🧱 Workspaces

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

## 🌍 Locals

**Locals** in Terraform define reusable values or computed expressions that can be referenced throughout the configuration.

They help keep code cleaner and more readable, reduce repetition (DRY principle), and store derived values or conditional logic in a single place.

### Syntax

```bash
locals {
  instance_count = var.environment == "dev" ? 1 : 2
  instance_name  = "${var.app_name}-${var.environment}"
}
```

Locals are referenced with the local. prefix:

```bash
resource "aws_instance" "app_instance" {
  count = local.instance_count

  ami           = var.default_ami
  instance_type = var.instance_type

  tags = {
    Name = local.instance_name
  }
}
```

- Centralising logic in locals reduces duplication and improves maintainability.
- Locals are best suited for internal logic that remains constant across runs, while variables handle values that differ between deployments.

## 📦 .tfvars Files

**.tfvars files** let you define environment-specific variable values (for example, `dev`, `prod`) outside your main Terraform configuration.
  
This keeps your setup **DRY**, allowing you to reuse the same code while switching environments simply by loading a different `.tfvars` file.

Each `.tfvars` file overrides variable values defined in `variables.tf`.

Example folder structure:

```bash
terraform/  
├── main.tf  
├── variables.tf  
├── dev.tfvars  
└── prod.tfvars  
```

### Syntax

```bash
dev.tfvars  
environment     = "dev"  
instance_count  = 1  

prod.tfvars  
environment     = "prod"  
instance_count  = 2
```

Terraform reads the variable values from the specified `.tfvars` file at runtime.

These values are passed into the configuration, allowing the same code to behave differently depending on the environment.

### Running with .tfvars Files

Specify which environment file to load:  
`terraform apply -var-file=dev.tfvars`  
`terraform apply -var-file=prod.tfvars`

Alternatively, rename the files to use the `.auto.tfvars` suffix:

```bash
dev.auto.tfvars  
prod.auto.tfvars  
```

Terraform automatically loads these, so you can simply run:  
`terraform apply`

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