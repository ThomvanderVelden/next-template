// Container Apps Environment and Container App
// Naming: cae-{project}-{environment}-{region}, ca-{project}-{environment}-{region}

param environmentName string
param containerAppName string
param location string

@allowed(['dev', 'test', 'staging', 'prod'])
param environment string = 'dev'

param logAnalyticsCustomerId string
@secure()
param logAnalyticsSharedKey string

param appInsightsConnectionString string
param acrLoginServer string
param identityId string
param containerImage string

@secure()
param databaseUrl string

@secure()
param betterAuthSecret string

param betterAuthUrl string

// Scaling configuration per environment
var isProd = environment == 'prod'
var minReplicas = isProd ? 1 : 0
var maxReplicas = isProd ? 10 : 3

// Container Apps Environment
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: logAnalyticsSharedKey
      }
    }
    zoneRedundant: isProd
  }
}

// Container App
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  properties: {
    environmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 3000
        transport: 'auto'
        allowInsecure: false
      }
      registries: !empty(acrLoginServer) ? [
        {
          server: acrLoginServer
          identity: identityId
        }
      ] : []
      secrets: [
        {
          name: 'database-url'
          value: databaseUrl
        }
        {
          name: 'better-auth-secret'
          value: betterAuthSecret
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'nextjs'
          image: !empty(containerImage) ? containerImage : 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'DATABASE_URL'
              secretRef: 'database-url'
            }
            {
              name: 'BETTER_AUTH_SECRET'
              secretRef: 'better-auth-secret'
            }
            {
              name: 'BETTER_AUTH_URL'
              value: betterAuthUrl
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsightsConnectionString
            }
            {
              name: 'NODE_ENV'
              value: 'production'
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'http-scale'
            http: {
              metadata: {
                concurrentRequests: '100'
              }
            }
          }
        ]
      }
    }
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
output url string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output name string = containerApp.name
