# ---------------------------------------------------------------------------
# Boot image lookup (Debian)
# ---------------------------------------------------------------------------
data "google_compute_image" "debian" {
  family  = var.boot_image_family
  project = var.boot_image_project
}

# ---------------------------------------------------------------------------
# Optional SSH metadata (only added if ssh_public_key is provided)
# ---------------------------------------------------------------------------
locals {
  ssh_metadata = var.ssh_public_key != "" ? {
    "ssh-keys" = "${var.ssh_user}:${var.ssh_public_key}"
  } : {}
}

# ---------------------------------------------------------------------------
# mynet-vm-1  -> mynetwork (auto-mode subnet, us-east1)
# ---------------------------------------------------------------------------
resource "google_compute_instance" "mynet_vm_1" {
  name         = "mynet-vm-1"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["mynet-vm"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = google_compute_network.mynetwork.id
    subnetwork = "mynetwork" # auto-mode subnet name == network name
    # access_config {} => ephemeral public IP
    access_config {}
  }

  metadata = local.ssh_metadata

  allow_stopping_for_update = true
}

# ---------------------------------------------------------------------------
# mynet-vm-2  -> mynetwork (auto-mode subnet, asia-south1)
# ---------------------------------------------------------------------------
resource "google_compute_instance" "mynet_vm_2" {
  name         = "mynet-vm-2"
  machine_type = var.machine_type
  zone         = var.zone_2

  tags = ["mynet-vm"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = google_compute_network.mynetwork.id
    subnetwork = "mynetwork"
    access_config {}
  }

  metadata = local.ssh_metadata

  allow_stopping_for_update = true
}

# ---------------------------------------------------------------------------
# managementnet-vm-1 -> managementsubnet-1
# ---------------------------------------------------------------------------
resource "google_compute_instance" "managementnet_vm_1" {
  name         = "managementnet-vm-1"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = google_compute_network.managementnet.id
    subnetwork = google_compute_subnetwork.managementsubnet_1.id
    access_config {}
  }

  metadata = local.ssh_metadata

  allow_stopping_for_update = true
}

# ---------------------------------------------------------------------------
# privatenet-vm-1 -> privatesubnet-1
# ---------------------------------------------------------------------------
resource "google_compute_instance" "privatenet_vm_1" {
  name         = "privatenet-vm-1"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = google_compute_network.privatenet.id
    subnetwork = google_compute_subnetwork.privatesubnet_1.id
    access_config {}
  }

  metadata = local.ssh_metadata

  allow_stopping_for_update = true
}

# ---------------------------------------------------------------------------
# vm-appliance -> 3 NICs (privatesubnet-1, managementsubnet-1, mynetwork)
#                 e2-standard-4 supports up to 4 vNICs
# ---------------------------------------------------------------------------
resource "google_compute_instance" "vm_appliance" {
  name         = "vm-appliance"
  machine_type = var.appliance_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
      size  = 10
      type  = "pd-balanced"
    }
  }

  # nic0 -> privatesubnet-1  (this NIC also gets the default route)
  network_interface {
    network    = google_compute_network.privatenet.id
    subnetwork = google_compute_subnetwork.privatesubnet_1.id
    access_config {} # external IP on nic0 so SSH works
  }

  # nic1 -> managementsubnet-1
  network_interface {
    network    = google_compute_network.managementnet.id
    subnetwork = google_compute_subnetwork.managementsubnet_1.id
  }

  # nic2 -> mynetwork (auto-mode subnet in us-east1)
  network_interface {
    network    = google_compute_network.mynetwork.id
    subnetwork = "mynetwork"
  }

  metadata = local.ssh_metadata

  allow_stopping_for_update = true
}
