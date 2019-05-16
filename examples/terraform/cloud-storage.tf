// Provision Cloud Storage Buckets
// https://www.terraform.io/docs/providers/google/r/storage_bucket.html
// 

// Bucket for the artifactsyes
resource "google_storage_bucket" "artifacts" {
    name     = "${var.gcp_artifacts_bucket}"
    location = "us"
    labels = {
        "app" = "project-setup"
        "env" = "prod"
    }
    
    // delete bucket and contents on destroy.
    force_destroy = "false"
}
