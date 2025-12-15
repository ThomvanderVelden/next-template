// Azure Database for PostgreSQL Flexible Server
// Naming: psql-{project}-{environment}-{region}

param serverName string
param location string

@allowed(['dev', 'test', 'staging', 'prod'])
param environment string = 'dev'

@description('Database administrator login name')
param administratorLogin string = 'pgadmin'

@description('Database administrator password')
@secure()
param administratorPassword string

@description('Database name')
param databaseName string = 'app'

// SKU configuration per environment
var skuConfig = {
  dev: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
    storageSizeGB: 32
  }
  test: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
    storageSizeGB: 32
  }
  staging: {
    name: 'Standard_B2s'
    tier: 'Burstable'
    storageSizeGB: 64
  }
  prod: {
    name: 'Standard_D2s_v3'
    tier: 'GeneralPurpose'
    storageSizeGB: 128
  }
}

var sku = skuConfig[environment]

// PostgreSQL Flexible Server
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-12-01-preview' = {
  name: serverName
  location: location
  sku: {
    name: sku.name
    tier: sku.tier
  }
  properties: {
    version: '16'
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    storage: {
      storageSizeGB: sku.storageSizeGB
    }
    backup: {
      backupRetentionDays: environment == 'prod' ? 35 : 7
      geoRedundantBackup: environment == 'prod' ? 'Enabled' : 'Disabled'
    }
    highAvailability: {
      mode: environment == 'prod' ? 'ZoneRedundant' : 'Disabled'
    }
    authConfig: {
      activeDirectoryAuth: 'Disabled'
      passwordAuth: 'Enabled'
    }
  }
}

// Database
resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-12-01-preview' = {
  parent: postgresServer
  name: databaseName
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

// Firewall rule to allow Azure services
resource allowAzureServices 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-12-01-preview' = {
  parent: postgresServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Connection string output
var connectionString = 'postgresql://${administratorLogin}:${administratorPassword}@${postgresServer.properties.fullyQualifiedDomainName}:5432/${databaseName}?sslmode=require'

output serverName string = postgresServer.name
output serverFqdn string = postgresServer.properties.fullyQualifiedDomainName
output databaseName string = database.name
output connectionString string = connectionString
