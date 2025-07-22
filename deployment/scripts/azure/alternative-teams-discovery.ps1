#!/usr/bin/env pwsh
<#
.SYNOPSIS
Alternative Teams App Discovery using Azure CLI and REST API

.DESCRIPTION
Uses Azure CLI and REST API calls to find existing Teams apps when PowerShell modules don't work.

.NOTES
Author: GitHub Copilot
Date: July 22, 2025
#>

param(
    [string]$AppId = "ce52f3ea-a567-4540-9c12-3e7941b825bf"
)

Write-Host "🔍 Alternative Teams App Discovery" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# Function to get access token
function Get-AccessToken {
    Write-Host "`n🔐 Getting Microsoft Graph access token..." -ForegroundColor Green
    
    try {
        # Get token using Azure CLI
        $tokenInfo = az account get-access-token --resource "https://graph.microsoft.com" --output json | ConvertFrom-Json
        
        if ($tokenInfo.accessToken) {
            Write-Host "   ✅ Access token obtained" -ForegroundColor Green
            return $tokenInfo.accessToken
        }
    } catch {
        Write-Host "   ❌ Failed to get access token: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Function to search Teams apps via REST API
function Search-TeamsApps {
    param([string]$AccessToken)
    
    Write-Host "`n📱 Searching Teams apps via REST API..." -ForegroundColor Green
    
    try {
        $headers = @{
            'Authorization' = "Bearer $AccessToken"
            'Content-Type' = 'application/json'
        }
        
        # Get Teams apps from Graph API
        $uri = "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps"
        
        Write-Host "   🌐 Calling: $uri" -ForegroundColor Yellow
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET
        
        Write-Host "   📊 Found $($response.value.Count) Teams apps" -ForegroundColor White
        
        # Look for apps matching our criteria
        $matchingApps = @()
        
        foreach ($app in $response.value) {
            $match = $false
            $reason = ""
            
            # Check by external ID
            if ($app.externalId -eq $AppId) {
                $match = $true
                $reason = "External ID match"
            }
            # Check by display name containing our keywords
            elseif ($app.displayName -like "*Copilot*" -or $app.displayName -like "*Company*" -or $app.displayName -like "*Plugin*") {
                $match = $true
                $reason = "Display name keyword match"
            }
            
            if ($match) {
                $matchingApps += [PSCustomObject]@{
                    Id = $app.id
                    ExternalId = $app.externalId
                    DisplayName = $app.displayName
                    DistributionMethod = $app.distributionMethod
                    Reason = $reason
                }
            }
        }
        
        if ($matchingApps.Count -gt 0) {
            Write-Host "`n   ✅ Found $($matchingApps.Count) matching app(s):" -ForegroundColor Green
            foreach ($match in $matchingApps) {
                Write-Host "`n   📱 App: $($match.DisplayName)" -ForegroundColor Cyan
                Write-Host "      ID: $($match.Id)" -ForegroundColor White
                Write-Host "      External ID: $($match.ExternalId)" -ForegroundColor White
                Write-Host "      Distribution: $($match.DistributionMethod)" -ForegroundColor White
                Write-Host "      Match Reason: $($match.Reason)" -ForegroundColor Gray
            }
        } else {
            Write-Host "`n   ⚠️  No apps found matching App ID: $AppId" -ForegroundColor Yellow
            Write-Host "   🔍 But found these potentially related apps:" -ForegroundColor Cyan
            
            # Show apps with similar names
            $similarApps = $response.value | Where-Object { 
                $_.displayName -like "*Plugin*" -or 
                $_.displayName -like "*API*" -or 
                $_.displayName -like "*Bot*" -or
                $_.distributionMethod -eq "organization"
            } | Select-Object -First 10
            
            foreach ($app in $similarApps) {
                Write-Host "      • $($app.displayName) (ID: $($app.id))" -ForegroundColor White
            }
        }
        
        return $matchingApps
        
    } catch {
        Write-Host "   ❌ Error calling Graph API: $($_.Exception.Message)" -ForegroundColor Red
        
        # Try to get more details about the error
        if ($_.Exception.Response) {
            $errorDetails = $_.Exception.Response | ConvertTo-Json -Depth 3
            Write-Host "   📋 Error details: $errorDetails" -ForegroundColor Gray
        }
        
        return @()
    }
}

# Function to check Azure AD app and find related Teams apps
function Find-RelatedAppsInAzureAD {
    Write-Host "`n🔍 Checking Azure AD for related service principals..." -ForegroundColor Green
    
    try {
        # Get the service principal
        $sp = az ad sp show --id $AppId --output json 2>$null | ConvertFrom-Json
        
        if ($sp) {
            Write-Host "   ✅ Found Service Principal: $($sp.displayName)" -ForegroundColor Green
            Write-Host "   📧 Publisher Domain: $($sp.publisherName)" -ForegroundColor White
            
            # Check if there are any associated Teams apps
            $spInfo = az ad sp show --id $AppId --query "{displayName:displayName, appRoles:appRoles, tags:tags}" --output json | ConvertFrom-Json
            
            if ($spInfo.tags) {
                Write-Host "   🏷️ Tags: $($spInfo.tags -join ', ')" -ForegroundColor White
            }
            
            return $true
        } else {
            Write-Host "   ❌ Service Principal not found" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "   ❌ Error checking Azure AD: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to provide troubleshooting steps
function Show-TroubleshootingSteps {
    Write-Host "`n🔧 Troubleshooting Steps" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    
    Write-Host "`n1. 🌐 Check Teams Admin Center manually:" -ForegroundColor Yellow
    Write-Host "   • URL: https://admin.teams.microsoft.com/" -ForegroundColor White
    Write-Host "   • Go to: Teams apps → Manage apps" -ForegroundColor White
    Write-Host "   • Search for: 'Copilot', 'Plugin', 'Company', 'API'" -ForegroundColor White
    Write-Host "   • Check different status tabs: All, Custom apps, Blocked, etc." -ForegroundColor White
    
    Write-Host "`n2. 📱 Check different app states:" -ForegroundColor Yellow
    Write-Host "   • Available apps (approved)" -ForegroundColor White
    Write-Host "   • Blocked apps" -ForegroundColor White
    Write-Host "   • Pending approval" -ForegroundColor White
    Write-Host "   • Org-wide app settings" -ForegroundColor White
    
    Write-Host "`n3. 🔍 Look for app by Azure AD App ID:" -ForegroundColor Yellow
    Write-Host "   • Search specifically for: $AppId" -ForegroundColor White
    Write-Host "   • The app might be listed with a different display name" -ForegroundColor White
    
    Write-Host "`n4. 🗑️ If you find the existing app:" -ForegroundColor Yellow
    Write-Host "   • Note down its current status" -ForegroundColor White
    Write-Host "   • Remove it if it's in a bad state" -ForegroundColor White
    Write-Host "   • Then try uploading the new package" -ForegroundColor White
    
    Write-Host "`n5. 🆕 Alternative: Create with different App ID:" -ForegroundColor Yellow
    Write-Host "   • Create a new Azure AD app registration" -ForegroundColor White
    Write-Host "   • Update the Teams manifest with the new App ID" -ForegroundColor White
    Write-Host "   • Create fresh Teams app package" -ForegroundColor White
}

# Function to help create new package with different App ID
function Offer-NewAppCreation {
    Write-Host "`n🆕 Create New App Registration?" -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor Cyan
    
    $createNew = Read-Host "Would you like to create a new Azure AD app registration? (y/n)"
    
    if ($createNew.ToLower() -eq "y") {
        Write-Host "`n🔧 Creating new Azure AD app registration..." -ForegroundColor Green
        
        try {
            # Create new app registration
            $newApp = az ad app create --display-name "M365 Copilot Plugin API v2" --output json | ConvertFrom-Json
            
            if ($newApp) {
                Write-Host "   ✅ New app created!" -ForegroundColor Green
                Write-Host "   🆔 New App ID: $($newApp.appId)" -ForegroundColor White
                Write-Host "   📝 Display Name: $($newApp.displayName)" -ForegroundColor White
                
                Write-Host "`n📋 Next steps:" -ForegroundColor Yellow
                Write-Host "   1. Update teams-app/manifest.json with new App ID: $($newApp.appId)" -ForegroundColor White
                Write-Host "   2. Update plugins/plugin_manifest.json if needed" -ForegroundColor White
                Write-Host "   3. Recreate teams-app-package.zip" -ForegroundColor White
                Write-Host "   4. Upload new package to Teams Admin Center" -ForegroundColor White
                
                return $newApp.appId
            }
        } catch {
            Write-Host "   ❌ Failed to create new app: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    return $null
}

# Main execution
function Main {
    # Get access token
    $accessToken = Get-AccessToken
    
    if (-not $accessToken) {
        Write-Host "`n❌ Cannot proceed without access token" -ForegroundColor Red
        return
    }
    
    # Search for Teams apps
    $matchingApps = Search-TeamsApps -AccessToken $accessToken
    
    # Check Azure AD for service principal
    $spExists = Find-RelatedAppsInAzureAD
    
    # Show troubleshooting steps
    Show-TroubleshootingSteps
    
    # Offer to create new app if needed
    if ($matchingApps.Count -eq 0) {
        $newAppId = Offer-NewAppCreation
        
        if ($newAppId) {
            Write-Host "`n🎯 New App ID created: $newAppId" -ForegroundColor Green
            Write-Host "Use this App ID to create a fresh Teams app package!" -ForegroundColor Green
        }
    }
    
    Write-Host "`n✅ Discovery complete!" -ForegroundColor Green
}

# Execute main function
Main
