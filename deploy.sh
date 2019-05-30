#!/bin/sh

set -ex

AWS_ACCOUNTID="$(aws sts get-caller-identity --query Account --output text)"
BACKEND_BUCKET="terraform-backend-$AWS_ACCOUNTID"
REPONAME=$(aws ecr describe-repositories --repository-names sample --query "repositories[].repositoryUri" --output text)

# build image
$(aws ecr get-login --no-include-email)
docker build . -t ${REPONAME}:latest
docker push ${REPONAME}:latest

# terraform apply
cd terraform
terraform init -backend-config="bucket=$BACKEND_BUCKET"
terraform apply -auto-approve
