#!/bin/bash

export ARM_CLIENT_ID=${2}
export ARM_CLIENT_SECRET=${3}
export ARM_SUBSCRIPTION_ID=${4}
export ARM_TENANT_ID=${5}


echo logon
set -eux # fail on error
az login --service-principal -u ${2} -p ${3} --tenant ${5}


echo "Change directory path ${10} configuration Directory"
cd ${10}/_terraform-azure-hub-spoke/drop

echo terraform init
terraform init \
 -upgrade \
 -backend-config="resource_group_name=${6}" \
 -backend-config="storage_account_name=${7}" \
 -backend-config="container_name=${8}" \
 -backend-config="key=${9}" 

echo select workspace
terraform workspace select ${1} || terraform workspace new ${1}

echo terraform plan excution
terraform plan -var-file="./environment/${1}/${1}.tfvars" -out="${1}.tfplan"

echo applying terraform changes
terraform apply ${1}.tfplan
