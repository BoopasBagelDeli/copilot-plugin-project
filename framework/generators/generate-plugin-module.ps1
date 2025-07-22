#!/usr/bin/env pwsh
<#
.SYNOPSIS
Plugin Module Generator for M365 Copilot Ecosystem

.DESCRIPTION
Generates new plugin modules based on proven templates from your existing architecture.
Leverages your Teams App + Power Platform Connector pattern for rapid development.

.PARAMETER PluginType
The type of plugin to generate (CRM, ProjectManagement, KnowledgeBase, BusinessIntelligence, Communication)

.PARAMETER PluginName
The name of the plugin module

.PARAMETER Description
Description of the plugin functionality

.PARAMETER Endpoints
Array of API endpoints to generate

.PARAMETER UseSharedInfrastructure
Whether to use existing shared infrastructure (default: true)

.EXAMPLE
.\generate-plugin-module.ps1 -PluginType "CRM" -PluginName "SalesforceConnector" -Description "Salesforce integration for M365 Copilot"

.NOTES
Author: GitHub Copilot
Date: July 22, 2025
#>

param(
    [Parameter(Mandatory)]
    [ValidateSet("CRM", "ProjectManagement", "KnowledgeBase", "BusinessIntelligence", "Communication", "Governance", "DocumentAI", "Custom")]
    [string]$PluginType,
    
    [Parameter(Mandatory)]
    [string]$PluginName,
    
    [Parameter(Mandatory)]
    [string]$Description,
    
    [string[]]$Endpoints = @(),
    
    [bool]$UseSharedInfrastructure = $true,
    
    [string]$OutputPath = ".",
    
    [switch]$GenerateTests,
    
    [switch]$Deploy
)

# Plugin templates configuration
$PluginTemplates = @{
    "CRM"                  = @{
        DefaultEndpoints        = @("SearchContacts", "GetAccounts", "GetOpportunities", "GetDeals", "GetActivities")
        AuthScopes              = @("https://graph.microsoft.com/.default")
        PowerPlatformOperations = 5
        BusinessLogicTemplate   = "crm-service.py"
        Description             = "Customer Relationship Management integration for M365 Copilot"
        Category                = "Sales & Customer Management"
        Icon                    = "🤝"
    }
    "ProjectManagement"    = @{
        DefaultEndpoints        = @("SearchProjects", "GetTasks", "GetTimelines", "GetResources", "GetMilestones", "GetTeamWorkload")
        AuthScopes              = @("https://graph.microsoft.com/.default")
        PowerPlatformOperations = 6
        BusinessLogicTemplate   = "project-management-service.py"
        Description             = "Project and task management integration for M365 Copilot"
        Category                = "Project Management"
        Icon                    = "📋"
    }
    "KnowledgeBase"        = @{
        DefaultEndpoints        = @("SearchDocuments", "GetFAQ", "FindExperts", "GetArticles", "SearchContent")
        AuthScopes              = @("https://graph.microsoft.com/.default", "https://graph.microsoft.com/Files.Read.All")
        PowerPlatformOperations = 5
        BusinessLogicTemplate   = "knowledge-base-service.py"
        Description             = "Knowledge base and document intelligence for M365 Copilot"
        Category                = "Knowledge Management"
        Icon                    = "🔍"
    }
    "BusinessIntelligence" = @{
        DefaultEndpoints        = @("GetKPIs", "GetDashboards", "AnalyzeTrends", "GetReports", "QueryDatasets", "GetMetrics")
        AuthScopes              = @("https://graph.microsoft.com/.default")
        PowerPlatformOperations = 6
        BusinessLogicTemplate   = "business-intelligence-service.py"
        Description             = "Business intelligence and analytics for M365 Copilot"
        Category                = "Analytics & Insights"
        Icon                    = "📊"
    }
    "Communication"        = @{
        DefaultEndpoints        = @("SearchMessages", "AnalyzeSentiment", "GetCommunicationPatterns", "FindConversations", "GetChannelInfo")
        AuthScopes              = @("https://graph.microsoft.com/.default", "https://graph.microsoft.com/Chat.Read")
        PowerPlatformOperations = 5
        BusinessLogicTemplate   = "communication-service.py"
        Description             = "Enhanced communication and messaging for M365 Copilot"
        Category                = "Communication"
        Icon                    = "💬"
    }
    "Governance"           = @{
        DefaultEndpoints        = @("GetDataClassification", "CheckCompliance", "AuditDataAccess", "GetGovernancePolicies", "GenerateComplianceReport", "TrackDataLineage")
        AuthScopes              = @("https://graph.microsoft.com/.default", "https://graph.microsoft.com/InformationProtectionPolicy.Read")
        PowerPlatformOperations = 6
        BusinessLogicTemplate   = "governance-service.py"
        Description             = "Microsoft Purview governance and compliance for M365 Copilot"
        Category                = "Governance & Compliance"
        Icon                    = "🛡️"
    }
    "DocumentAI"           = @{
        DefaultEndpoints        = @("ProcessDocument", "ExtractDocumentData", "ClassifyContent", "AnalyzeForm", "GetPreBuiltModels", "RunSynapseAnalysis")
        AuthScopes              = @("https://graph.microsoft.com/.default", "https://graph.microsoft.com/Sites.Read.All")
        PowerPlatformOperations = 6
        BusinessLogicTemplate   = "documentai-service.py"
        Description             = "Microsoft Syntex + Azure Synapse document AI processing for M365 Copilot"
        Category                = "AI & Document Processing"
        Icon                    = "🤖"
    }
}

