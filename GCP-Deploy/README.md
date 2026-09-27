# GCP Terraform Deployment (Flat Structure)

This repository contains Terraform code to deploy a complete, basic GCP environment. All resources are defined in separate `.tf` files but are managed under a **single state file**. 

## 🏗 Resources Created
- **VPC & Subnet** (`vpc.tf`) - Includes secondary IPs for GKE
- **Firewall Rules** (`firewall.tf`) - SSH & HTTP
- **Compute Engine VM** (`compute.tf`) - Debian 12 with Nginx
- **Cloud Storage Bucket** (`storage.tf`)
- **Service Account & IAM** (`iam.tf`)
- **Cloud Run Service** (`cloud_run.tf`) - Serverless container
- **GKE Cluster** (`gke.tf`) - Kubernetes cluster with 1 spot node

## ✅ Prerequisites

1. **Terraform** installed ([Download](https://developer.hashicorp.com/terraform/install))
2. **Google Cloud CLI** installed ([Download](https://cloud.google.com/sdk/docs/install))
3. A GCP Project with **Billing Enabled**.

## 🔐 Authentication & Setup

Run these commands in your terminal:

```bash
# 1. Login to GCP
gcloud auth login
gcloud auth application-default login

# 2. Set your project
gcloud config set project YOUR_PROJECT_ID

# 3. Enable required APIs (Notice container.googleapis.com added)
gcloud services enable compute.googleapis.com \
                       storage.googleapis.com \
                       iam.googleapis.com \
                       run.googleapis.com \
                       container.googleapis.com
```

## ⚙️ Configuration

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
2. Edit `terraform.tfvars` and add your `project_id`.

## 🚀 Deploy (Create Resources)

Run these commands to deploy everything at once:

```bash
# Initialize Terraform (downloads providers)
terraform init

# Format and validate code (best practice)
terraform fmt
terraform validate

# Preview the changes
terraform plan

# Deploy the resources
terraform apply -auto-approve
```
*(Note: GKE cluster creation can take 5-10 minutes to complete).*

### 🔑 Connect to the GKE Cluster
After deployment, connect `kubectl` to your new cluster:

```bash
# Get credentials
gcloud container clusters get-credentials $(terraform output -raw gke_cluster_name) --zone $(terraform output -raw gke_cluster_location)

# Test it!
kubectl get nodes
```

### Test the VM
```bash
# Get the IP
VM_IP=$(terraform output -raw vm_external_ip)

# Wait ~60 seconds for Nginx to install, then curl it
curl http://$VM_IP
```

## 🧨 Destroy (Delete Resources)

When you are done learning, destroy everything to avoid charges:

```bash
terraform destroy -auto-approve
```

## 🛠 Useful Commands

| Command | Purpose |
|---------|---------|
| `terraform state list` | List all resources being managed |
| `terraform state show <resource>` | Inspect a specific resource |
| `terraform output` | Show all outputs again |
| `terraform plan` | See what will change if you edit files |

## 💰 Cost Warning
- The `e2-micro` VM, empty GCS bucket, and minimal Cloud Run usage are generally **Free Tier eligible**.
- **GKE Cost:** A GKE cluster has a flat management fee (approx $0.10/hour, though one zonal cluster per billing account is often free under the GCP Free Tier). The `e2-small` spot instance is very cheap, but **not free**.
- **Always run `terraform destroy`** when you are finished to prevent unexpected billing.
