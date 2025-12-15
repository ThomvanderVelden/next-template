#!/bin/bash
# Setup GitHub Actions OIDC authentication with Azure
# Run this once before using the CI/CD workflows
#
# Prerequisites:
# - Azure CLI installed and logged in (az login)
# - GitHub CLI installed (optional, for automatic secret creation)

set -e

# Configuration - UPDATE THESE VALUES
APP_NAME="nextjs-template"
GITHUB_ORG="thomvandervelden"    # Replace with your GitHub org/username
GITHUB_REPO="next-template"     # Replace with your repo name

echo "================================================"
echo "GitHub Actions OIDC Setup for Azure"
echo "================================================"
echo ""
echo "App Name: $APP_NAME"
echo "GitHub: $GITHUB_ORG/$GITHUB_REPO"
echo ""

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo "Error: Not logged in to Azure. Run 'az login' first."
    exit 1
fi

# Get subscription and tenant IDs
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Tenant ID: $TENANT_ID"
echo ""

# Create Microsoft Entra Application
echo "Creating Microsoft Entra Application..."
APP_ID=$(az ad app create \
    --display-name "github-${APP_NAME}-deployment" \
    --query appId -o tsv)
echo "App (Client) ID: $APP_ID"

# Create Service Principal
echo "Creating Service Principal..."
SP_ID=$(az ad sp create --id $APP_ID --query id -o tsv)
echo "Service Principal ID: $SP_ID"

# Wait for propagation
echo "Waiting for Azure AD propagation..."
sleep 10

# Assign Contributor role at subscription level
echo "Assigning Contributor role..."
az role assignment create \
    --assignee $APP_ID \
    --role "Contributor" \
    --scope "/subscriptions/$SUBSCRIPTION_ID" \
    --output none

# Configure federated credentials
echo ""
echo "Configuring federated credentials..."

# Main branch
echo "  - main branch..."
az ad app federated-credential create \
    --id $APP_ID \
    --parameters "{
        \"name\": \"github-main-branch\",
        \"issuer\": \"https://token.actions.githubusercontent.com\",
        \"subject\": \"repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/main\",
        \"description\": \"GitHub Actions - main branch\",
        \"audiences\": [\"api://AzureADTokenExchange\"]
    }" \
    --output none

# Pull requests
echo "  - pull requests..."
az ad app federated-credential create \
    --id $APP_ID \
    --parameters "{
        \"name\": \"github-pull-requests\",
        \"issuer\": \"https://token.actions.githubusercontent.com\",
        \"subject\": \"repo:${GITHUB_ORG}/${GITHUB_REPO}:pull_request\",
        \"description\": \"GitHub Actions - Pull Requests\",
        \"audiences\": [\"api://AzureADTokenExchange\"]
    }" \
    --output none

# Environments
for ENV in dev staging prod; do
    echo "  - $ENV environment..."
    az ad app federated-credential create \
        --id $APP_ID \
        --parameters "{
            \"name\": \"github-env-${ENV}\",
            \"issuer\": \"https://token.actions.githubusercontent.com\",
            \"subject\": \"repo:${GITHUB_ORG}/${GITHUB_REPO}:environment:${ENV}\",
            \"description\": \"GitHub Actions - ${ENV} environment\",
            \"audiences\": [\"api://AzureADTokenExchange\"]
        }" \
        --output none
done

echo ""
echo "================================================"
echo "Setup Complete!"
echo "================================================"
echo ""
echo "Add these secrets to your GitHub repository:"
echo ""
echo "  AZURE_CLIENT_ID:       $APP_ID"
echo "  AZURE_TENANT_ID:       $TENANT_ID"
echo "  AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo ""
echo "Also add these secrets per environment (dev, staging, prod):"
echo "  DATABASE_URL:          Your PostgreSQL connection string"
echo "  BETTER_AUTH_SECRET:    Your Better Auth secret (generate with: openssl rand -base64 32)"
echo "  BETTER_AUTH_URL:       https://ca-${APP_NAME}-{env}-weu.westeurope.azurecontainerapps.io"
echo ""
echo "Next steps:"
echo "  1. Create GitHub environments: dev, staging, prod"
echo "  2. Add the secrets above to each environment"
echo "  3. Run the 'Deploy Infrastructure' workflow"
echo "  4. Run the 'Build and Deploy' workflow"
echo ""