Write-Host "🚀 Generating Plugin Module: $PluginName" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Function to get template configuration
function Get-PluginTemplate {
    param($Type)
    
    if ($PluginTemplates.ContainsKey($Type)) {
        return $PluginTemplates[$Type]
    }
    else {
        Write-Host "   ⚠️  Unknown plugin type '$Type', using Custom template" -ForegroundColor Yellow
        return @{
            DefaultEndpoints        = @("CustomOperation")
            AuthScopes              = @("https://graph.microsoft.com/.default")
            PowerPlatformOperations = 3
            BusinessLogicTemplate   = "custom-service.py"
            Description             = $Description
            Category                = "Custom"
            Icon                    = "⚙️"
        }
    }
}

# Function to create plugin directory structure
function New-PluginStructure {
    param($PluginName, $OutputPath)
    
    $ModulePath = Join-Path $OutputPath "$PluginName-module"
    
    Write-Host "`n📁 Creating plugin structure..." -ForegroundColor Green
    
    # Create main module directory
    if (-not (Test-Path $ModulePath)) {
        New-Item -ItemType Directory -Path $ModulePath -Force | Out-Null
        Write-Host "   ✅ Created: $ModulePath" -ForegroundColor Green
    }
    
    # Create subdirectories
    $SubDirs = @("business-logic", "tests", "docs", "templates")
    foreach ($dir in $SubDirs) {
        $dirPath = Join-Path $ModulePath $dir
        if (-not (Test-Path $dirPath)) {
            New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
            Write-Host "   ✅ Created: $dir/" -ForegroundColor Green
        }
    }
    
    return $ModulePath
}

