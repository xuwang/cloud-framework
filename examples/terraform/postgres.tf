locals {
    env = "${lookup(var.postgres_conf, "env", "prod")}"
    region = "${lookup(var.postgres_conf, "region", "us-west1")}"
    zone = "${lookup(var.postgres_conf, "zone", "us-west1-a")}"
    admin = "${lookup(var.postgres_conf, "admin_user", "admin")}"
    name = "postgres-${local.env}-${local.region}"
    authorized_networks = [ 
        "${var.authorized_networks}",
        {
            name = "allow-from-nat"
            value = "${google_compute_address.nat.address}/32"
        }
    ]
}

# Instance CloudSQL
# https://www.terraform.io/docs/providers/google/r/sql_database_instance.html
resource "google_sql_database_instance" "sql" {
    provider            = "google-beta"
    name                = "${local.name}"
    region              = "${local.region}"
    database_version = "${lookup(var.postgres_conf, "db_version", "POSTGRES_9_6")}"

    depends_on = [
        "google_service_networking_connection.google_managed_services"
    ]
    
    settings {
        tier                        = "${lookup(var.postgres_conf, "tier", "db-f1-micro")}"
        disk_type                   = "${lookup(var.postgres_conf, "disk_type", "PD_SSD")}"
        disk_size                   = "${lookup(var.postgres_conf, "disk_size", 10)}"
        disk_autoresize             = "${lookup(var.postgres_conf, "disk_auto", true)}"
        activation_policy           = "${lookup(var.postgres_conf, "activation_policy", "ALWAYS")}"
        availability_type           = "${lookup(var.postgres_conf, "availability_type", "ZONAL")}"
        user_labels                 = {}

        ip_configuration {
            require_ssl  = "${lookup(var.postgres_conf, "require_ssl", false)}"
            ipv4_enabled = "${lookup(var.postgres_conf, "ipv4_enabled", true)}"
            authorized_networks = ["${local.authorized_networks}"]
            private_network = "${google_compute_network.default.self_link}"
        }

        location_preference {
            zone = "${local.zone}"
        }

        backup_configuration {
            binary_log_enabled = false
            enabled            = "${lookup(var.postgres_conf, "backup_enabled", true)}"
            start_time         = "${lookup(var.postgres_conf, "backup_time", "10:30")}" # every 2:30AM (UTC-8)
        }

        maintenance_window {
            day          = "${lookup(var.postgres_conf, "maintenance_day", 1)}"          # Monday
            hour         = "${lookup(var.postgres_conf, "maintenance_hour", 10)}"         # 2AM
            update_track = "${lookup(var.postgres_conf, "maintenance_track", "stable")}"
        }
    }
}

# Open firewall to allow private connections to sql within vpc
resource "google_compute_firewall" "allow_private_sql" {
  name            = "allow-sql-in-vpc"
  description     = "allow private connections to ${local.name} within vpc"
  network         = "${google_compute_network.default.name}"
  direction       = "EGRESS"
  destination_ranges = ["${google_sql_database_instance.sql.private_ip_address}/32"]

  allow {
    protocol      = "tcp"
    ports         = ["5432"]
  }
}

resource "google_sql_user" "postgres_admin" {
    name     = "admin"
    instance = "${google_sql_database_instance.sql.name}"
    password = "${random_string.postgres_pass.result}"
  
    provisioner "local-exec" {
        command = <<EOF
            vault write ${var.postgres_sec_path}/admin_user format=text value="admin"
            vault write ${var.postgres_sec_path}/admin_pass format=text value="${self.password}"
            vault write ${var.postgres_sec_path}/connection_name format=text value="${google_sql_database_instance.sql.connection_name}"
            vault write ${var.postgres_sec_path}/ip_address format=text value="${google_sql_database_instance.sql.first_ip_address}"
            vault write ${var.postgres_sec_path}/private_ip_address format=text value="${google_sql_database_instance.sql.private_ip_address}"
            vault write ${var.postgres_sec_path}/public_uri format=text value="postgres://admin:${self.password}@${google_sql_database_instance.sql.first_ip_address}:5432"
            vault write ${var.postgres_sec_path}/private_uri format=text value="postgres://admin:${self.password}@${google_sql_database_instance.sql.private_ip_address}:5432"
EOF
    }
    provisioner "local-exec" {
        when = "destroy"
        command = <<EOF
            vault delete ${var.postgres_sec_path}/admin_user
            vault delete ${var.postgres_sec_path}/admin_pass
            vault delete ${var.postgres_sec_path}/connection_name
            vault delete ${var.postgres_sec_path}/ip_address
            vault delete ${var.postgres_sec_path}/private_ip_address
            vault delete ${var.postgres_sec_path}/private_uri
            vault delete ${var.postgres_sec_path}/public_uri
EOF
    }
}

# For generate default admin password
resource "random_string" "postgres_pass" {
    length  = 30
    special = false
    number  = true
    lower   = true
    upper   = true
}

resource "google_sql_database" "gitlab_prod" {
  name      = "gitlab_prod"
  instance = "${google_sql_database_instance.sql.name}"
}

resource "google_sql_database" "gitlab_stage" {
  name      = "gitlab_stage"
  instance = "${google_sql_database_instance.sql.name}"
}

resource "google_sql_database" "gitlab_dev" {
  name      = "gitlab_dev"
  instance = "${google_sql_database_instance.sql.name}"
}

resource "google_sql_database" "sonar_prod" {
  name      = "sonar_prod"
  instance = "${google_sql_database_instance.sql.name}"
}

resource "google_sql_database" "sonar_stage" {
  name      = "sonar_stage"
  instance = "${google_sql_database_instance.sql.name}"
}

resource "google_sql_database" "sonar_dev" {
  name      = "sonar_dev"
  instance = "${google_sql_database_instance.sql.name}"
}

output "postgres_name" {
    value = "${local.name}"
}

output "postgres_url" {
    value = "${google_sql_database_instance.sql.self_link}"
}

output "postgres_connection_name" {
    value = "${google_sql_database_instance.sql.connection_name}"
}

output "postgres_ipv4" {
    value = "${google_sql_database_instance.sql.first_ip_address}"
}

output "postgres_private_ipv4" {
    value = "${google_sql_database_instance.sql.private_ip_address}"
}

