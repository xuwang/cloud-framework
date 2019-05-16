

################################################################################
## kube-cluster-tf.mk
# Makefile targets useful for kube cluster ops
################################################################################

ifndef GCP_ENVIRONMENT
	missing_vars := ${missing_vars} GCP_ENVIRONMENT
endif

ifndef GKE_CLUSTER_NAME
	missing_vars := ${missing_vars} GKE_CLUSTER_NAME
endif

ifndef TILLER_IMAGE
	TILLER_IMAGE := gcr.io/kubernetes-helm/tiller:v2.9.1
endif

.PHONY: dryrun
dryrun: tf-plan ## dryrun the privisioning

.PHONY: cluster
cluster: tf-apply ## privision the GKE cluster and other related resources
	@${SCRIPTS_DIR}/config-kube.sh

.PHONY: update-cluster
update-cluster: tf-apply ## update the the GKE cluster and other related resources
	@${SCRIPTS_DIR}/config-kube.sh

destroy-cluster: ## destroy the GKE cluster and other related resources
	@echo "Will run Terraform destroy in ${GCP_ENVIRONMENT}."
	@confirm.sh "Destroy ${GKE_CLUSTER_NAME} in ${GCP_PROJECT_ID} project?"
	@${MAKE} tf-destroy 

.PHONY: cluster-describe
cluster-describe: ## show all the settings of the GKE cluster
	@gcloud container clusters describe ${GKE_CLUSTER_NAME}

.PHONY: cluster-versions
cluster-versions: ## show the available cluster master & node versions for the given zone
	@gcloud container get-server-config --zone=${GKE_CLUSTER_ZONE}

.PHONY: get-images
get-images: config-kube ## List all images running in the cluster
	@kubectl get pods --all-namespaces -o jsonpath="{..image}" | tr -s '[[:space:]]' '\n' | sort | uniq -c

.PHONY: tiller
tiller: config-kube ## install helm tiller
	@if ! kubectl get serviceaccount -n kube-system | grep tiller ; then \
		kubectl create serviceaccount --namespace kube-system tiller ; \
	fi
	@if ! kubectl get clusterrolebinding -n kube-system | grep tiller-cluster-rule ; then \
		kubectl create clusterrolebinding tiller-cluster-rule \
			--clusterrole=cluster-admin \
			--serviceaccount=kube-system:tiller ; \
	fi
	# wait 20s for tiller getting ready
	@if ! kubectl get deployment -n kube-system | grep tiller-deploy ; then \
		helm init --service-account tiller --tiller-image ${TILLER_IMAGE} ; \
		sleep 20 ; \
	else \
		echo "Info: Helm tiller already installed"; \
	fi

.PHONY: upgrade-tiller
upgrade-tiller: config-kube ## upgrade helm tiller
	@if kubectl get deployment -n kube-system | grep tiller-deploy  ; then \
		helm init --service-account tiller --upgrade --tiller-image ${TILLER_IMAGE} ; \
	else \
		echo "ERROR: tiller is not installed, please 'make tiller' first" ; \
	fi
	

.PHONY: destroy-tiller
destroy-tiller: #config-kube ## destroy helm tiller
	kubectl delete --ignore-not-found clusterrolebinding tiller-cluster-rule 
	kubectl delete deployment --ignore-not-found  -n kube-system tiller-deploy
	kubectl delete serviceaccount --ignore-not-found -n kube-system tiller

.PHONY: check-images ## check all running images
check-images: config-kube
	kube-images-report.sh

# eg. allow from myip:
# 	export GKE_AUTHZ_NET="`curl -s ipinfo.io/ip`/32"
# allow from example:
#   export GKE_AUTHZ_NET=171.64.0.0/16,171.65.0.0/16,171.66.0.0/16,128.12.0.0/16
.PHONY: enable-authz-net
enable-authz-net: config ## enable master authorized networks
	@if [ -z ${GKE_AUTHZ_NET} ]; \
	then \
		echo GKE_AUTHZ_NET is not defined; \
	else \
		gcloud container clusters update ${GKE_CLUSTER_NAME} \
			--enable-master-authorized-networks \
			--master-authorized-networks ${GKE_AUTHZ_NET}; \
		echo Cluster ${GKE_CLUSTER_NAME} API can be accessed only from ${GKE_AUTHZ_NET} now ; \
	fi