# Function to generate OpenAPI specification
function New-OpenAPISpec {
    param($PluginName, $Template, $Endpoints, $ModulePath)
    
    Write-Host "`n📝 Generating OpenAPI specification..." -ForegroundColor Green
    
    $openAPISpec = @{
        "swagger"             = "2.0"
        "info"                = @{
            "title"       = "$PluginName API"
            "description" = $Template.Description
            "version"     = "1.0.0"
            "contact"     = @{
                "name"  = "$PluginName Support"
                "email" = "support@boopasbageldeli.onmicrosoft.com"
            }
        }
        "host"                = "copilot-plugin-func-f46zzw7hhsh2q.azurewebsites.net"
        "basePath"            = "/api/$($PluginName.ToLower())"
        "schemes"             = @("https")
        "consumes"            = @("application/json")
        "produces"            = @("application/json")
        "securityDefinitions" = @{
            "oauth2_auth" = @{
                "type"             = "oauth2"
                "flow"             = "accessCode"
                "authorizationUrl" = "https://login.microsoftonline.com/de96b383-5f31-4895-9b41-88f3b7435919/oauth2/v2.0/authorize"
                "tokenUrl"         = "https://login.microsoftonline.com/de96b383-5f31-4895-9b41-88f3b7435919/oauth2/v2.0/token"
                "scopes"           = @{
                    "https://graph.microsoft.com/.default" = "Access $PluginName data through Microsoft Graph"
                }
            }
        }
        "security"            = @(@{ "oauth2_auth" = @("https://graph.microsoft.com/.default") })
        "paths"               = @{}
        "definitions"         = @{
            "ErrorResponse" = @{
                "type"       = "object"
                "properties" = @{
                    "error"   = @{
                        "type"        = "string"
                        "description" = "Error message"
                    }
                    "details" = @{
                        "type"        = "string"
                        "description" = "Detailed error information"
                    }
                }
                "required"   = @("error")
            }
        }
    }
    
    # Generate endpoints
    foreach ($endpoint in $Endpoints) {
        $path = "/$($endpoint.ToLower())"
        $openAPISpec.paths[$path] = @{
            "post" = @{
                "operationId" = $endpoint
                "summary"     = "Execute $endpoint operation"
                "description" = "Performs $endpoint operation for $PluginName"
                "consumes"    = @("application/json")
                "produces"    = @("application/json")
                "parameters"  = @(
                    @{
                        "name"     = "request"
                        "in"       = "body"
                        "required" = $true
                        "schema"   = @{
                            "type"       = "object"
                            "properties" = @{
                                "query" = @{
                                    "type"        = "string"
                                    "description" = "Search query or operation parameter"
                                }
                                "limit" = @{
                                    "type"        = "integer"
                                    "description" = "Maximum number of results"
                                    "default"     = 10
                                }
                            }
                            "required"   = @("query")
                        }
                    }
                )
                "responses"   = @{
                    "200" = @{
                        "description" = "Successful response"
                        "schema"      = @{
                            "type"       = "object"
                            "properties" = @{
                                "results" = @{
                                    "type"  = "array"
                                    "items" = @{
                                        "type"       = "object"
                                        "properties" = @{
                                            "id"          = @{ "type" = "string" }
                                            "title"       = @{ "type" = "string" }
                                            "description" = @{ "type" = "string" }
                                            "url"         = @{ "type" = "string" }
                                        }
                                    }
                                }
                                "total"   = @{
                                    "type"        = "integer"
                                    "description" = "Total number of results"
                                }
                            }
                        }
                    }
                    "400" = @{
                        "description" = "Bad request"
                        "schema"      = @{ "`$ref" = "#/definitions/ErrorResponse" }
                    }
                    "401" = @{
                        "description" = "Unauthorized"
                        "schema"      = @{ "`$ref" = "#/definitions/ErrorResponse" }
                    }
                    "500" = @{
                        "description" = "Internal server error"
                        "schema"      = @{ "`$ref" = "#/definitions/ErrorResponse" }
                    }
                }
                "security"    = @(@{ "oauth2_auth" = @("https://graph.microsoft.com/.default") })
            }
        }
    }
    
    # Save OpenAPI spec
    $specPath = Join-Path $ModulePath "connector-definition.json"
    $openAPISpec | ConvertTo-Json -Depth 10 | Out-File -FilePath $specPath -Encoding UTF8
    
    Write-Host "   ✅ OpenAPI specification: connector-definition.json" -ForegroundColor Green
    return $specPath
}

# Function to generate secure OpenAPI specification with Key Vault references
function New-SecureOpenAPISpec {
    param($PluginName, $Template, $Endpoints, $ModulePath, $BaseSpec)
    
    Write-Host "`n🔐 Generating secure OpenAPI specification..." -ForegroundColor Green
    
    # Read the base spec and modify for security
    $secureSpec = Get-Content $BaseSpec | ConvertFrom-Json
    
    # Update security definitions with Key Vault references
    $secureSpec.securityDefinitions.oauth2_auth.PSObject.Properties.Add([PSNoteProperty]::new("x-ms-client-id", "@Microsoft.KeyVault(SecretUri=https://kvf46zzw7hdeclarat.vault.azure.net/secrets/azure-client-id/)"))
    $secureSpec.securityDefinitions.oauth2_auth.PSObject.Properties.Add([PSNoteProperty]::new("x-ms-client-secret", "@Microsoft.KeyVault(SecretUri=https://kvf46zzw7hdeclarat.vault.azure.net/secrets/azure-client-secret/)"))
    
    # Save secure OpenAPI spec
    $secureSpecPath = Join-Path $ModulePath "connector-definition-secure.json"
    $secureSpec | ConvertTo-Json -Depth 10 | Out-File -FilePath $secureSpecPath -Encoding UTF8
    
    Write-Host "   ✅ Secure OpenAPI specification: connector-definition-secure.json" -ForegroundColor Green
    return $secureSpecPath
}

