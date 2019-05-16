

################################################################################
## disk.mk
# Makefile goals for persistent disk/volume management
################################################################################

ifndef DISK_DEF_FILE
	export DISK_DEF_FILE=${COMMON}/disks.def
endif

.PHONY: create-disk
create-disks: config-gcloud ## create persistent disks
	@if [ -a ${DISK_DEF_FILE} ]; then \
		${SCRIPTS_DIR}/disk-create-all.sh ${DISK_DEF_FILE} ; \
	fi

.PHONY: destroy-disks
destroy-disks: config-gcloud destroy-pv ## destroy persistent disks
	@if [ -a ${DISK_DEF_FILE} ]; then \
		${SCRIPTS_DIR}/disk-rm-all.sh ${DISK_DEF_FILE} ; \
	fi

.PHONY: snapshot-disks
snapshot-disks: config-gcloud ## snapshot pd disks
	@if [ -a ${DISK_DEF_FILE} ]; then \
		${SCRIPTS_DIR}/disk-snapshot-all.sh ${DISK_DEF_FILE}; \
	fi

.PHONY: describe-disks
describe-disks: config-gcloud ## describe pd disks
	@if [ -a ${DISK_DEF_FILE} ]; then \
		${SCRIPTS_DIR}/disk-describe-all.sh ${DISK_DEF_FILE}; \
	fi

.PHONY: resize-disks
resize-disks: config-gcloud ## resize pd disks
	@if [ -a ${DISK_DEF_FILE} ]; then \
		${SCRIPTS_DIR}/disk-resize-all.sh ${DISK_DEF_FILE}; \
	fi
	# See K8s PV/PVC resize issue: https://github.com/kubernetes/features/issues/284

.PHONY: create-pv
create-pv: config-kube create-disks ## create gke pv
	@if [ -a ${TEMPLATES}/pv.yml ]; then \
		kube_apply.sh ${TEMPLATES}/pv.yml ; \
	fi
	@for i in ${TEMPLATES}/*-pv.yml; do \
		kube_apply.sh $$i ; \
	done

.PHONY: create-pvc
create-pvc: create-pv ## create gke pvc
	@if [ -a ${TEMPLATES}/pvc.yml ]; then \
		kube_apply.sh ${TEMPLATES}/pvc.yml ; \
	fi
	@for i in ${TEMPLATES}/*-pvc.yml; do \
		kube_apply.sh $$i ; \
	done

.PHONY: destroy-pvc
destroy-pvc: config-kube ## destroy gke pvc
	@if [ -a ${TEMPLATES}/pvc.yml ]; then \
		kube_delete.sh ${TEMPLATES}/pvc.yml ; \
	fi
	@for i in ${TEMPLATES}/*-pvc.yml; do \
		kube_delete.sh $$i ; \
	done

.PHONY: destroy-pv
destroy-pv: destroy-pvc ## destroy gke pv
	@if [ -a ${TEMPLATES}/pv.yml ]; then \
		kube_delete.sh ${TEMPLATES}/pv.yml ; \
	fi
	@for i in ${TEMPLATES}/*-pv.yml; do \
		kube_delete.sh $$i ; \
	done

## end of disk.mk
