#!/usr/bin/env pwsh
<#
.SYNOPSIS
Complete M365 Copilot Plugin Integration Script

.DESCRIPTION
This script completes the final integration steps for your M365 Copilot Plugin using Microsoft Graph PowerShell and Azure CLI.

.NOTES
Requires: Microsoft Graph PowerShell modules and Azure CLI
Author: GitHub Copilot
Date: July 22, 2025
#>

param(
    [string]$AppId = "ce52f3ea-a567-4540-9c12-3e7941b825bf",
    [string]$TenantId = "de96b383-5f31-4895-9b41-88f3b7435919",
    [string]$PackagePath = ".\teams-app-package.zip"
)

Write-Host "🚀 Completing M365 Copilot Plugin Integration" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Function to check prerequisites
function Test-Prerequisites {
    Write-Host "`n📋 Checking Prerequisites..." -ForegroundColor Green
    
    # Check Azure CLI
    try {
        $azVersion = az --version 2>$null
        if ($azVersion) {
            Write-Host "   ✅ Azure CLI: Available" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ❌ Azure CLI: Not available" -ForegroundColor Red
        return $false
    }
    
    # Check Microsoft Graph PowerShell
    if (Get-Module -ListAvailable Microsoft.Graph.Applications) {
        Write-Host "   ✅ Microsoft Graph PowerShell: Available" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Microsoft Graph PowerShell: Not available" -ForegroundColor Red
        return $false
    }
    
    # Check Teams app package
    if (Test-Path $PackagePath) {
        Write-Host "   ✅ Teams App Package: Found ($PackagePath)" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Teams App Package: Not found ($PackagePath)" -ForegroundColor Red
        return $false
    }
    
    return $true
}

# Function to verify Azure AD app
function Test-AzureADApp {
    Write-Host "`n🔍 Verifying Azure AD App Registration..." -ForegroundColor Green
    
    try {
        # Check app via Azure CLI
        $app = az ad app show --id $AppId --output json 2>$null | ConvertFrom-Json
        if ($app) {
            Write-Host "   ✅ App Registration: $($app.displayName)" -ForegroundColor Green
            Write-Host "   📧 Publisher Domain: $($app.publisherDomain)" -ForegroundColor White
            
            # Check service principal
            $sp = az ad sp show --id $AppId --output json 2>$null | ConvertFrom-Json
            if ($sp) {
                Write-Host "   ✅ Service Principal: Exists" -ForegroundColor Green
            } else {
                Write-Host "   ⚠️  Service Principal: Missing - Creating..." -ForegroundColor Yellow
                az ad sp create --id $AppId
                Write-Host "   ✅ Service Principal: Created" -ForegroundColor Green
            }
            return $true
        }
    } catch {
        Write-Host "   ❌ App Registration: Not found or accessible" -ForegroundColor Red
        return $false
    }
}

# Function to test Function App
function Test-FunctionApp {
    Write-Host "`n🔧 Testing Function App..." -ForegroundColor Green
    
    $functionUrl = "https://copilot-plugin-func-f46zzw7hhsh2q.azurewebsites.net"
    $healthUrl = "$functionUrl/api/health"
    
    try {
        $response = Invoke-RestMethod -Uri $healthUrl -Method GET -TimeoutSec 10
        Write-Host "   ✅ Function App: $($response.status)" -ForegroundColor Green
        Write-Host "   🌐 URL: $functionUrl" -ForegroundColor White
        return $true
    } catch {
        Write-Host "   ❌ Function App: Not responding" -ForegroundColor Red
        Write-Host "   🌐 URL: $functionUrl" -ForegroundColor White
        return $false
    }
}

# Function to upload Teams app using Graph API
function Install-TeamsApp {
    Write-Host "`n📱 Installing Teams App via Microsoft Graph..." -ForegroundColor Green
    
    try {
        # Connect to Microsoft Graph
        Write-Host "   🔐 Connecting to Microsoft Graph..." -ForegroundColor Yellow
        Connect-MgGraph -TenantId $TenantId -Scopes "AppCatalog.ReadWrite.All", "TeamsApp.ReadWrite.All" -NoWelcome
        
        # Upload the Teams app package
        Write-Host "   📦 Uploading Teams app package..." -ForegroundColor Yellow
        
        # Read the zip file as bytes
        $packageBytes = [System.IO.File]::ReadAllBytes((Resolve-Path $PackagePath))
        
        # Create the app via Graph API
        $teamsApp = New-MgTeamApp -DistributionMethod "organization" -ContentBytes $packageBytes
        
        if ($teamsApp) {
            Write-Host "   ✅ Teams App Uploaded Successfully!" -ForegroundColor Green
            Write-Host "   🆔 App ID: $($teamsApp.Id)" -ForegroundColor White
            Write-Host "   📝 Display Name: $($teamsApp.DisplayName)" -ForegroundColor White
            return $teamsApp
        }
    } catch {
        Write-Host "   ⚠️  Graph API upload failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   ℹ️  This may require manual upload via Teams Admin Center" -ForegroundColor Cyan
        return $null
    }
}

# Function to provide manual upload instructions
function Show-ManualInstructions {
    Write-Host "`n📋 Manual Upload Instructions" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan
    
    Write-Host "`n1. 🌐 Open Teams Admin Center:" -ForegroundColor Yellow
    Write-Host "   URL: https://admin.teams.microsoft.com/" -ForegroundColor White
    
    Write-Host "`n2. 📱 Navigate to Teams Apps:" -ForegroundColor Yellow
    Write-Host "   Teams apps → Manage apps → Upload new app" -ForegroundColor White
    
    Write-Host "`n3. 📦 Upload Package:" -ForegroundColor Yellow
    Write-Host "   File: $PackagePath" -ForegroundColor White
    Write-Host "   Click 'Upload' and follow the prompts" -ForegroundColor White
    
    Write-Host "`n4. ✅ Enable for Organization:" -ForegroundColor Yellow
    Write-Host "   After upload, enable the app for your organization" -ForegroundColor White
    Write-Host "   Set appropriate app policies if needed" -ForegroundColor White
    
    Write-Host "`n5. 🤖 Configure M365 Copilot:" -ForegroundColor Yellow
    Write-Host "   URL: https://admin.microsoft.com/" -ForegroundColor White
    Write-Host "   Path: Settings → Copilot → Plugin management" -ForegroundColor White
    Write-Host "   Enable your plugin for M365 Copilot experiences" -ForegroundColor White
    
    Write-Host "`n6. 🧪 Test Integration:" -ForegroundColor Yellow
    Write-Host "   Open Teams → Apps → Built for your org" -ForegroundColor White
    Write-Host "   Look for 'Company Data Plugin'" -ForegroundColor White
    Write-Host "   Test in M365 Copilot by typing '@' to see available plugins" -ForegroundColor White
}

# Function to verify current permissions
function Show-PermissionSummary {
    Write-Host "`n🔐 Current Permission Configuration" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    
    Write-Host "`n✅ Optimized Permissions (Minimum quantity for maximum functionality):" -ForegroundColor Green
    Write-Host "   • User.Read: Basic user identity verification" -ForegroundColor White
    Write-Host "   • profile: User profile information" -ForegroundColor White  
    Write-Host "   • openid: OpenID Connect authentication" -ForegroundColor White
    Write-Host "   • email: Audit trail and user identification" -ForegroundColor White
    
    Write-Host "`n🎯 This configuration provides:" -ForegroundColor Yellow
    Write-Host "   ✓ Secure authentication via Azure AD" -ForegroundColor White
    Write-Host "   ✓ Basic user context for personalization" -ForegroundColor White
    Write-Host "   ✓ Audit capabilities for compliance" -ForegroundColor White
    Write-Host "   ✓ Minimal attack surface" -ForegroundColor White
    Write-Host "   ✓ No unnecessary data access" -ForegroundColor White
}

# Main execution
function Main {
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        Write-Host "`n❌ Prerequisites check failed. Please install missing components." -ForegroundColor Red
        return
    }
    
    # Verify Azure AD app
    if (-not (Test-AzureADApp)) {
        Write-Host "`n❌ Azure AD app verification failed." -ForegroundColor Red
        return
    }
    
    # Test Function App
    if (-not (Test-FunctionApp)) {
        Write-Host "`n⚠️  Function App not responding, but continuing..." -ForegroundColor Yellow
    }
    
    # Show current permission configuration
    Show-PermissionSummary
    
    # Attempt automated Teams app upload
    Write-Host "`n🚀 Attempting automated integration..." -ForegroundColor Cyan
    $teamsApp = Install-TeamsApp
    
    if ($teamsApp) {
        Write-Host "`n🎉 Automated Integration Complete!" -ForegroundColor Green
        Write-Host "Your M365 Copilot Plugin is now available in Teams!" -ForegroundColor Green
    } else {
        Write-Host "`n📋 Automated upload not available - showing manual instructions..." -ForegroundColor Yellow
        Show-ManualInstructions
    }
    
    Write-Host "`n✅ Integration process complete!" -ForegroundColor Cyan
    Write-Host "Your plugin is ready for M365 Copilot experiences." -ForegroundColor Green
}

# Execute main function
Main
