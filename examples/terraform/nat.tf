# NAT Gateway for route all private instance trafic to internet
resource "google_compute_address" "nat" {
    count = 1
    name = "${var.gcp_network}-${var.gcp_region}-${count.index}"
    region = "${var.gcp_region}"
    description = "nat gateway static ip"
}

resource "google_compute_router" "router" {
    name    = "${var.gcp_network}-${var.gcp_region}-router"
    region  = "${var.gcp_region}"
    network = "${google_compute_network.default.self_link}"
    bgp {
        asn = 64514
    }
}
resource "google_compute_router_nat" "nat" {
    name = "${var.gcp_network}-${var.gcp_region}-nat"

    lifecycle {
        ignore_changes = [
            "subnetwork",
            "icmp_idle_timeout_sec",
            "min_ports_per_vm",
            "tcp_established_idle_timeout_sec",
            "tcp_transitory_idle_timeout_sec",
            "udp_idle_timeout_sec"
            ]
    }

    router                             = "${google_compute_router.router.name}"
    region                             = "${var.gcp_region}"
    nat_ip_allocate_option             = "MANUAL_ONLY"
    nat_ips                            = ["${google_compute_address.nat.*.self_link}"]
    source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
    subnetwork {
        name = "${google_compute_subnetwork.prod.self_link}"
    }
    subnetwork {
        name = "${google_compute_subnetwork.stage.self_link}"
    }
    subnetwork {
        name = "${google_compute_subnetwork.dev.self_link}"
    }
}
