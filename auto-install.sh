#!/bin/sh

set -e

#####################################
# Set your environment variables here
#####################################

OBSERVABILITY_ENABLED=true
PIPELINES_NAMESPACE=ocp-pipelines

#####################################
## Do not modify anything from this line
#####################################

# Print environment variables
echo -e "\n=============="
echo -e "ENVIRONMENT VARIABLES:"
echo -e " * OBSERVABILITY_ENABLED: $OBSERVABILITY_ENABLED"
echo -e "==============\n"

# Check if the user is logged in 
if ! oc whoami &> /dev/null; then
    echo -e "Check. You are not logged out. Please log in and run the script again."
    exit 1
else
    echo -e "Check. You are correctly logged in. Continue..."
    if ! oc project &> /dev/null; then
        echo -e "Current project does not exist, moving to project Default."
        oc project default 
    fi
fi

echo -e "\n=================="
echo -e "=     GITOPS     ="
echo -e "==================\n"

echo -e "Trigger the Pipelines application creation"
oc apply -f application-ocp-pipelines.yaml

echo -n "Waiting for namespace $PIPELINES_NAMESPACE to be created..."; while [[ $(oc get namespace $PIPELINES_NAMESPACE --ignore-not-found -o jsonpath='{.metadata.name}') != "$PIPELINES_NAMESPACE" ]]; do echo -n "."; sleep 1; done; echo "  [OK]"


echo -e "\n=================="
echo -e "=     SECRETS    ="
echo -e "==================\n"

echo -e "Create the Secrets for Git, Quay, and RH Registry"
oc apply -k secrets

echo -e "Linking the secrets to the pipeline SA"
echo -n "Waiting for SA pipeline to be created..."; while ! oc get sa pipeline -n $PIPELINES_NAMESPACE &>/dev/null ; do echo -n "."; sleep 1; done; echo "  [OK]"

oc secrets link -n $PIPELINES_NAMESPACE pipeline rh-registry-sa
oc secrets link -n $PIPELINES_NAMESPACE pipeline git-secret-ssh
oc secrets link -n $PIPELINES_NAMESPACE pipeline quay-alopezme-pull-secret


echo -e "\n=================="
echo -e "= CONSOLE PLUGIN ="
echo -e "==================\n"

echo -e "Enable the console plugin:"
if oc get console.operator.openshift.io cluster -o template='{{.spec.plugins}}' | grep pipelines-console-plugin &> /dev/null; then
    echo -e "\tChecked. The logging plugin was already enabled."
else
    echo -e "\tChecked. The logging plugin was not enabled. Enabling..."
    oc patch console.operator.openshift.io cluster --type json \
    --patch '[{"op": "add", "path": "/spec/plugins/-", "value": "pipelines-console-plugin"}]'
fi


echo -e "\n=================="
echo -e "=     GRAFANA    ="
echo -e "==================\n"

echo -e "Create Grafana dashboards if Observability is enabled"

if [ "$OBSERVABILITY_ENABLED" = true ]; then
    echo "Observability is enabled, creating Grafana dashboards."
    oc apply -k grafana

else
    echo "Observability is not enabled, skipping Grafana dashboard creation."
fi