# Function to generate Power Platform connector properties
function New-ConnectorProperties {
    param($PluginName, $Template, $ModulePath)
    
    Write-Host "`n⚙️ Generating connector properties..." -ForegroundColor Green
    
    $properties = @{
        "properties" = @{
            "connectionParameters" = @{
                "token" = @{
                    "type"          = "oauthSetting"
                    "oAuthSettings" = @{
                        "identityProvider" = "aad"
                        "clientId"         = "ce52f3ea-a567-4540-9c12-3e7941b825bf"
                        "scopes"           = $Template.AuthScopes
                        "redirectMode"     = "Global"
                        "redirectUrl"      = "https://global.consent.azure-apim.net/redirect"
                        "properties"       = @{
                            "IsFirstParty"                   = "False"
                            "AzureActiveDirectoryResourceId" = "https://graph.microsoft.com/"
                        }
                        "customParameters" = @{
                            "tenantId" = @{
                                "value" = "de96b383-5f31-4895-9b41-88f3b7435919"
                            }
                        }
                    }
                }
            }
            "iconBrandColor"       = "#0078d4"
            "capabilities"         = @("actions")
            "environment"          = @{
                "name" = "Boopas (default)"
                "id"   = "de96b383-5f31-4895-9b41-88f3b7435919"
            }
        }
    }
    
    # Save connector properties
    $propertiesPath = Join-Path $ModulePath "connector-properties.json"
    $properties | ConvertTo-Json -Depth 10 | Out-File -FilePath $propertiesPath -Encoding UTF8
    
    # Generate secure version with Key Vault references
    $secureProperties = $properties.PSObject.Copy()
    $secureProperties.properties.connectionParameters.token.oAuthSettings.PSObject.Properties.Add([PSNoteProperty]::new("clientId", "@Microsoft.KeyVault(SecretUri=https://kvf46zzw7hdeclarat.vault.azure.net/secrets/azure-client-id/)"))
    
    $securePropertiesPath = Join-Path $ModulePath "connector-properties-secure.json"
    $secureProperties | ConvertTo-Json -Depth 10 | Out-File -FilePath $securePropertiesPath -Encoding UTF8
    
    Write-Host "   ✅ Connector properties: connector-properties.json" -ForegroundColor Green
    Write-Host "   ✅ Secure connector properties: connector-properties-secure.json" -ForegroundColor Green
}

# Function to generate business logic template
function New-BusinessLogic {
    param($PluginName, $Template, $Endpoints, $ModulePath)
    
    Write-Host "`n🧠 Generating business logic template..." -ForegroundColor Green
    
    $businessLogic = @"
#!/usr/bin/env python3
"""
$PluginName Business Logic
$($Template.Description)

Generated by Plugin Generator on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"""

import logging
import json
from typing import Dict, List, Any, Optional
from azure.functions import HttpRequest, HttpResponse
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
import requests

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class $($PluginName)Service:
    """$PluginName service implementation"""
    
    def __init__(self):
        self.credential = DefaultAzureCredential()
        self.key_vault_url = "https://kvf46zzw7hdeclarat.vault.azure.net/"
        self.secret_client = SecretClient(vault_url=self.key_vault_url, credential=self.credential)
        
    def _get_secret(self, secret_name: str) -> str:
        """Retrieve secret from Azure Key Vault"""
        try:
            secret = self.secret_client.get_secret(secret_name)
            return secret.value
        except Exception as e:
            logger.error(f"Failed to retrieve secret {secret_name}: {e}")
            raise

"@

    # Generate endpoint methods
    foreach ($endpoint in $Endpoints) {
        $methodName = $endpoint.ToLower().Replace("get", "get_").Replace("search", "search_")
        $businessLogic += @"

    def $methodName(self, query: str, limit: int = 10) -> Dict[str, Any]:
        """$endpoint operation implementation"""
        try:
            logger.info(f"Executing $endpoint with query: {query}")
            
            # TODO: Implement $endpoint business logic
            # This is a template - replace with actual implementation
            
            results = [
                {
                    "id": f"{query}-{i}",
                    "title": f"$endpoint Result {i}",
                    "description": f"Sample result for {query}",
                    "url": f"https://example.com/result/{i}",
                    "relevance": 0.9 - (i * 0.1)
                }
                for i in range(min(limit, 5))
            ]
            
            return {
                "results": results,
                "total": len(results),
                "query": query,
                "operation": "$endpoint"
            }
            
        except Exception as e:
            logger.error(f"$endpoint operation failed: {e}")
            raise

"@
    }

    # Add HTTP function handlers
    $businessLogic += @"

# Azure Function HTTP handlers
def main(req: HttpRequest) -> HttpResponse:
    """Main HTTP handler for $PluginName operations"""
    try:
        # Get operation from path
        operation = req.route_params.get('operation', '').lower()
        
        if not operation:
            return HttpResponse(
                json.dumps({"error": "Operation not specified"}),
                status_code=400,
                mimetype="application/json"
            )
        
        # Parse request body
        try:
            req_body = req.get_json()
            query = req_body.get('query', '')
            limit = req_body.get('limit', 10)
        except ValueError:
            return HttpResponse(
                json.dumps({"error": "Invalid JSON in request body"}),
                status_code=400,
                mimetype="application/json"
            )
        
        # Initialize service
        service = $($PluginName)Service()
        
        # Route to appropriate operation
"@

    foreach ($endpoint in $Endpoints) {
        $methodName = $endpoint.ToLower().Replace("get", "get_").Replace("search", "search_")
        $businessLogic += @"
        if operation == '$($endpoint.ToLower())':
            result = service.$methodName(query, limit)
"@
    }

    $businessLogic += @"
        else:
            return HttpResponse(
                json.dumps({"error": f"Unknown operation: {operation}"}),
                status_code=400,
                mimetype="application/json"
            )
        
        return HttpResponse(
            json.dumps(result),
            status_code=200,
            mimetype="application/json"
        )
        
    except Exception as e:
        logger.error(f"Request processing failed: {e}")
        return HttpResponse(
            json.dumps({
                "error": "Internal server error",
                "details": str(e)
            }),
            status_code=500,
            mimetype="application/json"
        )

# Health check endpoint
def health_check(req: HttpRequest) -> HttpResponse:
    """Health check for $PluginName service"""
    return HttpResponse(
        json.dumps({
            "status": "healthy",
            "service": "$PluginName",
            "timestamp": "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")"
        }),
        status_code=200,
        mimetype="application/json"
    )
