RESOURCE_GROUP="REPLACE_ME"
ACR_NAME="REPLACE_ME"
AZDO_ORG_URL="https://dev.azure.com/REPLACE_ME"
AZDO_PROJECT_NAME="REPLACE_ME"
AZP_POOL="bedrock-pool" # Must exist in $AZDO_ORG_URL/_settings/agentpools
SUBSCRIPTION_ID="REPLACE_ME"
TENANT_ID="REPLACE_ME"
SP_CLIENT_ID="REPLACE_ME"

# Should come from Azure KeyVault ideally
AZDO_PAT="REPLACE_ME"
SP_CLIENT_PASS="REPLACE_ME"

# Delete and create variable group
vg_name="agent-build-vg"
vg_result=$(az pipelines variable-group list --org $AZDO_ORG_URL -p $AZDO_PROJECT_NAME)
vg_exists=$(echo $vg_result | jq -r --arg vg_name "$vg_name" '.[].name | select(. == $vg_name ) != null')
vg_id=$(echo "$vg_result"  | jq -r --arg vg_name "$vg_name" '.[] | select(.name == $vg_name) | .id')

echo "variable group to delete is $vg_id"
az pipelines variable-group delete --id "$vg_id" --yes --org $AZDO_ORG_URL -p $AZDO_PROJECT_NAME

CREATE_RESULT=$(az pipelines variable-group create --name "agent-build-vg" \
    --org $AZDO_ORG_URL \
    -p $AZDO_PROJECT_NAME \
    --variables \
        RESOURCE_GROUP=$RESOURCE_GROUP \
        ACR_NAME=$ACR_NAME \
        AZDO_ORG_URL=$AZDO_ORG_URL \
        AZP_POOL=$AZP_POOL)  

GROUP_ID=$(echo $CREATE_RESULT | jq ".id")
echo "The group id is $GROUP_ID"

az pipelines variable-group variable create \
    --org $AZDO_ORG_URL \
    -p $AZDO_PROJECT_NAME \
    --group-id "$GROUP_ID" \
    --secret true \
    --name "AZDO_PAT" \
    --value $AZDO_PAT

az pipelines variable-group variable create \
    --org $AZDO_ORG_URL \
    -p $AZDO_PROJECT_NAME \
    --group-id "$GROUP_ID" \
    --secret true \
    --name "SUBSCRIPTION_ID" \
    --value $SUBSCRIPTION_ID

az pipelines variable-group variable create \
    --org $AZDO_ORG_URL \
    -p $AZDO_PROJECT_NAME \
    --group-id "$GROUP_ID" \
    --secret true \
    --name "TENANT_ID" \
    --value $TENANT_ID 

    az pipelines variable-group variable create \
        --org $AZDO_ORG_URL \
        -p $AZDO_PROJECT_NAME \
        --group-id "$GROUP_ID" \
        --secret true \
        --name "SP_CLIENT_ID" \
        --value $SP_CLIENT_ID 

az pipelines variable-group variable create \
    --org $AZDO_ORG_URL \
    -p $AZDO_PROJECT_NAME \
    --group-id "$GROUP_ID" \
    --secret true \
    --name "SP_CLIENT_PASS" \
    --value $SP_CLIENT_PASS  