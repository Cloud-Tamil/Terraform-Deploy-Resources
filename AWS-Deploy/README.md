# 🚀 Cloud Tamil — Terraform AWS Multi-Tier Infrastructure

A **single-command, zero-waste, fully destroyable** AWS infrastructure stack built with Terraform.  
Deploys a custom VPC, EC2 web server with live metadata dashboard, S3 storage, IAM roles, and a Fargate ECS cluster running a sample Nginx container — all torn down cleanly with `terraform destroy`.

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5.0-7B42BC?logo=terraform)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS%20Provider-~%3E5.0-FF9900?logo=amazonaws)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](#license)

---

## 📑 Table of Contents

1. [Overview](#-overview)
2. [Architecture Diagram](#-architecture-diagram)
3. [Resources Created](#-resources-created)
4. [Prerequisites](#-prerequisites)
5. [Project Structure](#-project-structure)
6. [Quick Start](#-quick-start)
7. [Configuration Reference](#-configuration-reference)
8. [Outputs](#-outputs)
9. [Testing the Deployment](#-testing-the-deployment)
10. [Connecting to EC2](#-connecting-to-ec2)
11. [Inspecting ECS Logs](#-inspecting-ecs-logs)
12. [Cost Estimate](#-cost-estimate)
13. [Security Notes](#-security-notes)
14. [Clean Teardown](#-clean-teardown)
15. [Troubleshooting](#-troubleshooting)
16. [FAQ](#-faq)
17. [Best Practices Applied](#-best-practices-applied)
18. [License](#-license)

---

## 🎯 Overview

This project is designed as a **learning and demonstration stack** that showcases Terraform best practices on AWS:

- **Custom VPC** with public + private subnets across two Availability Zones
- **EC2 web server** (Amazon Linux 2023) with a live metadata dashboard served by Apache
- **S3 bucket** with versioning, AES256 encryption, and public-access blocking
- **IAM roles & instance profile** with least-privilege S3 access + SSM Session Manager
- **ECS Fargate cluster** running a sample Nginx container (via Fargate Spot for cost savings)
- **100% clean teardown** — no orphaned resources on `terraform destroy`

All resources are tagged (`Project`, `Environment`, `ManagedBy`, `Repository`) via provider `default_tags`.

---

## 🏗️ Architecture Diagram

```
                              ┌────────────────────────────────────────┐
                              │             AWS Cloud (us-east-1)      │
                              │                                        │
                              │   ┌──────────────  VPC 10.0.0.0/16 ──┐ │
                              │   │                                 │ │
   ┌──────────┐   HTTP :80    │   │  ┌───────────────────────────┐  │ │
   │  Browser │ ──────────────┼───┼─▶│  Public Subnet 10.0.1.0/24│  │ │
   └──────────┘               │   │  │   ┌──────────────────┐    │  │ │
                              │   │  │   │  EC2 (AL2023)    │    │  │ │
   ┌──────────┐   SSM Session │   │  │   │  Apache + IMDSv2 │    │  │ │
   │   AWS    │ ──────────────┼───┼─▶│   └──────────────────┘    │  │ │
   │   CLI    │               │   │  └───────────────────────────┘  │ │
   └──────────┘               │   │                                 │ │
                              │   │  ┌───────────────────────────┐  │ │
                              │   │  │  Public Subnet 10.0.2.0/24│  │ │
                              │   │  │   ┌──────────────────┐    │  │ │
                              │   │  │   │ Fargate Task     │    │  │ │
                              │   │  │   │ nginx:alpine     │    │  │ │
                              │   │  │   └──────────────────┘    │  │ │
                              │   │  └───────────────────────────┘  │ │
                              │   │                                 │ │
                              │   │  ┌───────────────────────────┐  │ │
                              │   │  │  Private Subnet (unused)  │  │ │
                              │   │  │  10.0.10.0/24, 10.0.11.0/24│ │ │
                              │   │  └───────────────────────────┘  │ │
                              │   │                                 │ │
                              │   │       ┌────────────────┐        │ │
                              │   │       │ Internet GW    │        │ │
                              │   │       └────────────────┘        │ │
                              │   └─────────────────────────────────┘ │
                              │                                        │
                              │   ┌────────────┐   ┌─────────────────┐ │
                              │   │  S3 Bucket │   │ CloudWatch Logs │ │
                              │   │  Encrypted │   │  ECS Container  │ │
                              │   └────────────┘   └─────────────────┘ │
                              └────────────────────────────────────────┘
```

---

## 📦 Resources Created

| # | Resource | Count | Purpose |
|---|----------|-------|---------|
| 1 | `aws_vpc` | 1 | Custom VPC `10.0.0.0/16` |
| 2 | `aws_internet_gateway` | 1 | Public internet access |
| 3 | `aws_subnet` (public) | 2 | Multi-AZ public subnets |
| 4 | `aws_subnet` (private) | 2 | Multi-AZ private subnets |
| 5 | `aws_route_table` | 2 | Public + private routing |
| 6 | `aws_route_table_association` | 4 | Subnet ↔ RT links |
| 7 | `aws_route` | 1 | `0.0.0.0/0` → IGW |
| 8 | `aws_security_group` | 2 | EC2 web SG + ECS cluster SG |
| 9 | `aws_iam_role` | 2 | EC2 role + ECS execution role |
| 10 | `aws_iam_instance_profile` | 1 | Attaches role to EC2 |
| 11 | `aws_iam_policy` | 1 | Scoped S3 read/write policy |
| 12 | `aws_iam_role_policy_attachment` | 3 | SSM, S3, ECS policies |
| 13 | `aws_s3_bucket` | 1 | App storage |
| 14 | `aws_s3_bucket_public_access_block` | 1 | Blocks public access |
| 15 | `aws_s3_bucket_server_side_encryption_configuration` | 1 | AES256 default |
| 16 | `aws_s3_bucket_versioning` | 1 | Versioning enabled |
| 17 | `aws_s3_object` | 1 | `welcome.txt` demo file |
| 18 | `aws_instance` | 1 | EC2 web server (AL2023) |
| 19 | `aws_ecs_cluster` | 1 | Fargate cluster + Container Insights |
| 20 | `aws_ecs_cluster_capacity_providers` | 1 | FARGATE + FARGATE_SPOT |
| 21 | `aws_ecs_task_definition` | 1 | Nginx Alpine task |
| 22 | `aws_ecs_service` | 0 or 1 | Toggle via `enable_ecs_sample_service` |
| 23 | `aws_cloudwatch_log_group` | 1 | `/ecs/<project_name>` (1-day retention) |
| 24 | `random_string` | 1 | S3 bucket name suffix |
| 25 | `data.aws_ami` | 1 | Latest AL2023 AMI |
| 26 | `data.aws_availability_zones` | 1 | Region AZ list |
| 27 | `data.aws_iam_policy_document` | 2 | Assume-role policies |

**Total: ~30 resources** (ECS service optional).

---

## ✅ Prerequisites

### Required Tools

| Tool | Minimum Version | Install |
|------|-----------------|---------|
| Terraform | `>= 1.5.0` | [terraform.io/downloads](https://developer.hashicorp.com/terraform/downloads) |
| AWS CLI | `>= 2.13` | [aws.amazon.com/cli](https://aws.amazon.com/cli/) |
| Session Manager Plugin (optional) | Latest | [AWS docs](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) |
| `curl` | Any | Preinstalled on macOS/Linux |

### Required AWS Permissions

Your IAM identity must be able to create/modify:
`ec2:*`, `vpc:*`, `iam:*` (roles, policies, instance profiles), `s3:*`, `ecs:*`, `logs:*`, `ssm:*`.

### AWS Credentials

Configure credentials in **one** of these ways:

```bash
# Option 1 — AWS CLI profile (recommended)
aws configure --profile cloudtamil
export AWS_PROFILE=cloudtamil

# Option 2 — Environment variables
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"

# Option 3 — AWS SSO
aws sso login --profile cloudtamil
export AWS_PROFILE=cloudtamil
```

Verify credentials:
```bash
aws sts get-caller-identity
```

---

## 📂 Project Structure

```
.
├── provider.tf            # Terraform + AWS provider, default tags
├── variables.tf           # All input variables with defaults
├── terraform.tfvars       # Your custom values (edit this!)
├── vpc.tf                 # VPC, subnets, IGW, route tables
├── security_groups.tf     # Web SG + ECS cluster SG
├── iam.tf                 # IAM roles, policies, instance profile
├── s3.tf                  # S3 bucket + encryption + versioning
├── ec2.tf                 # EC2 instance + AL2023 AMI lookup
├── ecs.tf                 # ECS Fargate cluster + sample service
├── outputs.tf             # All outputs + quick test commands
└── README.md              # This file
```

---

## ⚡ Quick Start

### 1. Clone / Create the project

```bash
mkdir cloudtamil-terraform && cd cloudtamil-terraform
# Place all .tf files here
```

### 2. Create `terraform.tfvars`

```hcl
aws_region    = "us-east-1"
project_name  = "demo"           # ⚠️ MUST be lowercase (S3 rule)
environment   = "test"
vpc_cidr      = "10.0.0.0/16"
instance_type = "t3.micro"

# Get your IP: curl https://checkip.amazonaws.com
allowed_ssh_cidr = "0.0.0.0/0"   # ⚠️ For testing only — restrict in production

enable_ecs_sample_service = true
```

### 3. Initialize & deploy

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply -auto-approve
```

Wait ~3–5 minutes for EC2 user-data and ECS task to boot.

### 4. Grab the outputs

```bash
terraform output
# or JSON format:
terraform output -json
```

You'll see something like:

```
ec2_web_test_url = "http://54.152.xxx.xxx"
s3_bucket_name   = "demo-bucket-a1b2c3"
ecs_cluster_name = "demo-ecs-cluster"
```

### 5. Open the EC2 dashboard

Paste the `ec2_web_test_url` into your browser. You'll see a dark-themed page showing:

- Instance ID
- Availability Zone
- Public / Private IP
- VPC CIDR
- S3 bucket name

### 6. Destroy when done

```bash
terraform destroy -auto-approve
```

---

## 🔧 Configuration Reference

### Input Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `aws_region` | `string` | `"us-east-1"` | AWS region to deploy into |
| `project_name` | `string` | `"cloudtamil-demo"` | Resource name prefix (lowercase) |
| `environment` | `string` | `"dev"` | Environment tag (dev/staging/prod) |
| `vpc_cidr` | `string` | `"10.0.0.0/16"` | Base VPC CIDR |
| `public_subnet_cidrs` | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24"]` | Public subnets |
| `private_subnet_cidrs` | `list(string)` | `["10.0.10.0/24", "10.0.11.0/24"]` | Private subnets |
| `instance_type` | `string` | `"t3.micro"` | EC2 instance size |
| `key_name` | `string` | `null` | Optional EC2 key pair name |
| `allowed_ssh_cidr` | `string` | `"0.0.0.0/0"` | CIDR allowed to SSH (restrict!) |
| `enable_ecs_sample_service` | `bool` | `true` | Toggle ECS Fargate service |

### Example `terraform.tfvars` Variations

**Production-safe (recommended):**
```hcl
project_name     = "my-app-prod"
environment      = "prod"
instance_type    = "t3.small"
allowed_ssh_cidr = "203.0.113.42/32"     # your IP only
key_name         = "my-aws-key"
enable_ecs_sample_service = false        # disable demo container
```

**Minimal (VPC + EC2 only):**
```hcl
project_name              = "minimal-demo"
enable_ecs_sample_service = false
```

---

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | ID of the custom VPC |
| `internet_gateway_id` | ID of the IGW |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `public_route_table_id` | Public RT ID |
| `web_security_group_id` | EC2 security group ID |
| `cluster_security_group_id` | ECS security group ID |
| `ec2_instance_id` | EC2 instance ID |
| `ec2_public_ip` | EC2 public IPv4 |
| `ec2_web_test_url` | Direct URL to test the web page |
| `s3_bucket_name` | S3 bucket name |
| `ecs_cluster_name` | ECS cluster name |
| `iam_ec2_role_arn` | EC2 IAM role ARN |
| `quick_test_commands` | Map of handy test commands |

View a single output:
```bash
terraform output ec2_web_test_url
terraform output -raw s3_bucket_name
```

---

## 🧪 Testing the Deployment

### Verify EC2 web server

```bash
curl -I http://$(terraform output -raw ec2_public_ip)
# Expect: HTTP/1.1 200 OK
```

### Verify S3 contents

```bash
aws s3 ls s3://$(terraform output -raw s3_bucket_name)
# Expect: welcome.txt
```

### Verify ECS cluster status

```bash
CLUSTER=$(terraform output -raw ecs_cluster_name)
aws ecs describe-clusters --clusters "$CLUSTER"
aws ecs list-services --cluster "$CLUSTER"
aws ecs describe-services --cluster "$CLUSTER" --services "demo-service"
```

### Verify running tasks

```bash
aws ecs list-tasks --cluster "$CLUSTER"
```

---

## 🔐 Connecting to EC2

### Option A — AWS SSM Session Manager (recommended, no SSH key needed)

The instance already has `AmazonSSMManagedInstanceCore` attached.

```bash
# Install plugin (macOS)
brew install --cask session-manager-plugin

# Connect
aws ssm start-session --target $(terraform output -raw ec2_instance_id)
```

### Option B — SSH (requires key pair)

1. Set `key_name` in `terraform.tfvars` to an existing EC2 Key Pair.
2. Set `allowed_ssh_cidr` to your IP:
   ```bash
   curl -s https://checkip.amazonaws.com
   ```
3. Apply, then SSH:
   ```bash
   ssh -i ~/.ssh/my-key.pem ec2-user@$(terraform output -raw ec2_public_ip)
   ```

---

## 📊 Inspecting ECS Logs

Container logs stream to CloudWatch:

```bash
aws logs tail /ecs/demo --follow
```

Or via the AWS Console:
**CloudWatch → Log groups → `/ecs/<project_name>`**

> Note: retention is set to **1 day** to minimize cost.

---

## 💰 Cost Estimate

Approximate **us-east-1** on-demand pricing (verify with [AWS Pricing Calculator](https://calculator.aws/)):

| Resource | Spec | Monthly Est. |
|----------|------|--------------|
| EC2 `t3.micro` | 730 hrs (24/7) | ~$7.50 |
| EC2 EBS gp3 | 20 GB | ~$1.60 |
| Fargate Spot task | 0.25 vCPU, 0.5 GB (24/7) | ~$4.50 |
| S3 storage | < 1 GB | ~$0.02 |
| CloudWatch Logs | < 100 MB / day | ~$0.05 |
| Data transfer out | < 1 GB | ~$0.09 |
| **Total** | | **~$14 / month** |

**Save money:**
- Set `enable_ecs_sample_service = false` → saves ~$4.50/mo
- Use `terraform destroy` when not in use → $0

---

## 🔒 Security Notes

### ✅ Built-in best practices

- **S3 public access fully blocked** (all 4 flags enabled)
- **S3 AES256 encryption by default**
- **S3 versioning enabled**
- **IMDSv2 enforced** on EC2 (`http_tokens = "required"`)
- **EBS root volume encrypted**
- **IAM least privilege** — scoped S3 policy, no `*` resources
- **SSM Session Manager** enabled (no need for open SSH)
- **ECS Fargate Spot** — serverless, no host OS to patch
- **Container Insights** enabled for observability

### ⚠️ Testing-only defaults you should change

| Setting | Default | Production recommendation |
|---------|---------|---------------------------|
| `allowed_ssh_cidr` | `0.0.0.0/0` | Your office/home IP `/32` |
| HTTP ingress on EC2 | `0.0.0.0/0` | Restrict to a CDN or load balancer |
| ECS cluster SG ingress | `vpc_cidr` only | Add ALB + WAF |
| S3 `force_destroy` | `true` | `false` in production |

### Restrict SSH to your IP

```bash
sed -i.bak "s|allowed_ssh_cidr.*|allowed_ssh_cidr = \"$(curl -s https://checkip.amazonaws.com)/32\"|" terraform.tfvars
terraform apply -auto-approve
```

---

## 🧹 Clean Teardown

Everything is designed to be **fully destroyed** with a single command.

```bash
terraform destroy -auto-approve
```

**Why nothing is left behind:**

| Feature | What it protects |
|---------|------------------|
| `force_destroy = true` on S3 | Deletes versioned objects & bucket |
| `delete_on_termination = true` on EBS | Volume removed with EC2 |
| `retention_in_days = 1` on CloudWatch | Log group expires fast |
| ECS service created after IAM | No stuck deps |
| Route table associations explicit | Clean RT removal |

### Manual sanity check after destroy

```bash
aws ec2 describe-instances --filters "Name=tag:Project,Values=demo"
aws s3 ls | grep demo
aws ecs list-clusters | grep demo
```

If any of those return output, file an issue — the stack should be fully gone.

---

## 🛠️ Troubleshooting

### `Error: creating S3 Bucket: InvalidBucketName`

**Cause:** `project_name` contains uppercase letters.  
**Fix:** Use lowercase only — `"demo"` not `"Demo"`.

### `Error: creating EC2 Instance: InvalidKeyPair.NotFound`

**Cause:** `key_name` set but key pair doesn't exist in the region.  
**Fix:** Remove `key_name` (use SSM) or create the key pair first:
```bash
aws ec2 create-key-pair --key-name my-aws-key --query 'KeyMaterial' --output text > my-aws-key.pem
chmod 400 my-aws-key.pem
```

### `Error: creating ECS Service: ... unable to place a task`

**Cause:** Fargate Spot capacity temporarily unavailable in the AZ.  
**Fix:** Wait 1–2 minutes, then:
```bash
terraform apply -auto-approve
```
Or switch to on-demand by editing `ecs.tf`:
```hcl
launch_type = "FARGATE"   # already set
# and remove FARGATE_SPOT from the default strategy
```

### Web page not loading after `apply`

**Cause:** EC2 user-data still installing packages (takes 60–120 s).  
**Fix:** Wait, then retry:
```bash
sleep 90
curl -I http://$(terraform output -raw ec2_public_ip)
```

Or check cloud-init logs via SSM:
```bash
aws ssm start-session --target $(terraform output -raw ec2_instance_id)
sudo tail -f /var/log/cloud-init-output.log
```

### `Error: Error acquiring the state lock`

**Cause:** A previous run crashed.  
**Fix:**
```bash
terraform force-unlock <LOCK_ID>
```

### ECS container healthy but unreachable from browser

**Expected.** `cluster_sg` only allows port 80 **from inside the VPC**.  
There's no ALB. Verify via logs instead:
```bash
aws logs tail /ecs/demo --follow
```

To make it public, add an Application Load Balancer and open port 80 in `cluster_sg`.

---

## ❓ FAQ

**Q: Do I need an SSH key to connect?**  
A: No. SSM Session Manager works without any SSH key — just install the Session Manager plugin.

**Q: Can I change the region after deploying?**  
A: No — everything is region-scoped. Change `aws_region`, then `terraform destroy` in the old region first, then `apply` in the new one.

**Q: Is this Free Tier eligible?**  
A: Partially. `t3.micro` + 20 GB gp3 + S3 < 5 GB are covered under the 12-month Free Tier for new accounts. Fargate is not.

**Q: How do I disable the ECS demo?**  
A: Set `enable_ecs_sample_service = false` in `terraform.tfvars` and re-apply.

**Q: Can I run this in a shared AWS account?**  
A: Yes. All names are prefixed with `project_name`, so collisions are unlikely. S3 uses a random suffix.

**Q: How do I add a NAT gateway for private subnets?**  
A: Add an `aws_eip`, `aws_nat_gateway` in a public subnet, and a default route in the private RT. Not included by default to keep costs near zero.

**Q: Where do I report bugs?**  
A: Open an issue in the repository with `terraform version`, `aws --version`, and full error output.

---

## 🏅 Best Practices Applied

| Practice | Implementation |
|----------|----------------|
| **Infrastructure as Code** | 100% Terraform-managed |
| **Immutable infrastructure** | `user_data_replace_on_change = true` |
| **Least privilege IAM** | Scoped S3 policy, no wildcard resources |
| **Zero-trust networking** | Private subnets, SG-to-SG rules |
| **Encryption at rest** | S3 AES256, EBS encrypted |
| **Encryption in transit** | IMDSv2 enforced |
| **Observability** | CloudWatch Logs + Container Insights |
| **Cost hygiene** | Fargate Spot, 1-day log retention, `force_destroy` |
| **Consistent tagging** | `default_tags` on provider |
| **Modular variables** | All inputs in `variables.tf` |
| **Self-documenting outputs** | `quick_test_commands` map |
| **Teardown safety** | Explicit `depends_on`, no orphans |

---

## 📜 License

MIT License — see `LICENSE` file.  
Free to use, modify, and distribute for personal or commercial projects.

---

## 🙏 Credits

Built with ❤️ by **Cloud Tamil** — for learners, tinkerers, and cloud engineers who want a real AWS environment without the mess.

---

## 📚 Further Reading

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [ECS Best Practices Guide](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [AWS SSM Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

**⭐ If this helped you, give the repo a star!**
