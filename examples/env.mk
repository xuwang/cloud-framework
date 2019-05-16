# GCLOUD Configuration
export GOOGLE_CLOUD_PROJECT=my-gcp-example
export GCP_PROJECT_ID=${GOOGLE_CLOUD_PROJECT}
export GCP_PROJECT_NAME=${GOOGLE_CLOUD_PROJECT}
export GCP_VPC_NAME=my-vpc
export GCP_ENVIRONMENT=default
export GCP_CONFIGURATION=${GCP_PROJECT_NAME}-${GCP_ENVIRONMENT}
export GCP_REGION=us-west1
export GCP_ZONE=${GCP_REGION}-a

# For StackDriver Loggin and Monitoring
export GCP_MONITORING_PROJECT_ID=${GCP_PROJECT_ID}
export GCP_SLACK_CHANNEL=my-svc-alerts

# Force gcloud auth with user credentials
export GCP_USER_AUTH=true

# Cloud Framework (Scripts, shared config, etc.)
export FRAMEWORK_DIR=${HOME}/bin/cloud-framework
export FRAMEWORK_BUCKET=cloud-framework
export SCRIPTS_DIR=${FRAMEWORK_DIR}/scripts

# Vault and secrets configuration
export VAULT_ADDR=https://vault.example.com
export VAULT_AUTH_METHOD=ldap
export VAULT_CACHE=${HOME}/.vault-local
export SEC_PATH=secret/projects/${GCP_PROJECT_NAME}
export GCP_KEY_PATH=${SEC_PATH}/common/gcp-provision
export GCP_KEY_FILE=${VAULT_CACHE}/${GCP_KEY_PATH}

# Drone env
export DRONE_SERVER=https://drone.example.com
export DRONE_TOKEN_FILE=${HOME}/.drone-token

# SONARQUBE env
export SONARQUBE_SERVER=https://sonarqube.example.com
export SONARQUBE_TONKE_FILE=${HOME}/.sonar-token

# GCP artifacts bucket
export GCP_ARTIFACTS_BUCKET=${GCP_PROJECT_NAME}-artifacts

# Required by Terraform
export GCP_INFRASTRUCTURE_BUCKET=${GCP_PROJECT_ID}-infrastructure
export TF_BACKEND_PREFIX=terraform/${GCP_PROJECT_ID}/${GCP_ENVIRONMENT}/state

# GCP Networking
export GCP_NETWORK=${GCP_VPC_NAME}
export GCP_DNS_DOMAIN=example.com
export GCP_NAT_TAGS=nat

# For external-dns and cert-manager/ACME
export EXTERNAL_DNS_GOOGLE_PROJECT=${GCP_PROJECT_ID}
export ACME_DNS_PROVIDER=${EXTERNAL_DNS_GOOGLE_PROJECT}-dns


# Sub-projects dir 
export SUB_PROJECTS=sub-projects

# GKE Configuration
export GKE_CLUSTER_NAME=${GCP_ENVIRONMENT}-${GCP_VPC_NAME}
export GKE_NODE_TAG=${GCP_NAT_TAGS}
export KUBE_CONTEXT=${GKE_CLUSTER_NAME}

# set kube config default namespace
export KUBE_NAMESPACE=${APP_NAMESPACE}

# reserved cidrs for gke masters,  /28 CIDR blocks
export GKE_MASTER_CIDR_PROD=172.16.0.16/28
export GKE_MASTER_CIDR_STAGE=172.16.0.32/28
export GKE_MASTER_CIDR_DEV=172.16.0.48/28

# reserved cidrs for firestore,  /29 CIDR blocks
export FS_CIDR_STAGE=172.16.1.8/29
export FS_CIDR_PROD=172.16.1.16/29
export FS_CIDR_DEV=172.16.1.32/29
export FS_TIER=STANDARD
# capacity in number of TB
export FS_CAPACITY=1
export FS_NAME=filestore-${GCP_ENVIRONMENT}

#########
# Storage buckets created and used in gke-cluster for each env

# gitlab backup bucket
export GITLAB_BACKUP_BUCKET=${GCP_ENVIRONMENT}-${GCP_PROJECT_NAME}-gitlab-backup
export GITLAB_BACKUP_BUCKET_LOCATION=US
export FORCE_DESTROY_GITLAB_BACKUP_BUCKET=true

# docker registry bucket
export REGISTRY_BUCKET=${GCP_ENVIRONMENT}-${GCP_PROJECT_NAME}-container-registry
export REGISTRY_BUCKET_LOCATION=US
export FORCE_DESTROY_REGISTRY_BUCKET=true

# nexus data bucket
export NEXUS_BUCKET=${GCP_ENVIRONMENT}-${GCP_PROJECT_NAME}-nexus-data
export NEXUS_BUCKET_LOCATION=US
export FORCE_DESTROY_NEXUS_BUCKET=true

# spinnaker
export SPINNAKER_BUCKET=${GCP_PROJECT_NAME}-spinnaker

############
# Cloud SQL
export MYSQL_SEC_PATH=${SEC_PATH}/cloud-sql/mysql
export POSTGRES_SEC_PATH=${SEC_PATH}/cloud-sql/postgres