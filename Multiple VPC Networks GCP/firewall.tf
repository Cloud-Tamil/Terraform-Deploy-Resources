# ---------------------------------------------------------------------------
# managementnet-allow-icmp-ssh-rdp
# ---------------------------------------------------------------------------
resource "google_compute_firewall" "managementnet_allow_icmp_ssh_rdp" {
  name      = "managementnet-allow-icmp-ssh-rdp"
  network   = google_compute_network.managementnet.name
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  source_ranges = ["0.0.0.0/0"]
  # No target_tags => applies to ALL instances in the network
}

# ---------------------------------------------------------------------------
# privatenet-allow-icmp-ssh-rdp
# ---------------------------------------------------------------------------
resource "google_compute_firewall" "privatenet_allow_icmp_ssh_rdp" {
  name      = "privatenet-allow-icmp-ssh-rdp"
  network   = google_compute_network.privatenet.name
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# ---------------------------------------------------------------------------
# mynetwork-allow-icmp-ssh-rdp
# (Pre-created in the lab — comment out if it already exists)
# ---------------------------------------------------------------------------
resource "google_compute_firewall" "mynetwork_allow_icmp_ssh_rdp" {
  name      = "mynetwork-allow-icmp-ssh-rdp"
  network   = google_compute_network.mynetwork.name
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  source_ranges = ["0.0.0.0/0"]
}
