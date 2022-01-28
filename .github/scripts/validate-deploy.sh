#!/usr/bin/env bash

GIT_REPO=$(cat git_repo)
GIT_TOKEN=$(cat git_token)
BIN_DIR=$(cat .bin_dir)

export KUBECONFIG=$(cat .kubeconfig)
NAMESPACE="openshift-operators"
BRANCH="main"
SERVER_NAME="default"
TYPE="operators"

COMPONENT_NAME="ibm-ace-operator"

mkdir -p .testrepo

git clone https://${GIT_TOKEN}@${GIT_REPO} .testrepo

cd .testrepo || exit 1

find . -name "*"

if [[ ! -f "argocd/2-services/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml" ]]; then
  echo "ArgoCD config missing - argocd/2-services/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"
  exit 1
fi

echo "Printing argocd/2-services/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"
cat "argocd/2-services/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"

if [[ ! -f "payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml" ]]; then
  echo "Application values not found - payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"
  exit 1
fi

echo "Printing payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"
cat "payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"

cd ..
rm -rf .testrepo

SUBSCRIPTION="subscription/ibm-ace"
count=0
until kubectl get "${SUBSCRIPTION}" -n "${NAMESPACE}" || [[ $count -eq 20 ]]; do
  echo "Waiting for ${SUBSCRIPTION} in ${NAMESPACE}"
  count=$((count + 1))
  sleep 15
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for ${SUBSCRIPTION} in ${NAMESPACE}"
  kubectl get subscription -n "${NAMESPACE}"
  exit 1
fi

CSV_NAME="ibm-appconnect"

count=0
until kubectl get csv -n "${NAMESPACE}" -o json | "${BIN_DIR}/jq" -r '.items[] | .metadata.name' | grep -q "${CSV_NAME}" || [[ $count -eq 20 ]]; do
  echo "Waiting for ${CSV_NAME} csv in ${NAMESPACE}"
  count=$((count + 1))
  sleep 15
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for ${CSV_NAME} csv in ${NAMESPACE}"
  kubectl get csv -n "${NAMESPACE}"
  exit 1
fi

CSV=$(kubectl get csv -n "${NAMESPACE}" -o json | "${BIN_DIR}/jq" -r '.items[] | .metadata.name' | grep "${CSV_NAME}")
echo "Found csv ${CSV} in ${NAMESPACE}"