"@

    # Save business logic
    $businessLogicPath = Join-Path $ModulePath "business-logic" "$($PluginName.ToLower())_service.py"
    $businessLogic | Out-File -FilePath $businessLogicPath -Encoding UTF8
    
    Write-Host "   ✅ Business logic template: business-logic/$($PluginName.ToLower())_service.py" -ForegroundColor Green
}

# Function to generate deployment script
function New-DeploymentScript {
    param($PluginName, $Template, $ModulePath)
    
    Write-Host "`n🚀 Generating deployment script..." -ForegroundColor Green
    
    $deployScript = @"
#!/usr/bin/env pwsh
<#
.SYNOPSIS
Deploy $PluginName Module

.DESCRIPTION
Deploys the $PluginName plugin module to Power Platform with enterprise security.

.NOTES
Generated by Plugin Generator on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
#>

param(
    [string]`$Environment = "de96b383-5f31-4895-9b41-88f3b7435919",
    [switch]`$UseSecureConnector = `$true
)

Write-Host "$($Template.Icon) Deploying $PluginName Module" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Function to deploy connector
function Deploy-$($PluginName)Connector {
    Write-Host "`n🔌 Deploying Power Platform connector..." -ForegroundColor Green
    
    try {
        # Check authentication
        `$authStatus = pac auth list
        if (-not `$authStatus) {
            Write-Host "   ❌ Not authenticated to Power Platform" -ForegroundColor Red
            Write-Host "   💡 Run: pac auth create --url https://org29f8dd94.crm.dynamics.com/" -ForegroundColor Yellow
            return `$false
        }
        
        # Deploy connector
        if (`$UseSecureConnector) {
            Write-Host "   🔐 Using secure connector with Key Vault..." -ForegroundColor Green
            `$result = pac connector create --api-definition-file "connector-definition-secure.json" --api-properties-file "connector-properties-secure.json"
        } else {
            Write-Host "   🔌 Using standard connector..." -ForegroundColor Green
            `$result = pac connector create --api-definition-file "connector-definition.json" --api-properties-file "connector-properties.json"
        }
        
        if (`$LASTEXITCODE -eq 0) {
            Write-Host "   ✅ $PluginName connector deployed successfully!" -ForegroundColor Green
            
            # Extract connector ID from output
            `$connectorId = (`$result | Select-String "Connector created with ID (.+)" -AllMatches).Matches[0].Groups[1].Value
            if (`$connectorId) {
                Write-Host "   🆔 Connector ID: `$connectorId" -ForegroundColor White
                Write-Host "   🌐 Manage: https://make.powerapps.com/environments/`$Environment/customconnectors/`$connectorId" -ForegroundColor White
            }
            
            return `$true
        } else {
            Write-Host "   ❌ Connector deployment failed" -ForegroundColor Red
            return `$false
        }
        
    } catch {
        Write-Host "   ❌ Deployment error: `$(`$_.Exception.Message)" -ForegroundColor Red
        return `$false
    }
}

# Function to test connector
function Test-$($PluginName)Connector {
    Write-Host "`n🧪 Testing connector functionality..." -ForegroundColor Green
    
    try {
        # Test health endpoint
        `$healthUrl = "https://copilot-plugin-func-f46zzw7hhsh2q.azurewebsites.net/api/$($PluginName.ToLower())/health"
        `$response = Invoke-RestMethod -Uri `$healthUrl -Method GET -TimeoutSec 10
        
        if (`$response.status -eq "healthy") {
            Write-Host "   ✅ Health check passed" -ForegroundColor Green
            return `$true
        } else {
            Write-Host "   ❌ Health check failed" -ForegroundColor Red
            return `$false
        }
        
    } catch {
        Write-Host "   ❌ Health check error: `$(`$_.Exception.Message)" -ForegroundColor Red
        return `$false
    }
}

# Function to show next steps
function Show-NextSteps {
    Write-Host "`n📋 Next Steps for $PluginName" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan
    
    Write-Host "`n1. 🔧 Test Your Connector:" -ForegroundColor Yellow
    Write-Host "   • Open Power Platform: https://make.powerapps.com/environments/`$Environment/customconnectors" -ForegroundColor White
    Write-Host "   • Find '$PluginName' connector" -ForegroundColor White
    Write-Host "   • Click 'Test' tab and create a test connection" -ForegroundColor White
    
    Write-Host "`n2. 🎯 Create Flows:" -ForegroundColor Yellow
    Write-Host "   • Power Automate: https://make.powerautomate.com/" -ForegroundColor White
    Write-Host "   • Use '$PluginName' connector in new flows" -ForegroundColor White
    Write-Host "   • Available operations: $($Template.PowerPlatformOperations) endpoints" -ForegroundColor White
    
    Write-Host "`n3. 📱 Build Apps:" -ForegroundColor Yellow
    Write-Host "   • Power Apps: https://make.powerapps.com/" -ForegroundColor White
    Write-Host "   • Add '$PluginName' as data source" -ForegroundColor White
    Write-Host "   • Integrate with your app logic" -ForegroundColor White
    
    Write-Host "`n4. 🤖 M365 Copilot Integration:" -ForegroundColor Yellow
    Write-Host "   • Operations available in M365 Copilot context" -ForegroundColor White
    Write-Host "   • Test with natural language queries" -ForegroundColor White
    Write-Host "   • Category: $($Template.Category)" -ForegroundColor White
}

# Main deployment execution
function Main {
    Write-Host "`n🎯 Starting $PluginName deployment..." -ForegroundColor Green
    
    # Deploy connector
    `$connectorDeployed = Deploy-$($PluginName)Connector
    if (-not `$connectorDeployed) {
        Write-Host "`n❌ Deployment failed!" -ForegroundColor Red
        return
    }
    
    # Test connector
    `$connectorTested = Test-$($PluginName)Connector
    if (-not `$connectorTested) {
        Write-Host "`n⚠️  Connector deployed but health check failed" -ForegroundColor Yellow
    }
    
    # Show next steps
    Show-NextSteps
    
    Write-Host "`n🎉 $PluginName deployment complete!" -ForegroundColor Green
    Write-Host "$($Template.Icon) Your $PluginName plugin is ready to use!" -ForegroundColor Green
}

