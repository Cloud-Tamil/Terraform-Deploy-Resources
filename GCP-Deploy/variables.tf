variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "demo"
}

variable "machine_type" {
  description = "VM machine type"
  type        = string
  default     = "e2-micro" # Free tier eligible
}
