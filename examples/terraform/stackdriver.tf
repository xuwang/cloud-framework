
# A bucket to store logs in
resource "google_storage_bucket" "logs" {
    name     = "${var.gcp_project_name}-logs"
    location = "us"

    labels = {
        "app" = "stackdriver"
        "env" = "prod"
    }

    // delete bucket and contents on destroy.
    force_destroy = "false"

    // lifecycle policies for log data
    // delete logs that 365 days old
    lifecycle_rule {
        action {
            type = "Delete"
        }
        condition {
            age = 365,
            is_live = false
        }
    }
}

# Our sink; this logs all activity related to our "my-logged-instance" instance
resource "google_logging_project_sink" "log_sink" {
    name = "${var.gcp_project_name}-log-sink"
    destination = "storage.googleapis.com/${google_storage_bucket.logs.name}"
    filter = "${var.log_sink_filter}"
    
    unique_writer_identity = true
}

# Because our sink uses a unique_writer, we must grant that writer access to the bucket.
resource "google_storage_bucket_iam_member" "log_sink_writer" {
  bucket = "${google_storage_bucket.logs.name}"
  role    = "roles/storage.objectAdmin"
  member  =  "${google_logging_project_sink.log_sink.writer_identity}"
}

# For bucket usage analytics logging, 
# we must set permissions to allow Cloud Storage WRITE permission to the bucket.
# See https://cloud.google.com/storage/docs/access-logs
resource "google_storage_bucket_acl" "storage_analytics_writer" {
    bucket = "${google_storage_bucket.logs.name}"
    default_acl = "projectPrivate"
    role_entity = [
        "WRITER:group-cloud-storage-analytics@google.com"
    ]

    lifecycle {
        ignore_changes = ["role_entity"]
    }
}

# NOTE:  according to the google cloud documentation
# sink_writer access is granted by bucket IAM
# storage_analytics_writer access is granted by bucket ACL