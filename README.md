# Bedrock Build Agent

## What's inside

- A Dockerfile that steps up a build agent environment with:
  - Helm
  - Fabrikate
  - Bedrock CLI (SPK)
  - Bedrock `build.sh` file globally symlinked
  - Az CLI (With Azure DevOps extension)
  - Terraform
  - Scripts to connect to an Azure DevOps organization and register as a custom build agent
- A script to build the Dockerfile and push to ACR
- A script to deploy custom build agent image to Azure Container Instance with secure environment variables
- An Azure Pipelines yaml file that will validate that existence of aforementioned applications in the custom build agent

## What this unlocks

- The ability to pin specific versions of tooling in the Bedrock CI/CD infrastructure.
- The ability to run Bedrock workflows in a restricted environment
- The ability to simplify Bedrock CI/CD pipelines
- The ability to canary test new versions of Bedrock tooling
- The ability to streamline secrets management

## Steps 
1. Login to your ACR `az acr login --name <ACR NAME>`
2. Run `az acr build -r <ACR NAME> --image bedrock-build-agent:dev .`