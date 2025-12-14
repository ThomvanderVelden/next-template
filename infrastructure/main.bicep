// OpenNext Azure - Main Infrastructure Template
// This creates all resources needed to run a Next.js app on Azure
//
// Naming Convention: {resourcetype}-{project}-{environment}-{region}
// See: https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging

@description('Project/Application name (e.g. webapp, api, data-processor)')
param appName string

@description('Environment (dev, test, staging, prod)')
@allowed(['dev', 'test', 'staging', 'prod'])
param environment string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Node.js version for Functions')
@allowed(['20', '22'])
param nodeVersion string = '20'

@description('Enable Application Insights for monitoring and logging')
param enableApplicationInsights bool = false

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
  northcentralus: 'ncus'
  southcentralus: 'scus'
  canadacentral: 'cac'
  canadaeast: 'cae'
  brazilsouth: 'brs'
  australiaeast: 'aue'
  australiasoutheast: 'ause'
  japaneast: 'jpe'
  japanwest: 'jpw'
  koreacentral: 'krc'
  koreasouth: 'krs'
  southeastasia: 'sea'
  eastasia: 'ea'
  centralindia: 'inc'
  southindia: 'ins'
  westindia: 'inw'
}
var regionCode = contains(regionCodes, location) ? regionCodes[location] : substring(replace(location, ' ', ''), 0, 3)

// Naming variables following convention: {resourcetype}-{project}-{environment}-{region}
var sanitizedAppName = replace(toLower(appName), '-', '')
var storageAccountName = take('st${sanitizedAppName}${environment}${regionCode}', 24)
var functionAppName = 'func-${appName}-${environment}-${regionCode}'
var appServicePlanName = 'asp-${appName}-${environment}-${regionCode}'
var applicationInsightsName = 'appi-${appName}-${environment}-${regionCode}'

// Storage container/table/queue names (internal, no naming convention needed)
var containerName = 'nextjs-cache'
var tableName = 'nextjstags'
var queueName = 'nextjsrevalidation'

// Application Insights (optional)
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = if (enableApplicationInsights) {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    RetentionInDays: environment == 'prod' ? 90 : 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Storage Account (for cache, static assets, and function storage)
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: environment == 'prod' ? 'Standard_GRS' : 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: true
    accessTier: 'Hot'
  }

  // Blob service for cache and static assets
  resource blobService 'blobServices' = {
    name: 'default'
    properties: {
      cors: {
        corsRules: [
          {
            allowedOrigins: ['*']
            allowedMethods: ['GET', 'HEAD']
            maxAgeInSeconds: 3600
            exposedHeaders: ['*']
            allowedHeaders: ['*']
          }
        ]
      }
    }

    // Container for Next.js cache
    resource cacheContainer 'containers' = {
      name: containerName
      properties: {
        publicAccess: 'None'
      }
    }

    // Container for static assets (public CDN access)
    resource assetsContainer 'containers' = {
      name: 'assets'
      properties: {
        publicAccess: 'Blob'
      }
    }

    // Container for optimized images (public CDN access)
    resource optimizedImagesContainer 'containers' = {
      name: 'optimized-images'
      properties: {
        publicAccess: 'Blob'
      }
    }
  }

  // Table service for tag cache
  resource tableService 'tableServices' = {
    name: 'default'

    resource tagTable 'tables' = {
      name: tableName
    }
  }

  // Queue service for ISR revalidation (revalidateTag/revalidatePath)
  resource queueService 'queueServices' = {
    name: 'default'

    resource revalidationQueue 'queues' = {
      name: queueName
    }
  }
}

// App Service Plan (Consumption or Premium based on environment)
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: environment == 'prod' ? 'EP1' : 'Y1' // EP1 = Premium, Y1 = Consumption
    tier: environment == 'prod' ? 'ElasticPremium' : 'Dynamic'
  }
  kind: 'functionapp'
  properties: {
    reserved: true // Linux
  }
}

// Function App
resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'NODE|${nodeVersion}'
      appSettings: concat([
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~${nodeVersion}'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'AzureWebJobsDisableHomepage'
          value: 'true'
        }
        // Next.js / OpenNext environment variables
        {
          name: 'AZURE_STORAGE_CONNECTION_STRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'AZURE_STORAGE_ACCOUNT_NAME'
          value: storageAccountName
        }
        {
          name: 'AZURE_STORAGE_CONTAINER_NAME'
          value: containerName
        }
        {
          name: 'AZURE_TABLE_NAME'
          value: tableName
        }
        {
          name: 'AZURE_QUEUE_NAME'
          value: queueName
        }
        {
          name: 'AZURE_IMAGE_OPTIMIZATION_CACHE'
          value: 'true'
        }
        {
          name: 'NODE_ENV'
          value: 'production'
        }
      ], enableApplicationInsights ? [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
      ] : [])

      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      cors: {
        allowedOrigins: ['*']
      }
    }
    httpsOnly: true
  }
}

// Outputs
output functionAppName string = functionApp.name
output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}'
output storageAccountName string = storageAccount.name
output assetsUrl string = 'https://${storageAccount.name}.blob.${az.environment().suffixes.storage}/assets'
output resourceGroupName string = resourceGroup().name
output applicationInsightsName string = enableApplicationInsights ? applicationInsights.name : ''
output applicationInsightsInstrumentationKey string = enableApplicationInsights ? applicationInsights.properties.InstrumentationKey : ''

output deploymentInfo object = {
  functionApp: functionAppName
  storageAccount: storageAccountName
  containerName: containerName
  tableName: tableName
  queueName: queueName
  assetsUrl: 'https://${storageAccount.name}.blob.${az.environment().suffixes.storage}/assets'
  functionUrl: 'https://${functionApp.properties.defaultHostName}'
  appUrl: 'https://${functionApp.properties.defaultHostName}'
  applicationInsights: enableApplicationInsights ? applicationInsightsName : null
}
