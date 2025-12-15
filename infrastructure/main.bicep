// Azure Container Apps Infrastructure
// Naming Convention: {resourcetype}-{project}-{environment}-{region}

@description('Project/Application name (e.g., webapp, api)')
param appName string

@description('Environment (dev, test, staging, prod)')
@allowed(['dev', 'test', 'staging', 'prod'])
param environment string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Container image to deploy (full ACR path)')
param containerImage string = ''

@description('PostgreSQL administrator password')
@secure()
param postgresPassword string

@description('Better Auth secret')
@secure()
param betterAuthSecret string = ''

@description('Better Auth URL')
param betterAuthUrl string = ''

// Region code mapping for naming convention
var regionCodes = {
  westeurope: 'weu'
  northeurope: 'neu'
  swedencentral: 'swe'
  francecentral: 'fra'
  germanywestcentral: 'gwc'
  uksouth: 'uks'
  ukwest: 'ukw'
  eastus: 'eus'
  eastus2: 'eus2'
  westus: 'wus'
  westus2: 'wus2'
  westus3: 'wus3'
  centralus: 'cus'
  canadacentral: 'cac'
  brazilsouth: 'brs'
  australiaeast: 'aue'
  japaneast: 'jpe'
  southeastasia: 'sea'
  eastasia: 'ea'
}
var regionCode = regionCodes[?location] ?? substring(replace(location, ' ', ''), 0, 3)

// Resource names following naming convention
var sanitizedAppName = replace(toLower(appName), '-', '')
var acrName = take('acr${sanitizedAppName}${environment}${regionCode}', 50)
var identityName = 'id-${appName}-${environment}-${regionCode}'
var logAnalyticsName = 'log-${appName}-${environment}-${regionCode}'
var appInsightsName = 'appi-${appName}-${environment}-${regionCode}'
var environmentName = 'cae-${appName}-${environment}-${regionCode}'
var containerAppName = 'ca-${appName}-${environment}-${regionCode}'
var postgresServerName = 'psql-${appName}-${environment}-${regionCode}'

// Managed Identity
module identity 'modules/identity.bicep' = {
  name: 'identity-deployment'
  params: {
    identityName: identityName
    location: location
  }
}

// Azure Container Registry
module acr 'modules/acr.bicep' = {
  name: 'acr-deployment'
  params: {
    acrName: acrName
    location: location
    identityPrincipalId: identity.outputs.principalId
    sku: environment == 'prod' ? 'Standard' : 'Basic'
  }
}

// Monitoring (Log Analytics + App Insights)
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring-deployment'
  params: {
    logAnalyticsName: logAnalyticsName
    appInsightsName: appInsightsName
    location: location
    environment: environment
  }
}

// PostgreSQL Flexible Server
module postgresql 'modules/postgresql.bicep' = {
  name: 'postgresql-deployment'
  params: {
    serverName: postgresServerName
    location: location
    environment: environment
    administratorPassword: postgresPassword
  }
}

// Container App
module containerApp 'modules/container-app.bicep' = {
  name: 'container-app-deployment'
  params: {
    environmentName: environmentName
    containerAppName: containerAppName
    location: location
    environment: environment
    logAnalyticsCustomerId: monitoring.outputs.logAnalyticsCustomerId
    logAnalyticsSharedKey: monitoring.outputs.logAnalyticsSharedKey
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    acrLoginServer: acr.outputs.loginServer
    identityId: identity.outputs.identityId
    containerImage: containerImage
    databaseUrl: postgresql.outputs.connectionString
    betterAuthSecret: betterAuthSecret
    betterAuthUrl: !empty(betterAuthUrl) ? betterAuthUrl : 'https://${containerAppName}.${location}.azurecontainerapps.io'
  }
}

// Outputs
output acrLoginServer string = acr.outputs.loginServer
output acrName string = acr.outputs.name
output containerAppUrl string = containerApp.outputs.url
output containerAppName string = containerApp.outputs.name
output identityClientId string = identity.outputs.clientId
output resourceGroupName string = resourceGroup().name
output postgresServerFqdn string = postgresql.outputs.serverFqdn

output deploymentInfo object = {
  acr: acr.outputs.loginServer
  containerApp: containerApp.outputs.name
  url: containerApp.outputs.url
  postgresServer: postgresql.outputs.serverFqdn
  environment: environment
  region: regionCode
}
