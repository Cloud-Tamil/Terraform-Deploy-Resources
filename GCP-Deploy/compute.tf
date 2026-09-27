resource "google_compute_instance" "vm" {
  name         = "${var.prefix}-vm"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["ssh", "http"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {} # Gives a public IP
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
  EOT
}
