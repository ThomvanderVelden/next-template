// Log Analytics Workspace and Application Insights
// Naming: log-{project}-{environment}-{region}, appi-{project}-{environment}-{region}

param logAnalyticsName string
param appInsightsName string
param location string

@allowed(['dev', 'test', 'staging', 'prod'])
param environment string = 'dev'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: environment == 'prod' ? 90 : 30
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    RetentionInDays: environment == 'prod' ? 90 : 30
  }
}

output logAnalyticsWorkspaceId string = logAnalytics.id
output logAnalyticsCustomerId string = logAnalytics.properties.customerId
output logAnalyticsSharedKey string = logAnalytics.listKeys().primarySharedKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
