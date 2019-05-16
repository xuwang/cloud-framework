# The services/APIs that are enabled for this project.
# For a list of available services, run "gcloud service-management list"
# https://www.terraform.io/docs/providers/google/r/google_project_services.html

# NOT Controled by TF yet!

# List current enabled services
# gcloud services list --enabled --format="value(NAME)" | xargs -L 1 -I{} echo \"{}\",

// resource "google_project_services" "project_services" {
// 	project = "${var.gcp_project_id}"

// 	# Don't desable project services when destroy 
// 	disable_on_destroy = false

// 	# Services/APIs to be enabled
//     # NOTE: there are implicit dependences on google APIs
//     # so be very careful to remove or add APIs to this list!
//  	services = [        
//         "bigquery-json.googleapis.com",
//         "file.googleapis.com",
//         "clouddebugger.googleapis.com",
//         "cloudresourcemanager.googleapis.com",
//         "datastore.googleapis.com",
//         "pubsub.googleapis.com",
//         "container.googleapis.com",
//         "ml.googleapis.com",
//         "logging.googleapis.com",
//         "bigtableadmin.googleapis.com",
//         "replicapool.googleapis.com",
//         "cloudapis.googleapis.com",
//         "deploymentmanager.googleapis.com",
//         "containerregistry.googleapis.com",
//         "endpoints.googleapis.com",
//         "monitoring.googleapis.com",
//         "redis.googleapis.com",
//         "dns.googleapis.com",
//         "oslogin.googleapis.com",
//         "compute.googleapis.com",
//         "iam.googleapis.com",
//         "cloudkms.googleapis.com",
//         "cloudtrace.googleapis.com",
//         "replicapoolupdater.googleapis.com",
//         "servicemanagement.googleapis.com",
//         "sqladmin.googleapis.com",
//         "servicebroker.googleapis.com",
//         "spanner.googleapis.com",
//         "storage-api.googleapis.com",
//         "servicecontrol.googleapis.com",
//         "stackdriver.googleapis.com",
//         "resourceviews.googleapis.com",
//         "stackdriverprovisioning.googleapis.com",
//         "serviceusage.googleapis.com",
//         "sql-component.googleapis.com",
//         "storage-component.googleapis.com"
//    	]

// 	# Allow external changes
// 	lifecycle {
//         ignore_changes = ["services"]
//     }
// }
