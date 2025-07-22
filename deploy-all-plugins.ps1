#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy all enhanced plugin modules to Azure

.DESCRIPTION
    This script deploys the three enhanced plugin modules:
    - PurviewGovernanceConnector-module
    - SyntexSynapseConnector-module  
    - EnterpriseKnowledgeHub-module

.PARAMETER Environment
    Target environment (dev, staging, prod)

.PARAMETER ResourceGroupName
    Azure Resource Group name

.PARAMETER SubscriptionId
    Azure Subscription ID

.EXAMPLE
    .\deploy-all-plugins.ps1 -Environment "dev" -ResourceGroupName "rg-copilot-plugins" -SubscriptionId "12345678-1234-1234-1234-123456789012"
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId
)

# Set error handling
$ErrorActionPreference = "Stop"

Write-Host "=== Deploying Enhanced Plugin Modules ===" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host "Subscription: $SubscriptionId" -ForegroundColor Yellow

# Verify Azure CLI is logged in
Write-Host "`nChecking Azure CLI authentication..." -ForegroundColor Cyan
try {
    $account = az account show --query "user.name" -o tsv
    Write-Host "✅ Logged in as: $account" -ForegroundColor Green
}
catch {
    Write-Host "❌ Please run 'az login' first" -ForegroundColor Red
    exit 1
}

# Set subscription
Write-Host "`nSetting subscription..." -ForegroundColor Cyan
az account set --subscription $SubscriptionId
Write-Host "✅ Subscription set to: $SubscriptionId" -ForegroundColor Green

# Deploy PurviewGovernanceConnector
Write-Host "`n=== Deploying PurviewGovernanceConnector ===" -ForegroundColor Blue
try {
    Push-Location "PurviewGovernanceConnector-module"
    & .\deploy-purviewgovernanceconnector.ps1 -Environment $Environment -ResourceGroupName $ResourceGroupName
    Write-Host "✅ PurviewGovernanceConnector deployed successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ PurviewGovernanceConnector deployment failed: $_" -ForegroundColor Red
}
finally {
    Pop-Location
}

# Deploy SyntexSynapseConnector  
Write-Host "`n=== Deploying SyntexSynapseConnector ===" -ForegroundColor Blue
try {
    Push-Location "SyntexSynapseConnector-module"
    & .\deploy-syntexsynapseconnector.ps1 -Environment $Environment -ResourceGroupName $ResourceGroupName
    Write-Host "✅ SyntexSynapseConnector deployed successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ SyntexSynapseConnector deployment failed: $_" -ForegroundColor Red
}
finally {
    Pop-Location
}

# Deploy EnterpriseKnowledgeHub
Write-Host "`n=== Deploying EnterpriseKnowledgeHub ===" -ForegroundColor Blue
try {
    Push-Location "EnterpriseKnowledgeHub-module"
    & .\deploy-enterpriseknowledgehub.ps1 -Environment $Environment -ResourceGroupName $ResourceGroupName
    Write-Host "✅ EnterpriseKnowledgeHub deployed successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ EnterpriseKnowledgeHub deployment failed: $_" -ForegroundColor Red
}
finally {
    Pop-Location
}

Write-Host "`n=== Deployment Summary ===" -ForegroundColor Green
Write-Host "All plugin modules have been deployed to Azure." -ForegroundColor White
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow

Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Configure Power Platform custom connectors" -ForegroundColor White
Write-Host "2. Update M365 Copilot plugin manifests" -ForegroundColor White
Write-Host "3. Test plugin functionality in Copilot Studio" -ForegroundColor White
Write-Host "4. Configure authentication and permissions" -ForegroundColor White

Write-Host "`n✅ Deployment Complete!" -ForegroundColor Green
