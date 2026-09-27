# ---------------------------------------------------------------------------
# mynetwork  -> AUTO mode network (subnets created in every region)
#              In the Qwiklabs lab this network is pre-created for you.
# ---------------------------------------------------------------------------
resource "google_compute_network" "mynetwork" {
  name                    = "mynetwork"
  auto_create_subnetworks = true
  routing_mode            = "REGIONAL"
}

# ---------------------------------------------------------------------------
# managementnet -> CUSTOM mode network
# ---------------------------------------------------------------------------
resource "google_compute_network" "managementnet" {
  name                    = "managementnet"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "managementsubnet_1" {
  name          = "managementsubnet-1"
  network       = google_compute_network.managementnet.id
  region        = var.region
  ip_cidr_range = "10.130.0.0/20"
}

# ---------------------------------------------------------------------------
# privatenet -> CUSTOM mode network (two subnets in two regions)
# ---------------------------------------------------------------------------
resource "google_compute_network" "privatenet" {
  name                    = "privatenet"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "privatesubnet_1" {
  name          = "privatesubnet-1"
  network       = google_compute_network.privatenet.id
  region        = var.region
  ip_cidr_range = "172.16.0.0/24"
}

resource "google_compute_subnetwork" "privatesubnet_2" {
  name          = "privatesubnet-2"
  network       = google_compute_network.privatenet.id
  region        = var.region_2
  ip_cidr_range = "172.20.0.0/20"
}
