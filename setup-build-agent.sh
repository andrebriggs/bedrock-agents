#!/bin/bash

#Fail on first error
set -e

[ ! -z "$RESOURCE_GROUP" ] || { echo "Provide RESOURCE_GROUP"; exit 1;}
[ ! -z "$ACR_NAME" ] || { echo "Provide ACR_NAME"; exit 1;}
[ ! -z "$AZDO_PAT" ] || { echo "Provide AZDO_PAT"; exit 1;}
[ ! -z "$AZDO_ORG_URL" ] || { echo "Provide AZDO_ORG_URL"; exit 1;}
[ ! -z "$AZP_POOL" ] || { echo "Provide AZP_POOL"; exit 1;}
[ ! -z "$SUBSCRIPTION_ID" ] || { echo "Provide SUBSCRIPTION_ID"; exit 1;}
[ ! -z "$TENANT_ID" ] || { echo "Provide AZDO_TENANT_IDPAT"; exit 1;}
[ ! -z "$SP_CLIENT_ID" ] || { echo "Provide SP_CLIENT_ID"; exit 1;}
[ ! -z "$SP_CLIENT_PASS" ] || { echo "Provide SP_CLIENT_PASS"; exit 1;}

EnvName="dev"
idx=1
AGENT_NAME="bedrock-build-agent-$EnvName-$idx"
ACR_IMAGE_PATH="$ACR_NAME.azurecr.io/bedrock-build-agent:dev"
RESTART_POLICY="Always"
ACR_PASS=$(az acr credential show -n $ACR_NAME | jq -r ".passwords[0].value")


# echo "Creating ACI"
# echo "\tName:\t$AGENT_NAME"
# echo "\tGroup\t$RESOURCE_GROUP"
# echo "\tACR:\t$ACR_NAME"
# echo "\tImage:\t$ACR_IMAGE_PATH"

az container create \
    --name $AGENT_NAME \
    --resource-group $RESOURCE_GROUP \
    --image $ACR_IMAGE_PATH \
    --cpu 1 \
    --memory 1 \
    --registry-login-server "$ACR_NAME.azurecr.io" \
    --registry-username $ACR_NAME \
    --registry-password $ACR_PASS \
    --dns-name-label $AGENT_NAME \
    --ip-address Private \
    --restart-policy $RESTART_POLICY \
    --environment-variables AZP_URL=$AZDO_ORG_URL AZP_POOL=$AZP_POOL AZP_AGENT_NAME=$AGENT_NAME ARM_SUBSCRIPTION_ID="$SUBSCRIPTION_ID" ARM_TENANT_ID="$TENANT_ID" ARM_CLIENT_ID="$SP_CLIENT_ID" \
    --secure-environment-variable AZP_TOKEN=$AZDO_PAT AZ_SERVICE_PRINCIPAL="$SP_CLIENT_ID" AZ_SERVICE_PRINCIPAL_KEY="$SP_CLIENT_PASS" ARM_CLIENT_SECRET="$SP_CLIENT_PASS" \
    --assign-identity

echo "Ensure contributor role for MSI in current subscription"
CONTAINER_PRINCIPAL_ID=$(az container show -g $RESOURCE_GROUP -n $AGENT_NAME | jq -r ".identity.principalId")
SUB_SCOPE_ID="/subscriptions/$SUBSCRIPTION_ID"
ASSIGNMENT_COUNT=$(az role assignment list --role Contributor --assignee $CONTAINER_PRINCIPAL_ID --scope $SUB_SCOPE_ID | jq length) 

if [ "$ASSIGNMENT_COUNT" -eq "0" ]; then
   echo "Creating role assignment for service principal on subscription scope";
   az role assignment create --role Contributor --assignee $CONTAINER_PRINCIPAL_ID --scope $SUB_SCOPE_ID
else
    echo "Role assignment already exists for service principal on subscription scope"
fi