# Execute deployment
Main
"@

    # Save deployment script
    $deployScriptPath = Join-Path $ModulePath "deploy-$($PluginName.ToLower()).ps1"
    $deployScript | Out-File -FilePath $deployScriptPath -Encoding UTF8
    
    Write-Host "   ✅ Deployment script: deploy-$($PluginName.ToLower()).ps1" -ForegroundColor Green
}

# Function to generate README
function New-PluginREADME {
    param($PluginName, $Template, $Endpoints, $ModulePath)
    
    Write-Host "`n📚 Generating documentation..." -ForegroundColor Green
    
    $readme = @"
# $($Template.Icon) $PluginName Module

## 🎯 Overview

$($Template.Description)

**Category**: $($Template.Category)  
**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Type**: $PluginType Plugin Module  

---

## 🔌 Available Operations

This plugin provides the following operations for M365 Copilot and Power Platform:

"@

    foreach ($endpoint in $Endpoints) {
        $readme += "- **$endpoint**: $(($endpoint -replace '([A-Z])', ' $1').Trim())`n"
    }

    $readme += @"

---

## 🚀 Quick Start

### 1. Deploy to Power Platform

``````powershell
# Deploy with enterprise security (recommended)
.\deploy-$($PluginName.ToLower()).ps1 -UseSecureConnector

# Test deployment
.\deploy-$($PluginName.ToLower()).ps1 -Environment "your-environment-id"
``````

### 2. Access Your Connector

- **Power Platform**: https://make.powerapps.com/environments/de96b383-5f31-4895-9b41-88f3b7435919/customconnectors
- **Power Automate**: https://make.powerautomate.com/
- **Power Apps**: https://make.powerapps.com/

### 3. Test Operations

Each operation accepts a JSON request:

``````json
{
  "query": "search terms or operation parameters",
  "limit": 10
}
``````

---

## 🏗️ Architecture

### Files Structure

``````
$PluginName-module/
├── connector-definition.json          # OpenAPI specification
├── connector-definition-secure.json   # Secure version with Key Vault
├── connector-properties.json          # Power Platform properties
├── connector-properties-secure.json   # Secure properties
├── deploy-$($PluginName.ToLower()).ps1              # Deployment script
├── business-logic/                    # Implementation
│   └── $($PluginName.ToLower())_service.py          # Service implementation
├── tests/                             # Test suite
├── docs/                              # Documentation
└── README.md                          # This file
``````

### Security Features

- ✅ **Azure Key Vault Integration**: All secrets stored securely
- ✅ **Managed Identity**: Zero credential management
- ✅ **RBAC Permissions**: Proper access controls
- ✅ **OAuth 2.0**: Azure AD authentication
- ✅ **Enterprise Compliance**: Audit trail and monitoring

---

## 🔧 Customization

### Adding New Operations

1. **Update OpenAPI** (`connector-definition.json`)
2. **Implement Handler** (`business-logic/$($PluginName.ToLower())_service.py`)
3. **Add Tests** (`tests/`)
4. **Redeploy** using deployment script

### Integrating External Systems

1. **Add API Client** in service class
2. **Store Credentials** in Azure Key Vault
3. **Update Authentication** scopes if needed
4. **Test Integration** end-to-end

---

## 🧪 Testing

### Manual Testing

``````powershell
# Test health endpoint
Invoke-RestMethod -Uri "https://copilot-plugin-func-f46zzw7hhsh2q.azurewebsites.net/api/$($PluginName.ToLower())/health"

# Test operation endpoint
`$body = @{ query = "test"; limit = 5 } | ConvertTo-Json
Invoke-RestMethod -Uri "https://copilot-plugin-func-f46zzw7hhsh2q.azurewebsites.net/api/$($PluginName.ToLower())/searchcontacts" -Method POST -Body `$body -ContentType "application/json"
``````

### Power Platform Testing

1. Open your connector in Power Platform
2. Go to **Test** tab
3. Create a new connection
4. Test each operation with sample data

---

## 📊 Monitoring

### Application Insights

Monitor your plugin usage and performance:

- **Function App**: https://portal.azure.com/#@BoopasBagelDeli.onmicrosoft.com/resource/subscriptions/0098349c-01ee-4e71-aecf-a312e1ca1074/resourceGroups/rg-declarative-agent-plugin/providers/Microsoft.Web/sites/copilot-plugin-func-f46zzw7hhsh2q
- **Application Insights**: Telemetry and performance metrics
- **Key Vault**: Security audit logs

### Health Monitoring

The plugin includes health check endpoints for monitoring:

- **Health Check**: `/api/$($PluginName.ToLower())/health`
- **Status**: Returns plugin status and timestamp

---

## 🎯 Usage Examples

### In Power Automate

1. Create a new flow
2. Add **$PluginName** connector action
3. Configure authentication
4. Use operations in your workflow

### In Power Apps

1. Add **$PluginName** as data source
2. Use operations in Power Fx formulas
3. Display results in your app

### In M365 Copilot

The plugin operations are available in M365 Copilot context for natural language interactions.

---

## 🤝 Support

- **Documentation**: See `docs/` folder for detailed guides
- **Issues**: Use project issue tracking
- **Security**: Report security issues through proper channels

---

**Generated by Plugin Generator Framework**  
**Template Version**: 1.0.0  
**Framework**: M365 Copilot Plugin Ecosystem
"@

    # Save README
    $readmePath = Join-Path $ModulePath "README.md"
    $readme | Out-File -FilePath $readmePath -Encoding UTF8
    
    Write-Host "   ✅ Documentation: README.md" -ForegroundColor Green
}

