// Main Bicep template for Microsoft 365 Copilot Plugin infrastructure
// Deploys Azure Functions, Application Insights, Key Vault, and supporting resources

@description('The name of the environment (e.g., dev, staging, prod)')
param environmentName string = 'dev'

@description('The location for all resources')
param location string = resourceGroup().location

@description('The name prefix for all resources')
param resourcePrefix string = 'copilot-plugin'

@description('The SKU for the Function App hosting plan')
@allowed(['Y1', 'EP1', 'EP2', 'EP3'])
param functionAppSku string = 'Y1'

@description('The Python version for the Function App')
@allowed(['3.9', '3.10', '3.11'])
param pythonVersion string = '3.11'

@description('Enable Application Insights')
param enableApplicationInsights bool = true

@description('Enable Key Vault')
param enableKeyVault bool = true

@description('Tags to apply to all resources')
param tags object = {
  Environment: environmentName
  Project: 'Copilot-Plugin'
  'azd-env-name': environmentName
}

// Generate unique resource names using resource token (shortened for naming limits)
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var shortToken = substring(resourceToken, 0, 8)
var envPrefix = substring(replace(environmentName, '-', ''), 0, min(length(replace(environmentName, '-', '')), 8))
var storageAccountName = 'st${shortToken}${envPrefix}'
var functionAppName = '${resourcePrefix}-func-${resourceToken}'
var hostingPlanName = '${resourcePrefix}-plan-${resourceToken}'
var applicationInsightsName = '${resourcePrefix}-ai-${resourceToken}'
var keyVaultName = 'kv${shortToken}${envPrefix}'
var logAnalyticsName = '${resourcePrefix}-logs-${resourceToken}'

// Storage Account for Azure Functions
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Allow'
    }
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enableApplicationInsights) {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = if (enableApplicationInsights) {
  name: applicationInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    WorkspaceResourceId: enableApplicationInsights ? logAnalyticsWorkspace.id : null
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = if (enableKeyVault) {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
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

// User-assigned managed identity for Function App
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${resourcePrefix}-identity-${resourceToken}'
  location: location
  tags: tags
}

// Role assignment for managed identity to access Key Vault
resource keyVaultAccessPolicy 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableKeyVault) {
  scope: keyVault
  name: guid(keyVault.id, managedIdentity.id, 'Key Vault Secrets User')
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6'
    ) // Key Vault Secrets User
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Role assignment for managed identity to access Storage Account
resource storageAccessPolicy 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageAccount.id, managedIdentity.id, 'Storage Blob Data Owner')
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
    ) // Storage Blob Data Owner
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Hosting Plan for Azure Functions
resource hostingPlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: hostingPlanName
  location: location
  tags: tags
  sku: {
    name: functionAppSku
  }
  kind: 'functionapp'
  properties: {
    reserved: true // Linux hosting
  }
}

// Azure Function App
resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  tags: union(tags, {
    'azd-service-name': 'api'
  })
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: hostingPlan.id
    reserved: true
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'Python|${pythonVersion}'
      appSettings: [
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
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'ENVIRONMENT'
          value: environmentName
        }
        {
          name: 'APPLICATION_INSIGHTS_CONNECTION_STRING'
          value: enableApplicationInsights ? applicationInsights!.properties.ConnectionString : ''
        }
        {
          name: 'KEY_VAULT_URL'
          value: enableKeyVault ? keyVault!.properties.vaultUri : ''
        }
        {
          name: 'AZURE_CLIENT_ID'
          value: managedIdentity.properties.clientId
        }
        {
          name: 'RATE_LIMIT_PER_MINUTE'
          value: '100'
        }
        {
          name: 'BURST_LIMIT'
          value: '20'
        }
      ]
      cors: {
        allowedOrigins: [
          'https://copilot.microsoft.com'
          'https://teams.microsoft.com'
          'https://outlook.office.com'
        ]
        supportCredentials: true
      }
      use32BitWorkerProcess: false
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
    }
  }
  dependsOn: [
    storageAccessPolicy
    keyVaultAccessPolicy
  ]
}

// Diagnostic settings for Function App
resource functionAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableApplicationInsights) {
  scope: functionApp
  name: 'default'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
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
@description('The name of the Function App')
output functionAppName string = functionApp.name

@description('The URL of the Function App')
output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}'

@description('The name of the storage account')
output storageAccountName string = storageAccount.name

@description('The Application Insights connection string')
output applicationInsightsConnectionString string = enableApplicationInsights
  ? applicationInsights!.properties.ConnectionString
  : ''

@description('The Key Vault URL')
output keyVaultUrl string = enableKeyVault ? keyVault!.properties.vaultUri : ''

@description('The managed identity client ID')
output managedIdentityClientId string = managedIdentity.properties.clientId

@description('The resource group name')
output resourceGroupName string = resourceGroup().name

@description('The environment name')
output environmentName string = environmentName
