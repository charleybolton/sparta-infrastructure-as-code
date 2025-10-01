# 🧩 Intro to IaC

- [🧩 Intro to IaC](#-intro-to-iac)
  - [⚙️ What Is the Problem?](#️-what-is-the-problem)
  - [🤖 What Have We Automated So Far?](#-what-have-we-automated-so-far)
  - [🚀 Solving the Problem](#-solving-the-problem)
  - [💻 What Is IaC?](#-what-is-iac)
  - [✨ Benefits of IaC](#-benefits-of-iac)
  - [📍 When/Where to Use IaC](#-whenwhere-to-use-iac)
  - [🧰 Tools Available for IaC / Types of IaC Tools](#-tools-available-for-iac--types-of-iac-tools)


## ⚙️ What Is the Problem?

We are still manually "provisioning" on the servers. Provisioning means the process of setting up and configuring server.


## 🤖 What Have We Automated So Far?

* VMs
  * Creation of the VMs? No, other than Auto Scaling Group.
  * Creation of the infrastructure they live (e.g. VNet)? No
  * Setup & configuration of the software on VMS?
    * Bash scripts
    * User data
    * AMI

## 🚀 Solving the Problem

Infrastructure as Code (IaC) can do the provisioning of:
  * Infrastructure itself (servers)
  * Configuration of the servers i.e. installing software & configuring settings

## 💻 What Is IaC?

Iac is a way to manage and provision computers through a machine-readable definition of the infrastructure.

  * Usually codify WHAT is wanted (**declarative**), not HOW to do it (**imperative**, the user defines the desired state/outcomes)

## ✨ Benefits of IaC

+ Speed & simplicity
  + Reduces the time to deploy your infrastructure
  + Simply describe the end state, and the tool works out the rest

+ Consistency & accuracy
  + Avoid human error when creating error/maintaining the same infrastructure

+ Version control
  + Keep track of version of infrastructure over time
  
+ Scalability
  + Easy to scale or duplicate the infrastructure (including for different environments)

## 📍 When/Where to Use IaC

Use good judgment - will automating the infrastructure be worth the investment in time?

## 🧰 Tools Available for IaC / Types of IaC Tools

Two types of Iac tools:

1. **Configuration management tools** - best for installing/configuring software.

E.g. Chef, Puppet, Ansible

2.  **Orchestration tools** - best for managing infrastructure, such as VMs, security groups, route tables.

E.g. CloudFormation (AWS), Terraform, ARM/Bicep templates (Azure), Ansible (can do this, but best for configuration management)

