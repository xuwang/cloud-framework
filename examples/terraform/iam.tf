# iam bindings

# We must use Non-authoritative IAM bindings, 
# because there are other party, GOOGLE, may also make changes.
# See https://www.terraform.io/docs/providers/google/r/google_project_iam.html
# NOTE: DO NOT managing project owner in terraform, it may lock youself out.

resource "google_project_iam_member" "svc_provision" {
  project = "${var.gcp_project_id}"
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.provision.email}"
}

# Permistions for dev_ops
resource "google_project_iam_member" "dev_ops_editor" {
  project = "${var.gcp_project_id}"
  role    = "roles/editor"
  member  =  "group:devops@example.com"
}
# Grants all permissions related to KMS
resource "google_project_iam_member" "dev_ops_kms_admin" {
  project = "${var.gcp_project_id}"
  role    = "roles/cloudkms.admin"
  member  =  "group:devops@example.com"
}
# Grants all permissions to KMS encrypter/decripter
resource "google_project_iam_member" "dev_ops_kms_user" {
  project = "${var.gcp_project_id}"
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  =  "group:devops@example.com"
}
# Grants all permissions related to project IAM
resource "google_project_iam_member" "dev_ops_iam" {
  project = "${var.gcp_project_id}"
  role    = "roles/resourcemanager.projectIamAdmin"
  member  =  "group:devops@example.com"
}
# Grants all permissions related to Stackdriver Logging
resource "google_project_iam_member" "dev_ops_logging" {
  project = "${var.gcp_project_id}"
  role    = "roles/logging.admin"
  member  =  "group:devops@example.com"
}
# Grants permissions related to Stackdriver Log config
# see https://www.terraform.io/docs/providers/google/r/logging_project_sink.html
resource "google_project_iam_member" "dev_ops_log_config" {
  project = "${var.gcp_project_id}"
  role    = "roles/logging.configWriter"
  member  =  "group:devops@example.com"
}
# Grants all permissions related to GKE
resource "google_project_iam_member" "dev_ops_gke" {
  project = "${var.gcp_project_id}"
  role    = "roles/container.admin"
  member  =  "group:devops@example.com"
}
# https://cloud.google.com/kubernetes-engine/docs/how-to/iam#host_service_agent_user
resource "google_project_iam_member" "dev_ops_svc" {
  project = "${var.gcp_project_id}"
  role    = "roles/iam.serviceAccountUser"
  member  =  "group:devops@example.com"
}
# Needed to create/delete bucket
resource "google_project_iam_member" "dev_ops_storage_admin" {
  project = "${var.gcp_project_id}"
  role    = "roles/storage.admin"
  member  =  "group:devops@example.com"
}
# Needed to setup cloud sql private ip connection
resource "google_project_iam_member" "dev_ops_net_peering" {
  project = "${var.gcp_project_id}"
  role    = "roles/servicenetworking.networksAdmin"
  member  =  "group:devops@example.com"
}

resource "google_project_iam_member" "svc_gcr_user" {
  project = "${var.gcp_project_id}"
  role    = "roles/storage.objectAdmin"
  member  =  "serviceAccount:${google_service_account.gcr_user.email}"
}

resource "google_project_iam_member" "svc_gcr_pull" {
  project = "${var.gcp_project_id}"
  role    = "roles/storage.objectViewer"
  member  =  "serviceAccount:${google_service_account.gcr_pull.email}"
}
