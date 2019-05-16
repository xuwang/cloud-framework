#!/bin/bash
# Used by makefile_parts/terraform.mk
# to initalized the terraform build dir

# defaults
TF_MODULES_DIR=${TF_MODULES_DIR:-terraform-modules}
TF_DIR=${TF_DIR:-terraform}
TF_BUILD_DIR=${TF_TF_BUILD_DIR:-build}

# Copy TF_BUILD_DIR from TF_DIR, if missing
if [ -d ${TF_DIR} ]
then 
	if [ -d ${TF_BUILD_DIR} ]
	then
		echo "Update ${TF_BUILD_DIR} ..."
		rsync -dr --delete ${TF_DIR}/ ${TF_BUILD_DIR}
	else
		echo "Copy ${TF_BUILD_DIR} from ${TF_DIR}..."
		cp -r ${TF_DIR} ${TF_BUILD_DIR}
	fi
else
	echo "ERROR: ${TF_DIR} are missing!"
	exit 1
fi

# Link terraform modules to build, i.e. module source is relative to ./terraform-modules
if [ -d ${TF_MODULES_DIR} ]
then
	ln -sf ${TF_MODULES_DIR} ${TF_BUILD_DIR}/
fi
		
pwd=${PWD}
cd ${TF_BUILD_DIR}

# Generate terraform file from templates
for file in $(ls *.tmpl* 2> /dev/null)
do
	base=${file%%.*}
	cat $file | render.sh > ${base}.tf
	rm -f $file
done

# Do terraform init
${TF_CMD} init -get;

cd $pwd