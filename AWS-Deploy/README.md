# Basic AWS VM + S3 + Monitoring Stack (Terraform)

Minimal, disposable stack: one EC2 instance, one security group (SSH-only
inbound), one S3 bucket, and a single CloudWatch CPU alarm. Built so the
whole thing can be spun up and torn down cleanly with two commands.

## What gets created

| Resource | Notes |
|---|---|
| `aws_security_group.vm_sg` | Inbound: SSH (22) from `allowed_ssh_cidr` only. Outbound: all. |
| `aws_instance.vm` | Amazon Linux 2023, `t3.micro` by default, basic (free) monitoring, encrypted root volume, IMDSv2 enforced. |
| `aws_s3_bucket.storage` + encryption/versioning/public-access-block resources | Private, AES256-encrypted, versioned bucket. |
| `aws_cloudwatch_metric_alarm.cpu_high` | Optional (on by default) — alarms if average CPU > threshold for 10 min. Uses the free basic EC2 metrics, no extra agent installed. |

No CloudWatch Logs agent, no detailed monitoring, no NAT gateway, no extra
IAM roles are created — kept to the minimum needed to stand the box up and
watch it.

## Prerequisites

1. [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.0
2. AWS credentials configured (any of these work):
   ```bash
   aws configure
   # or
   export AWS_ACCESS_KEY_ID=...
   export AWS_SECRET_ACCESS_KEY=...
   export AWS_SESSION_TOKEN=...   # if using temporary creds
   ```
3. (Optional but recommended) an existing EC2 key pair if you want SSH access:
   ```bash
   aws ec2 create-key-pair --key-name my-ec2-keypair --query 'KeyMaterial' --output text > my-ec2-keypair.pem
   chmod 400 my-ec2-keypair.pem
   ```

## Configure

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and at minimum set:
- `allowed_ssh_cidr` — your public IP as `x.x.x.x/32` (find it with `curl ifconfig.me`)
- `key_name` — an existing key pair name, or leave `null` if you don't need SSH

## Deploy

```bash
terraform init
terraform plan      # review what will be created
terraform apply      # type 'yes' to confirm
```

Outputs after apply give you the instance public IP, security group ID,
S3 bucket name, and alarm name.

SSH in (if you set a key):
```bash
ssh -i my-ec2-keypair.pem ec2-user@$(terraform output -raw instance_public_ip)
```

## Tear everything down

Because the S3 bucket has versioning enabled, Terraform can only delete it
if it's empty. If you put objects in it, empty it first:

```bash
aws s3 rm s3://$(terraform output -raw s3_bucket_name) --recursive
```

Then destroy all resources:

```bash
terraform destroy
```

Type `yes` to confirm. This removes the EC2 instance, security group,
S3 bucket, and CloudWatch alarm — nothing is left behind, so nothing
keeps billing.

To automate that emptying step so `destroy` always works in one shot, you
can instead add `force_destroy = true` to the `aws_s3_bucket.storage`
resource in `main.tf` before running `terraform destroy` — that tells
Terraform to delete all objects/versions in the bucket for you. It's left
out by default as a safety net so you don't accidentally lose data.

## File layout

```
.
├── versions.tf               # Terraform + provider version constraints
├── variables.tf               # Input variables
├── main.tf                    # Security group, EC2 instance, S3 bucket, alarm
├── outputs.tf                 # Useful values printed after apply
├── terraform.tfvars.example   # Copy to terraform.tfvars and fill in
└── README.md
```

## Notes / things to double-check before using in anything beyond a sandbox

- The default VPC/subnets are used. If your account doesn't have a default
  VPC, you'll need to add `vpc_id`/`subnet_id` variables pointing at your own.
- `allowed_ssh_cidr` has no default on purpose — you must set it, so you
  don't accidentally leave SSH open to the world.
- State is local (`terraform.tfstate` in this directory) for simplicity.
  For team use, switch to a remote backend (S3 + DynamoDB lock table).
