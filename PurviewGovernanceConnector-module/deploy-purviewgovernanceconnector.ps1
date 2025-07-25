#!/usr/bin/env pwsh
<#
.SYNOPSIS
Deploy PurviewGovernanceConnector Module

.DESCRIPTION
Deploys the PurviewGovernanceConnector plugin module to Power Platform with enterprise security.

.NOTES
Generated by Plugin Generator on 2025-07-22 09:19:04
#>

param(
    [string]$Environment = "de96b383-5f31-4895-9b41-88f3b7435919",
    [switch]$UseSecureConnector = $true
)

Write-Host "🛡️ Deploying PurviewGovernanceConnector Module" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Function to deploy connector
function Deploy-PurviewGovernanceConnectorConnector {
    Write-Host "
🔌 Deploying Power Platform connector..." -ForegroundColor Green
    
    try {
        # Check authentication
        $authStatus = pac auth list
        if (-not $authStatus) {
            Write-Host "   ❌ Not authenticated to Power Platform" -ForegroundColor Red
            Write-Host "   💡 Run: pac auth create --url https://org29f8dd94.crm.dynamics.com/" -ForegroundColor Yellow
            return $false
        }
        
        # Deploy connector
        if ($UseSecureConnector) {
            Write-Host "   🔐 Using secure connector with Key Vault..." -ForegroundColor Green
            $result = pac connector create --api-definition-file "connector-definition-secure.json" --api-properties-file "connector-properties-secure.json"
        } else {
            Write-Host "   🔌 Using standard connector..." -ForegroundColor Green
            $result = pac connector create --api-definition-file "connector-definition.json" --api-properties-file "connector-properties.json"
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ PurviewGovernanceConnector connector deployed successfully!" -ForegroundColor Green
            
            # Extract connector ID from output
            $connectorId = ($result | Select-String "Connector created with ID (.+)" -AllMatches).Matches[0].Groups[1].Value
            if ($connectorId) {
                Write-Host "   🆔 Connector ID: $connectorId" -ForegroundColor White
                Write-Host "   🌐 Manage: https://make.powerapps.com/environments/$Environment/customconnectors/$connectorId" -ForegroundColor White
            }
            
            return $true
        } else {
            Write-Host "   ❌ Connector deployment failed" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "   ❌ Deployment error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to test connector
function Test-PurviewGovernanceConnectorConnector {
    Write-Host "
🧪 Testing connector functionality..." -ForegroundColor Green
    
    try {
        # Test health endpoint
        $healthUrl = "https://copilot-plugin-func-f46zzw7hhsh2q.azurewebsites.net/api/purviewgovernanceconnector/health"
        $response = Invoke-RestMethod -Uri $healthUrl -Method GET -TimeoutSec 10
        
        if ($response.status -eq "healthy") {
            Write-Host "   ✅ Health check passed" -ForegroundColor Green
            return $true
        } else {
            Write-Host "   ❌ Health check failed" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "   ❌ Health check error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to show next steps
function Show-NextSteps {
    Write-Host "
📋 Next Steps for PurviewGovernanceConnector" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan
    
    Write-Host "
1. 🔧 Test Your Connector:" -ForegroundColor Yellow
    Write-Host "   • Open Power Platform: https://make.powerapps.com/environments/$Environment/customconnectors" -ForegroundColor White
    Write-Host "   • Find 'PurviewGovernanceConnector' connector" -ForegroundColor White
    Write-Host "   • Click 'Test' tab and create a test connection" -ForegroundColor White
    
    Write-Host "
2. 🎯 Create Flows:" -ForegroundColor Yellow
    Write-Host "   • Power Automate: https://make.powerautomate.com/" -ForegroundColor White
    Write-Host "   • Use 'PurviewGovernanceConnector' connector in new flows" -ForegroundColor White
    Write-Host "   • Available operations: 6 endpoints" -ForegroundColor White
    
    Write-Host "
3. 📱 Build Apps:" -ForegroundColor Yellow
    Write-Host "   • Power Apps: https://make.powerapps.com/" -ForegroundColor White
    Write-Host "   • Add 'PurviewGovernanceConnector' as data source" -ForegroundColor White
    Write-Host "   • Integrate with your app logic" -ForegroundColor White
    
    Write-Host "
4. 🤖 M365 Copilot Integration:" -ForegroundColor Yellow
    Write-Host "   • Operations available in M365 Copilot context" -ForegroundColor White
    Write-Host "   • Test with natural language queries" -ForegroundColor White
    Write-Host "   • Category: Governance & Compliance" -ForegroundColor White
}

# Main deployment execution
function Main {
    Write-Host "
🎯 Starting PurviewGovernanceConnector deployment..." -ForegroundColor Green
    
    # Deploy connector
    $connectorDeployed = Deploy-PurviewGovernanceConnectorConnector
    if (-not $connectorDeployed) {
        Write-Host "
❌ Deployment failed!" -ForegroundColor Red
        return
    }
    
    # Test connector
    $connectorTested = Test-PurviewGovernanceConnectorConnector
    if (-not $connectorTested) {
        Write-Host "
⚠️  Connector deployed but health check failed" -ForegroundColor Yellow
    }
    
    # Show next steps
    Show-NextSteps
    
    Write-Host "
🎉 PurviewGovernanceConnector deployment complete!" -ForegroundColor Green
    Write-Host "🛡️ Your PurviewGovernanceConnector plugin is ready to use!" -ForegroundColor Green
}

# Execute deployment
Main
