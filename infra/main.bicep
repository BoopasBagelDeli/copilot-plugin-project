targetScope = 'resourceGroup'

metadata name = 'Microsoft Ecosystem Plugin Infrastructure'
metadata description = 'Azure infrastructure for Microsoft ecosystem plugin modules including Function Apps, Key Vault, and Application Insights'

@minLength(1)
@maxLength(64)
@description('Name of the environment (dev, test, prod)')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Optional. Application Insights location')
param appInsightsLocation string = location

@description('Optional. Log Analytics workspace location')
param logAnalyticsLocation string = location

@description('Optional. Storage account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param storageAccountType string = 'Standard_LRS'

@description('Function App runtime stack')
@allowed([
  'python'
  'node'
  'dotnet'
  'java'
])
param functionAppRuntime string = 'python'

@description('Tags for all resources')
param tags object = {}

// Variables for resource naming
var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, resourceGroup().id, location, environmentName))

// Resource names
var keyVaultName = '${abbrs.keyVaultVaults}${take(replace(environmentName, '-', ''), 8)}${take(resourceToken, 8)}'
var logAnalyticsName = '${abbrs.operationalInsightsWorkspaces}${take(environmentName, 15)}-${take(resourceToken, 10)}'
var applicationInsightsName = '${abbrs.insightsComponents}${take(environmentName, 10)}-${take(resourceToken, 12)}'
var appServicePlanName = '${abbrs.webServerFarms}${take(environmentName, 10)}-${take(resourceToken, 12)}'
var storageAccountName = '${abbrs.storageStorageAccounts}${take(replace(environmentName, '-', ''), 8)}${take(resourceToken, 14)}'
var managedIdentityName = '${abbrs.managedIdentityUserAssignedIdentities}${environmentName}-${resourceToken}'

// Function App names for each plugin
var functionAppNames = {
  entraId: '${abbrs.webSitesFunctions}entraid-${environmentName}-${resourceToken}'
  azureMonitor: '${abbrs.webSitesFunctions}azuremon-${environmentName}-${resourceToken}'
  azureDevOps: '${abbrs.webSitesFunctions}azuredevops-${environmentName}-${resourceToken}'
  github: '${abbrs.webSitesFunctions}github-${environmentName}-${resourceToken}'
  githubActions: '${abbrs.webSitesFunctions}ghactions-${environmentName}-${resourceToken}'
  azureRepos: '${abbrs.webSitesFunctions}azurerepos-${environmentName}-${resourceToken}'
}

// Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: union(tags, { 'azd-env-name': environmentName })
}

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  tags: union(tags, { 'azd-env-name': environmentName })
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: logAnalyticsLocation
  tags: union(tags, { 'azd-env-name': environmentName })
  properties: {
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  }
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: appInsightsLocation
  tags: union(tags, { 'azd-env-name': environmentName })
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: union(tags, { 'azd-env-name': environmentName })
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForTemplateDeployment: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Key Vault RBAC - Grant Managed Identity access to secrets
resource keyVaultSecretsUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, managedIdentity.id, 'Key Vault Secrets User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Storage Account RBAC roles for Function Apps
resource storageBlobDataOwnerRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, managedIdentity.id, 'Storage Blob Data Owner')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b') // Storage Blob Data Owner
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource storageBlobDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, managedIdentity.id, 'Storage Blob Data Contributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource storageQueueDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, managedIdentity.id, 'Storage Queue Data Contributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '974c5e8b-45b9-4653-ba55-5f855dd0fb88') // Storage Queue Data Contributor
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource storageTableDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, managedIdentity.id, 'Storage Table Data Contributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3') // Storage Table Data Contributor
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource monitoringMetricsPublisherRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, managedIdentity.id, 'Monitoring Metrics Publisher')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '3913510d-42f4-4e42-8a64-420c390055eb') // Monitoring Metrics Publisher
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// App Service Plan (Consumption)
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  tags: union(tags, { 'azd-env-name': environmentName })
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
  properties: {
    reserved: false
  }
  kind: 'functionapp'
}

// Common app settings for Function Apps
var commonAppSettings = [
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: functionAppRuntime
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: applicationInsights.properties.InstrumentationKey
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: applicationInsights.properties.ConnectionString
  }
  {
    name: 'KEY_VAULT_URL'
    value: keyVault.properties.vaultUri
  }
  {
    name: 'AZURE_CLIENT_ID'
    value: managedIdentity.properties.clientId
  }
]

// EntraID Function App
resource entraIdFunctionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppNames.entraId
  location: location
  tags: union(tags, { 'azd-env-name': environmentName, 'azd-service-name': 'entraidconnector' })
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: concat([
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppNames.entraId)
        }
      ], commonAppSettings)
      cors: {
        allowedOrigins: ['*']
        supportCredentials: false
      }
      pythonVersion: functionAppRuntime == 'python' ? '3.11' : null
    }
  }
}

