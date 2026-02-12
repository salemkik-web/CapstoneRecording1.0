# Terraform WordPress + RDS Deployment

## Overview

This project deploys a **production-ready WordPress environment** on AWS using Terraform. It includes:

- **VPC** with public and private subnets
- **Public EC2 instances** running WordPress behind an ALB
- **Auto Scaling Group** for high availability
- **Private RDS MySQL instance** for database
- **Security Groups** with minimal exposure (SSH limited to your IP)
- **Fully automated WordPress setup** using user-data
- **Secure Apache configuration** and WordPress salts

> ✅ No NAT required, cost-efficient, and portfolio-ready.

---

## Architecture

# CapstoneRecording1.0
    ┌─────────────────────────────┐
      │       AWS ALB (Public)       │
      └─────────────┬───────────────┘
                    │
       ┌────────────┴────────────┐
       │                         │
┌─────────────┐ ┌─────────────┐
│ EC2 (Public)│ │ EC2 (Public)│
│ WordPress │ │ WordPress │
└──────┬──────┘ └──────┬──────┘
│ │
└────────────┬────────────┘
│
┌─────────────┐
│ RDS MySQL │
│ (Private) │
└─────────────┘


- EC2 instances are in **public subnets** for SSH debugging
- RDS is in **private subnets** for security
- ALB distributes traffic to EC2 instances
- Auto Scaling ensures availability
- Security Groups allow only necessary ports:
  - HTTP (80) from ALB
  - SSH (22) from your IP
  - MySQL (3306) from EC2 only

---

## Prerequisites

- Terraform ≥ 1.5
- AWS CLI configured
- SSH key pair (~/.ssh/id_rsa.pub)
- Internet access to download WordPress and PHP packages

---

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| region | AWS region | us-west-2 |
| availability_zone1 | AZ for first subnet | us-west-2a |
| availability_zone2 | AZ for second subnet | us-west-2b |
| vpc_cidr | VPC CIDR | 10.0.0.0/16 |
| db_username | RDS admin username | admin |
| db_password | RDS admin password (sensitive) | — |
| myip | Your public IP for SSH access | 149.233.230.216/32 |

> **Sensitive**: `db_password` should be passed at runtime or via a `.tfvars` file.

---

## Deployment

1. Initialize Terraform:

```bash
terraform init

---

This README is **portfolio-ready**:

- Explains architecture clearly
- Shows security best practices
- Walks through usage
- Highlights production-like features

---