.PHONY: disable-authz-net
disable-authz-net: config ## disable master authorized networks
	@gcloud container clusters update ${GKE_CLUSTER_NAME} \
			--no-enable-master-authorized-networks
	@echo Cluster ${GKE_CLUSTER_NAME} API can be accessed from anywhere now

.PHONY: enable-net-policy
enable-net-policy: config ## enable clsuter network policy
	@gcloud container clusters update ${GKE_CLUSTER_NAME} --update-addons=NetworkPolicy=ENABLED
	@gcloud container clusters update ${GKE_CLUSTER_NAME} --enable-network-policy
	echo Network policy is enabled for cluster ${GKE_CLUSTER_NAME}

.PHONY: disable-net-policy
disable-net-policy: config ## disable cluster network policy
	@gcloud container clusters update ${GKE_CLUSTER_NAME} --no-enable-network-policy
	echo Network policy is disabled for cluster ${GKE_CLUSTER_NAME}

.PHONY: gke-versions
gke-versions: ## show availabe gke/kubernetes versions
	gcloud container get-server-config --zone=${GKE_CLUSTER_ZONE}

.PHONY: get-ops
get-ops: ## List cluster operations for GKE
	@gcloud container operations list

.PHONY: grant-cluster-admin
grant-cluster-admin: config-kube ## Grant the cluster admin role (cluster-admin) to your GCP account.
	user=$$(gcloud config get-value account); \
	kubectl create clusterrolebinding cluster-admin-$$user \
		--clusterrole=cluster-admin \
		--user=$$user

.PHONY: revoke-cluster-admin
revoke-cluster-admin: config-kube ## Revoke the cluster admin role of your GCP account.
	user=$$(gcloud config get-value account); \
	kubectl delete clusterrolebindings cluster-admin-$$user   \
		--ignore-not-found 

# https://cloud.google.com/kubernetes-engine/docs/how-to/add-on/service-catalog/install-service-catalog
.PHONY: install-sc 
install-sc: grant-cluster-admin ## Install the Kubernetes Service Catalog into the cluster
	sc check
	sc install
	sc add-gcp-broker

.PHONY: check-sc
check-sc: config-kube ## To check service catalog  status
	# Verify that Service Catalog components are ready 
	kubectl get deployment -n service-catalog
	# Verify that Service Broker is available and ready:
	kubectl get clusterservicebrokers -o 'custom-columns=BROKER:.metadata.name,STATUS:.status.conditions[0].reason'

## Cluster operations
.PHONY: cordon
cordon: NODES = $$(kubectl get node -o json  | jq -r '.items[].metadata.name')
cordon: config-kube  ## Disable scheduling on a node
	@NODES=$$(kubectl get node -o json  | jq -r '.items[].metadata.name'); \
		for i in ${NODES}; do \
			kubectl get node $$i ; \
			echo "" ; \
			echo "Cordon $$i?" ; \
			confirm.sh 2> /dev/null || continue ; \
			kubectl cordon $$i ; \
		done

.PHONY: drain
drain: NODES = $$(kubectl get node -o json  | jq -r '.items[].metadata.name')
drain: config-kube  ## Drain workload on a node
	@NODES=$$(kubectl get node -o json  | jq -r '.items[].metadata.name'); \
		for i in ${NODES}; do \
			kubectl get node $$i ; \
			echo "" ; \
			echo "Drain $$i?" ; \
			confirm.sh 2> /dev/null || continue ; \
			kubectl drain $$i --ignore-daemonsets --delete-local-data ; \
		done

.PHONY: uncordon
uncordon: NODES = $(shell kubectl get node -o json  | jq -r '.items[].metadata.name')
uncordon: ## Enable scheduling on a node
	@NODES=$$(kubectl get node -o json  | jq -r '.items[].metadata.name'); \
		for i in ${NODES}; do \
			kubectl get node $$i ; \
			echo "" ; \
			echo "Uncordon $$i?" ; \
			confirm.sh 2> /dev/null || continue ; \
			kubectl uncordon $$i ; \
		done