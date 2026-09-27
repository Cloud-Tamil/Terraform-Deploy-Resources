variable "project_id" {
  description = "GCP project ID (in the lab: qwiklabs-gcp-02-xxxxxxxxxxxx)"
  type        = string
}

variable "region" {
  description = "Primary region (region_1)"
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "Primary zone (region_1 zone)"
  type        = string
  default     = "us-east1-c"
}

variable "region_2" {
  description = "Secondary region (region_2)"
  type        = string
  default     = "asia-south1"
}

variable "zone_2" {
  description = "Secondary zone (region_2 zone)"
  type        = string
  default     = "asia-south1-a"
}

variable "machine_type" {
  description = "Machine type for the single-NIC VMs"
  type        = string
  default     = "e2-micro"
}

variable "appliance_machine_type" {
  description = "Machine type for the multi-NIC VM (must support >= 3 vNICs)"
  type        = string
  default     = "e2-standard-4"
}

variable "boot_image_project" {
  description = "Project hosting the boot image"
  type        = string
  default     = "debian-cloud"
}

variable "boot_image_family" {
  description = "Boot image family"
  type        = string
  default     = "debian-12"
}

variable "ssh_user" {
  description = "Username baked into the instance SSH metadata (for browser SSH)"
  type        = string
  default     = "student"
}

variable "ssh_public_key" {
  description = "Optional SSH public key to inject into instances. Leave empty to rely on OS Login / browser SSH."
  type        = string
  default     = ""
}