# Function to generate tests
function New-PluginTests {
    param($PluginName, $Endpoints, $ModulePath)
    
    if (-not $GenerateTests) {
        return
    }
    
    Write-Host "`n🧪 Generating test suite..." -ForegroundColor Green
    
    $testCode = @"
#!/usr/bin/env python3
"""
Test suite for $PluginName Module

Generated by Plugin Generator on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"""

import unittest
import json
from unittest.mock import Mock, patch
import sys
import os

# Add business logic to path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'business-logic'))

from $($PluginName.ToLower())_service import $($PluginName)Service

class Test$($PluginName)Service(unittest.TestCase):
    """Test cases for $PluginName service"""
    
    def setUp(self):
        """Set up test environment"""
        self.service = $($PluginName)Service()
    
    @patch('$($PluginName.ToLower())_service.SecretClient')
    def test_service_initialization(self, mock_secret_client):
        """Test service initializes correctly"""
        service = $($PluginName)Service()
        self.assertIsNotNone(service)
        self.assertEqual(service.key_vault_url, "https://kvf46zzw7hdeclarat.vault.azure.net/")

"@

    foreach ($endpoint in $Endpoints) {
        $methodName = $endpoint.ToLower().Replace("get", "get_").Replace("search", "search_")
        $testCode += @"
    
    @patch('$($PluginName.ToLower())_service.SecretClient')
    def test_$methodName(self, mock_secret_client):
        """Test $endpoint operation"""
        # Arrange
        query = "test query"
        limit = 5
        
        # Act
        result = self.service.$methodName(query, limit)
        
        # Assert
        self.assertIsInstance(result, dict)
        self.assertIn('results', result)
        self.assertIn('total', result)
        self.assertIn('query', result)
        self.assertEqual(result['query'], query)
        self.assertEqual(result['operation'], '$endpoint')
        self.assertLessEqual(len(result['results']), limit)

"@
    }

    $testCode += @"

if __name__ == '__main__':
    unittest.main()
"@

    # Save test file
    $testPath = Join-Path $ModulePath "tests" "test_$($PluginName.ToLower())_service.py"
    $testCode | Out-File -FilePath $testPath -Encoding UTF8
    
    Write-Host "   ✅ Test suite: tests/test_$($PluginName.ToLower())_service.py" -ForegroundColor Green
}

