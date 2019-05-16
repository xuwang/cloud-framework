# Default service account for this project

# For provisioning
resource "google_service_account" "provision" {
    account_id = "provision"
    display_name = "provision"
}

resource "google_service_account" "gcr_user" {
    account_id = "gcr-user"
    display_name = "gcr-user"
}

resource "google_service_account" "gcr_pull" {
    account_id = "gcr-pull"
    display_name = "gcr-pull"
}

resource "google_service_account" "dns_admin" {
    account_id = "dns-admin"
    display_name = "dns-admin"
}

