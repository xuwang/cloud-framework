#Bastion host

locals {
    bastion = "${var.gcp_network}-bastion"
} 

resource "google_compute_address" "bastion" {
    #name = "${local.bastion}"

    # NOTE: reuse the old nat ip by import:
    name = "nat-us-west1-a"
    region = "${var.gcp_region}"
}

resource "google_dns_record_set" "bastion" {
  name = "${local.bastion}.example.com."
  type = "A"
  ttl  = 300

  managed_zone = "${var.dns_managed_zone}"
  project = "${var.dns_project_id}"

  rrdatas = ["${google_compute_address.bastion.address}"]
}

resource "google_compute_instance" "bastion" {
  name         = "${local.bastion}"
  machine_type = "n1-standard-1"
  zone         = "${var.gcp_zone}"

  tags = [ 
        "bastion",     
        "allow-ssh"
  ]

  boot_disk {
    device_name = "${local.bastion}"
    initialize_params {
      image     = "cos-cloud/cos-stable"
      size      = "100"
    }
  }
  
  network_interface {
    subnetwork  = "${google_compute_subnetwork.dmz.self_link}"
    access_config {
        nat_ip      = "${google_compute_address.bastion.address}"
    }
  }

  metadata { 
  }

  service_account {
    scopes = [
        "https://www.googleapis.com/auth/servicecontrol", 
        "https://www.googleapis.com/auth/service.management.readonly", 
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring.write",
        "https://www.googleapis.com/auth/trace.append",
        "https://www.googleapis.com/auth/devstorage.read_write"
        ]
  }
  
  scheduling {
    on_host_maintenance = "MIGRATE"
  }
}

# Allow ssh from bastion to all allow-ssh instances
resource "google_compute_firewall" "allow_ssh" {
  name            = "allow-ssh-from-${local.bastion}"
  description     = "allow ssh from bastion to all allow-ssh instances"
  network         = "${google_compute_network.default.name}"
  source_tags     = ["bastion"]
  target_tags     = ["${var.allow_ssh_tags}"]

  allow {
    protocol      = "tcp"
    ports         = ["22"]
  }
}

# Allow ssh bastion from ssh_source_ranges
resource "google_compute_firewall" "allow_bastion" {
  name            = "allow-${local.bastion}"
  description     = "allow ssh to bastion"
  network         = "${google_compute_network.default.name}"
  source_ranges   = "${var.ssh_source_ranges}"
  target_tags     = ["bastion"]

  allow {
    protocol      = "tcp"
    ports         = ["22"]
  }
}

output "bastion_fqdn" {
    value="${local.bastion}.example.com"
}

output "bastion_address" {
    value="${google_compute_address.bastion.address}"
}