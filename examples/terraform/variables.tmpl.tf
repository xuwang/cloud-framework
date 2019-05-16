#!gomplate

variable "gcp_project_id" { 
    default = "{{.Env.GCP_PROJECT_ID}}" 
}
variable "gcp_project_name" {
     default = "{{.Env.GCP_PROJECT_NAME}}" 
}
variable "gcp_region" { 
    default = "{{.Env.GCP_REGION}}" 
}
variable "gcp_zone" { 
    default = "{{.Env.GCP_ZONE}}" 
}
variable "gcp_environment" { 
    default = "{{.Env.GCP_ENVIRONMENT}}" 
}
variable "gcp_network" { 
    default = "{{.Env.GCP_NETWORK}}" 
}

variable "gcp_artifacts_bucket" {
    default = "{{.Env.GCP_ARTIFACTS_BUCKET}}"
}

# DNS config
variable "gcp_dns_domain" { 
    description = "DNS domain."
    default = "{{.Env.GCP_DNS_DOMAIN}}"
}
variable "dns_project_id" {
    description = "DNS hosting project ID"
    default = "gcp-example"
}
variable "dns_managed_zone" {
    description = "Managed DNS zone name"
    default = "example.com"
}

variable "ssh_source_ranges" {
    description = "Authorized ssh source ranges to access bastion"
    type = "list"
    default = [ 
        "0.0.0.0/0"
    ]
}
variable "allow_ssh_tags" {
    description = "Allow ssh instance tags"
    type = "list"
    default = [ 
        "{{.Env.GKE_NODE_TAG}}", "allow-ssh"
    ]
}
# See https://cloud.google.com/logging/docs/view/advanced-filters
variable "log_sink_filter" {
    description = "Stackdriver log sink filter"
    default = ""
}

# Cloud SQL
variable "mysql_sec_path" {
    description = "vault path for mysql admin pass"
    default = "{{ .Env.MYSQL_SEC_PATH }}"
}

variable "postgres_sec_path" {
    description = "vault path for postgres admin pass"
    default = "{{ .Env.POSTGRES_SEC_PATH }}"
}

# env (default: prod)
# region (default: us-west1)
# zone (default: us-west1-a )
# db_version (default: POSTGRES_9_6)
# backup_enabled (default: true)
# backup_time (default: 2:30)
# tier (default: db-f1-micro)
# disk_type (default: PD_SSD)
# disk_size (default: 10)
# disk_auto (default: true)
# activation_policy (default: ALWAYS)
# availability_type (default: ZONAL)
# require_ssl (default: false)
# ipv4_enabled (default: true)
# maintenance_day (default: 1)
# maintenance_hour (default: 2)
# maintenance_track (default: stable)
variable "postgres_conf" {
    description = "cloud sql postgres configuration"
    type        = "map"
    default     = {
        region              = "{{ .Env.GCP_REGION }}"
        zone                = "{{ .Env.GCP_ZONE }}"
        tier                = "db-custom-2-7168"
        availability_type   = "REGIONAL"
    }
}
# Postgres only supports shared-core machine types (i.e. `db-f1-micro`, `db-g1-small`) and custom
# machine types (see Google's [Postgres Pricing Page](https://cloud.google.com/sql/docs/postgres/pricing)).
# For custom machine types the number of CPUs and the amount of memory (expressed in `MiB = GB *
# 1024`) is encoded in the tier as: `db-custom-{CPUS}-{MEMORY}`. For a machine with 1 CPU and
# 4GB of memory the tier would be `db-custom-1-4096`, for 2 CPUs and 13GB of ram it would be
# `db-custom-2-13312`.
# Only certain combinations of CPU and memory are allowed, see Google's 
# [Custom Machine Type Documentation](https://cloud.google.com/compute/docs/instances/creating-instance-with-custom-machine-type#create).

variable "authorized_networks" {
    description = "cloud sql authorized_networks"
    type = "list"   # of map(name,value)
    default = []
}

variable "slack_channel" {
    description = "slack channel for stackdriver alert notifactions"
    default = ""
}