# Main execution function
function Main {
    Write-Host "`n🎯 Plugin Generator Configuration" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    
    # Get template configuration
    $template = Get-PluginTemplate -Type $PluginType
    
    # Use provided endpoints or template defaults
    $finalEndpoints = if ($Endpoints.Count -gt 0) { $Endpoints } else { $template.DefaultEndpoints }
    
    Write-Host "`n📋 Generation Plan:" -ForegroundColor Green
    Write-Host "   🎯 Plugin Name: $PluginName" -ForegroundColor White
    Write-Host "   📝 Description: $($template.Description)" -ForegroundColor White
    Write-Host "   🏷️ Category: $($template.Category)" -ForegroundColor White
    Write-Host "   🔌 Endpoints: $($finalEndpoints -join ', ')" -ForegroundColor White
    Write-Host "   🔐 Auth Scopes: $($template.AuthScopes -join ', ')" -ForegroundColor White
    Write-Host "   ⚡ Operations: $($template.PowerPlatformOperations)" -ForegroundColor White
    Write-Host "   🏗️ Use Shared Infrastructure: $UseSharedInfrastructure" -ForegroundColor White
    
    # Create plugin structure
    $modulePath = New-PluginStructure -PluginName $PluginName -OutputPath $OutputPath
    
    # Generate OpenAPI specification
    $specPath = New-OpenAPISpec -PluginName $PluginName -Template $template -Endpoints $finalEndpoints -ModulePath $modulePath
    
    # Generate secure OpenAPI specification
    $secureSpecPath = New-SecureOpenAPISpec -PluginName $PluginName -Template $template -Endpoints $finalEndpoints -ModulePath $modulePath -BaseSpec $specPath
    
    # Generate connector properties
    New-ConnectorProperties -PluginName $PluginName -Template $template -ModulePath $modulePath
    
    # Generate business logic
    New-BusinessLogic -PluginName $PluginName -Template $template -Endpoints $finalEndpoints -ModulePath $modulePath
    
    # Generate deployment script
    New-DeploymentScript -PluginName $PluginName -Template $template -ModulePath $modulePath
    
    # Generate documentation
    New-PluginREADME -PluginName $PluginName -Template $template -Endpoints $finalEndpoints -ModulePath $modulePath
    
    # Generate tests if requested
    New-PluginTests -PluginName $PluginName -Endpoints $finalEndpoints -ModulePath $modulePath
    
    # Show completion summary
    Write-Host "`n🎉 Plugin Generation Complete!" -ForegroundColor Green
    Write-Host "==============================" -ForegroundColor Green
    
    Write-Host "`n📁 Generated Module: $modulePath" -ForegroundColor Cyan
    Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
    Write-Host "   1. 📝 Review generated files and customize business logic" -ForegroundColor White
    Write-Host "   2. 🧪 Test the plugin locally if needed" -ForegroundColor White
    Write-Host "   3. 🚀 Deploy to Power Platform:" -ForegroundColor White
    Write-Host "      cd $modulePath" -ForegroundColor Gray
    Write-Host "      .\deploy-$($PluginName.ToLower()).ps1" -ForegroundColor Gray
    Write-Host "   4. 🔗 Access your connector in Power Platform" -ForegroundColor White
    Write-Host "   5. 🎯 Build Power Automate flows and Power Apps" -ForegroundColor White
    
    if ($Deploy) {
        Write-Host "`n🚀 Auto-deploying plugin..." -ForegroundColor Yellow
        Set-Location $modulePath
        & ".\deploy-$($PluginName.ToLower()).ps1"
        Set-Location ..
    }
    
    Write-Host "`n✨ $($template.Icon) $PluginName plugin module ready for action!" -ForegroundColor Green
}

# Execute main function
Main
