output "networks" {
  description = "All VPC networks"
  value = {
    mynetwork     = google_compute_network.mynetwork.name
    managementnet = google_compute_network.managementnet.name
    privatenet    = google_compute_network.privatenet.name
  }
}

output "subnets" {
  description = "Custom subnets created"
  value = {
    managementsubnet_1 = google_compute_subnetwork.managementsubnet_1.name
    privatesubnet_1    = google_compute_subnetwork.privatesubnet_1.name
    privatesubnet_2    = google_compute_subnetwork.privatesubnet_2.name
  }
}

output "vm_external_ips" {
  description = "External (public) IPs of all VMs"
  value = {
    mynet_vm_1          = google_compute_instance.mynet_vm_1.network_interface[0].access_config[0].nat_ip
    mynet_vm_2          = google_compute_instance.mynet_vm_2.network_interface[0].access_config[0].nat_ip
    managementnet_vm_1  = google_compute_instance.managementnet_vm_1.network_interface[0].access_config[0].nat_ip
    privatenet_vm_1     = google_compute_instance.privatenet_vm_1.network_interface[0].access_config[0].nat_ip
    vm_appliance        = google_compute_instance.vm_appliance.network_interface[0].access_config[0].nat_ip
  }
}

output "vm_internal_ips" {
  description = "Internal (private) IPs of all VMs (one per NIC)"
  value = {
    mynet_vm_1         = google_compute_instance.mynet_vm_1.network_interface[0].network_ip
    mynet_vm_2         = google_compute_instance.mynet_vm_2.network_interface[0].network_ip
    managementnet_vm_1 = google_compute_instance.managementnet_vm_1.network_interface[0].network_ip
    privatenet_vm_1    = google_compute_instance.privatenet_vm_1.network_interface[0].network_ip
    vm_appliance = {
      nic0_privatesubnet_1    = google_compute_instance.vm_appliance.network_interface[0].network_ip
      nic1_managementsubnet_1 = google_compute_instance.vm_appliance.network_interface[1].network_ip
      nic2_mynetwork          = google_compute_instance.vm_appliance.network_interface[2].network_ip
    }
  }
}