// Azure Monitor Function App  
resource azureMonitorFunctionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppNames.azureMonitor
  location: location
  tags: union(tags, { 'azd-env-name': environmentName, 'azd-service-name': 'azuremonitorconnector' })
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: concat([
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppNames.azureMonitor)
        }
      ], commonAppSettings)
      cors: {
        allowedOrigins: ['*']
        supportCredentials: false
      }
      pythonVersion: functionAppRuntime == 'python' ? '3.11' : null
    }
  }
}

// Azure DevOps Function App
resource azureDevOpsFunctionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppNames.azureDevOps
  location: location
  tags: union(tags, { 'azd-env-name': environmentName, 'azd-service-name': 'azuredevopsconnector' })
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: concat([
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppNames.azureDevOps)
        }
      ], commonAppSettings)
      cors: {
        allowedOrigins: ['*']
        supportCredentials: false
      }
      pythonVersion: functionAppRuntime == 'python' ? '3.11' : null
    }
  }
}

// GitHub Function App
resource githubFunctionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppNames.github
  location: location
  tags: union(tags, { 'azd-env-name': environmentName, 'azd-service-name': 'githubconnector' })
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: concat([
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppNames.github)
        }
      ], commonAppSettings)
      cors: {
        allowedOrigins: ['*']
        supportCredentials: false
      }
      pythonVersion: functionAppRuntime == 'python' ? '3.11' : null
    }
  }
}

// GitHub Actions Function App
resource githubActionsFunctionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppNames.githubActions
  location: location
  tags: union(tags, { 'azd-env-name': environmentName, 'azd-service-name': 'githubactionsconnector' })
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: concat([
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppNames.githubActions)
        }
      ], commonAppSettings)
      cors: {
        allowedOrigins: ['*']
        supportCredentials: false
      }
      pythonVersion: functionAppRuntime == 'python' ? '3.11' : null
    }
  }
}

// Azure Repos Function App
resource azureReposFunctionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppNames.azureRepos
  location: location
  tags: union(tags, { 'azd-env-name': environmentName, 'azd-service-name': 'azurereposconnector' })
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: concat([
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppNames.azureRepos)
        }
      ], commonAppSettings)
      cors: {
        allowedOrigins: ['*']
        supportCredentials: false
      }
      pythonVersion: functionAppRuntime == 'python' ? '3.11' : null
    }
  }
}

// Diagnostic Settings for Function Apps
resource entraIdFunctionAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'logs'
  scope: entraIdFunctionApp
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource azureMonitorFunctionAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'logs'
  scope: azureMonitorFunctionApp
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource azureDevOpsFunctionAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'logs'
  scope: azureDevOpsFunctionApp
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource githubFunctionAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'logs'
  scope: githubFunctionApp
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource githubActionsFunctionAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'logs'
  scope: githubActionsFunctionApp
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource azureReposFunctionAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'logs'
  scope: azureReposFunctionApp
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = subscription().tenantId
output AZURE_RESOURCE_GROUP string = resourceGroup().name
output RESOURCE_GROUP_ID string = resourceGroup().id

output AZURE_KEY_VAULT_NAME string = keyVault.name
output AZURE_KEY_VAULT_URL string = keyVault.properties.vaultUri

output AZURE_APPLICATION_INSIGHTS_NAME string = applicationInsights.name
output AZURE_APPLICATION_INSIGHTS_CONNECTION_STRING string = applicationInsights.properties.ConnectionString
output AZURE_APPLICATION_INSIGHTS_INSTRUMENTATION_KEY string = applicationInsights.properties.InstrumentationKey

output AZURE_STORAGE_ACCOUNT_NAME string = storageAccount.name

output AZURE_MANAGED_IDENTITY_CLIENT_ID string = managedIdentity.properties.clientId
output AZURE_MANAGED_IDENTITY_NAME string = managedIdentity.name

// Function App URLs
output ENTRAID_FUNCTION_APP_NAME string = entraIdFunctionApp.name
output ENTRAID_FUNCTION_APP_URL string = 'https://${entraIdFunctionApp.properties.defaultHostName}'

output AZUREMONITOR_FUNCTION_APP_NAME string = azureMonitorFunctionApp.name
output AZUREMONITOR_FUNCTION_APP_URL string = 'https://${azureMonitorFunctionApp.properties.defaultHostName}'

output AZUREDEVOPS_FUNCTION_APP_NAME string = azureDevOpsFunctionApp.name
output AZUREDEVOPS_FUNCTION_APP_URL string = 'https://${azureDevOpsFunctionApp.properties.defaultHostName}'

output GITHUB_FUNCTION_APP_NAME string = githubFunctionApp.name
output GITHUB_FUNCTION_APP_URL string = 'https://${githubFunctionApp.properties.defaultHostName}'

output GITHUBACTIONS_FUNCTION_APP_NAME string = githubActionsFunctionApp.name
output GITHUBACTIONS_FUNCTION_APP_URL string = 'https://${githubActionsFunctionApp.properties.defaultHostName}'

output AZUREREPOS_FUNCTION_APP_NAME string = azureReposFunctionApp.name
output AZUREREPOS_FUNCTION_APP_URL string = 'https://${azureReposFunctionApp.properties.defaultHostName}'
