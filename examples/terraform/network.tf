# Setup private network/subnetwork for services
resource "google_compute_network" "default" {
  name                    = "${var.gcp_network}"
  description             = "private network for services"
  auto_create_subnetworks = "false"
}

# see https://cloud.google.com/vpc/docs/vpc#subnet-ranges
# see https://www.terraform.io/docs/providers/google/r/compute_subnetwork.html
# see https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips

# DMZ subnetwork
resource "google_compute_subnetwork" "dmz" {
    name          = "dmz"
    ip_cidr_range = "10.0.4.0/24"
    region        = "${var.gcp_region}"
    network       = "${google_compute_network.default.self_link}"
    private_ip_google_access = "true"
    enable_flow_logs = "true"
}

# GKE subnetworks
# nodes /24 cidr   
#   svc /20 cidr
#   pod /16 cider (i.e. nodes_cidr * 256)

# Production GKE subnetwork
resource "google_compute_subnetwork" "prod" {
    name          = "prod"
    ip_cidr_range = "10.0.10.0/24"
    region        = "${var.gcp_region}"
    network       = "${google_compute_network.default.self_link}"
    private_ip_google_access = "true"
    enable_flow_logs = "false"
    secondary_ip_range = [
        {
            range_name    = "svc"
            ip_cidr_range = "10.2.0.0/20"
        },
        {
            range_name    = "pod"
            ip_cidr_range = "10.10.0.0/16"
        }
    ]
}

# Stagging GKE subnetwork
resource "google_compute_subnetwork" "stage" {
    name          = "stage"
    ip_cidr_range = "10.0.11.0/24"
    region        = "${var.gcp_region}"
    network       = "${google_compute_network.default.self_link}"
    private_ip_google_access = "true"
    enable_flow_logs = "false"
    secondary_ip_range = [
        {
            range_name    = "svc"
            ip_cidr_range = "10.2.16.0/20"
        },
        {
            range_name    = "pod"
            ip_cidr_range = "10.11.0.0/16"
        }
    ]
}

# Development GKE subnetwork
resource "google_compute_subnetwork" "dev" {
    name          = "dev"
    ip_cidr_range = "10.0.12.0/24"
    region        = "${var.gcp_region}"
    network       = "${google_compute_network.default.self_link}"
    private_ip_google_access = "true"
    enable_flow_logs = "false"
    secondary_ip_range = [
        {
            range_name    = "svc"
            ip_cidr_range = "10.2.32.0/20"
        },
        {
            range_name    = "pod"
            ip_cidr_range = "10.12.0.0/16"
        }
    ]
}

# User GKE subnetwork
resource "google_compute_subnetwork" "user" {
    name          = "user"
    ip_cidr_range = "10.100.0.0/16"
    region        = "${var.gcp_region}"
    network       = "${google_compute_network.default.self_link}"
    private_ip_google_access = "true"
    enable_flow_logs = "false"
}

# Reserved private ips for google managed services, i.e. CloudSQL, etc.
# see https://cloud.google.com/vpc/docs/configure-private-services-access?hl=en_US&_ga=2.78478358.-387853964.1550029978#allocating-range
# add https://www.terraform.io/docs/providers/google/r/sql_database_instance.html
resource "google_compute_global_address" "google_managed_services" {
    provider        = "google-beta"
    name            = "google-managed-services-${var.gcp_network}"
    purpose         = "VPC_PEERING"
    address_type    = "INTERNAL"
    address         = "192.168.0.0"
    prefix_length   = 16
    network         = "${google_compute_network.default.self_link}"
}

resource "google_service_networking_connection" "google_managed_services" {
  provider      = "google-beta"

  network       = "${google_compute_network.default.self_link}"
  service       = "servicenetworking.googleapis.com"
  reserved_peering_ranges = ["${google_compute_global_address.google_managed_services.name}"]
}


# see https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters
# reserved cidrs for gke masters, /28 CIDR blocks, do not overlap with 172.17.0.0/16.
# prod 172.16.0.16/28
# stage 172.16.0.32/28
# dev 172.16.0.48/28

# reserved cidrs for firestore,  /29 CIDR blocks
# fs-prod 172.16.1.8/29
# fs-stage 172.16.1.16/29
# fs-dev 172.16.1.32/29

# reserved cidrs for redis,  /29 CIDR blocks
# redis-prod 172.16.2.8/29
# redis-stage 172.16.2.16/29
# redis-dev 172.16.2.32/29