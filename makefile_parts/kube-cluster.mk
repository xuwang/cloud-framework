

################################################################################
## kube-cluster.mk
# Makefile targets useful for kube cluster ops
################################################################################

ifndef GCP_ENVIRONMENT
	missing_vars := ${missing_vars} GCP_ENVIRONMENT
endif

ifndef GKE_CLUSTER_NAME
	missing_vars := ${missing_vars} GKE_CLUSTER_NAME
endif

ifndef GKE_CLUSTER_ZONE
	missing_vars := ${missing_vars} GKE_CLUSTER_ZONE
endif

ifndef GKE_CLUSTER_MACHINE_TYPE
	missing_vars := ${missing_vars} GKE_CLUSTER_MACHINE_TYPE
endif

ifndef GKE_CLUSTER_NUM_NODES
	missing_vars := ${missing_vars} GKE_CLUSTER_NUM_NODES
endif

ifndef TILLER_IMAGE
	TILLER_IMAGE := gcr.io/kubernetes-helm/tiller:v2.9.1
endif

.PHONY: cluster
cluster: config-gcloud  ## build GKE cluster
	@echo building GKE Cluster: ${GKE_CLUSTER_NAME}
	@echo GCP_ENVIRONMENT=${GCP_ENVIRONMENT}
	@echo GCP_PROJECT_ID=${GCP_PROJECT_ID}
	@${SCRIPTS_DIR}/create-cluster.sh
	@${SCRIPTS_DIR}/config-kube.sh

.PHONY: destroy-cluster
destroy-cluster: config-kube ## destroy the GKE cluster
	@echo "Please make sure ALL APPS/SERVICES hosted on this cluster have been destroyed before destroy the cluster."
	@read -p "Are you sure to DESTROY cluster ${GKE_CLUSTER_NAME}? [YES/NO] " ; \
	if [ "$$REPLY" = 'YES' ] ; \
	then \
		${SCRIPTS_DIR}/delete-cluster.sh;  \
	else \
		echo "Destroy canceled" ; \
	fi

.PHONY: cluster-describe
cluster-describe: ## show all the settings of the GKE cluster
	@gcloud container clusters describe ${GKE_CLUSTER_NAME}

.PHONY: cluster-versions
cluster-versions: ## show the available cluster master & node versions for the given zone
	@gcloud container get-server-config --zone=${GKE_CLUSTER_ZONE}

.PHONY: cluster-upgrade-nodes
cluster-upgrade-nodes: ## upgrade the cluster's nodes to a new version
	@gcloud container get-server-config --zone=${GKE_CLUSTER_ZONE}
	@echo Enter in the node version you want to upgrade to: 
	@read node_version && \
	 	echo "upgrading to node version '$$node_version' (non-blocking, please monitor)" && \
		gcloud container clusters upgrade ${GKE_CLUSTER_NAME} --cluster-version $$node_version --zone=${GKE_CLUSTER_ZONE} --async

.PHONY: get-images
get-images: config-kube ## List all images running in the cluster
    @kubectl get pods --all-namespaces -o jsonpath="{..image}" | tr -s '[[:space:]]' '\n' | sort | uniq -c

.PHONY: tiller
tiller: config-kube ## install/upgrade helm tiller
	kubectl create serviceaccount --namespace kube-system tiller
	kubectl --username=admin \
			--password=`${SCRIPTS_DIR}/kube-admin-pass.sh` \
		create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
	#kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
	helm init --service-account tiller --upgrade --tiller-image ${TILLER_IMAGE}

.PHONY: destroy-tiller
destroy-tiller: config-kube ## destroy helm tiller
	kubectl delete --ignore-not-found serviceaccount --namespace kube-system tiller
	kubectl --username=admin \
			--password=`${SCRIPTS_DIR}/kube-admin-pass.sh` \
		delete --ignore-not-found clusterrolebinding tiller-cluster-rule
	kubectl -n "kube-system" delete --ignore-not-found deployment tiller-deploy

.PHONY: tag-nodes
tag-nodes: config-kube ## tag the cluster nodes for NAT
	tag-nodes-for-nat.sh ${GCP_NAT_TAGS}

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