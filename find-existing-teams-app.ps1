#!/usr/bin/env pwsh
<#
.SYNOPSIS
Find and Manage Existing M365 Copilot Plugin in Teams

.DESCRIPTION
This script helps locate and manage an existing M365 Copilot Plugin that's already in the Teams system but may not be properly configured.

.NOTES
Requires: Microsoft Graph PowerShell modules
Author: GitHub Copilot
Date: July 22, 2025
#>

param(
    [string]$AppId = "ce52f3ea-a567-4540-9c12-3e7941b825bf",
    [string]$TenantId = "de96b383-5f31-4895-9b41-88f3b7435919",
    [string]$AppDisplayName = "M365 Copilot Plugin API"
)

Write-Host "🔍 Finding Existing M365 Copilot Plugin in Teams" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Function to connect to Microsoft Graph
function Connect-ToGraph {
    Write-Host "`n🔐 Connecting to Microsoft Graph..." -ForegroundColor Green
    try {
        # Connect with required scopes
        Connect-MgGraph -TenantId $TenantId -Scopes @(
            "AppCatalog.Read.All",
            "AppCatalog.ReadWrite.All", 
            "TeamsApp.Read.All",
            "TeamsApp.ReadWrite.All",
            "Application.Read.All"
        ) -NoWelcome
        
        $context = Get-MgContext
        Write-Host "   ✅ Connected as: $($context.Account)" -ForegroundColor Green
        Write-Host "   🏢 Tenant: $($context.TenantId)" -ForegroundColor White
        return $true
    } catch {
        Write-Host "   ❌ Failed to connect: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to find existing Teams apps
function Find-ExistingTeamsApps {
    Write-Host "`n📱 Searching for Existing Teams Apps..." -ForegroundColor Green
    
    try {
        # Get all Teams apps in the tenant
        Write-Host "   🔍 Retrieving all Teams apps..." -ForegroundColor Yellow
        $allApps = Get-MgTeamApp -All
        
        Write-Host "   📊 Found $($allApps.Count) total Teams apps" -ForegroundColor White
        
        # Look for apps matching our criteria
        $matchingApps = @()
        
        foreach ($app in $allApps) {
            $match = $false
            $reason = ""
            
            # Check by external ID (Azure AD App ID)
            if ($app.ExternalId -eq $AppId) {
                $match = $true
                $reason = "Exact App ID match"
            }
            # Check by display name
            elseif ($app.DisplayName -like "*$AppDisplayName*" -or $app.DisplayName -like "*Company Data Plugin*") {
                $match = $true
                $reason = "Display name match"
            }
            # Check by app ID contains our app ID
            elseif ($app.Id -eq $AppId) {
                $match = $true
                $reason = "Teams App ID match"
            }
            
            if ($match) {
                $matchingApps += [PSCustomObject]@{
                    TeamsAppId = $app.Id
                    ExternalId = $app.ExternalId
                    DisplayName = $app.DisplayName
                    Version = $app.Version
                    DistributionMethod = $app.DistributionMethod
                    Reason = $reason
                    App = $app
                }
            }
        }
        
        if ($matchingApps.Count -gt 0) {
            Write-Host "`n   ✅ Found $($matchingApps.Count) matching app(s):" -ForegroundColor Green
            foreach ($match in $matchingApps) {
                Write-Host "   📱 App: $($match.DisplayName)" -ForegroundColor Cyan
                Write-Host "      Teams App ID: $($match.TeamsAppId)" -ForegroundColor White
                Write-Host "      External ID: $($match.ExternalId)" -ForegroundColor White
                Write-Host "      Version: $($match.Version)" -ForegroundColor White
                Write-Host "      Distribution: $($match.DistributionMethod)" -ForegroundColor White
                Write-Host "      Match Reason: $($match.Reason)" -ForegroundColor Gray
                Write-Host ""
            }
        } else {
            Write-Host "   ⚠️  No matching apps found" -ForegroundColor Yellow
        }
        
        return $matchingApps
    } catch {
        Write-Host "   ❌ Error searching Teams apps: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

# Function to get app details
function Get-AppDetails {
    param($AppObject)
    
    Write-Host "`n📋 App Details for: $($AppObject.DisplayName)" -ForegroundColor Green
    Write-Host "   Teams App ID: $($AppObject.TeamsAppId)" -ForegroundColor White
    Write-Host "   External ID: $($AppObject.ExternalId)" -ForegroundColor White
    Write-Host "   Version: $($AppObject.Version)" -ForegroundColor White
    Write-Host "   Distribution Method: $($AppObject.DistributionMethod)" -ForegroundColor White
    
    try {
        # Get detailed app information
        $appDetails = Get-MgTeamApp -TeamsAppId $AppObject.TeamsAppId
        
        if ($appDetails.AppDefinitions) {
            Write-Host "   📝 App Definitions: $($appDetails.AppDefinitions.Count)" -ForegroundColor White
            foreach ($def in $appDetails.AppDefinitions) {
                Write-Host "      - Version: $($def.Version)" -ForegroundColor Gray
                Write-Host "        State: $($def.PublishingState)" -ForegroundColor Gray
            }
        }
        
        return $appDetails
    } catch {
        Write-Host "   ⚠️  Could not get detailed app information: $($_.Exception.Message)" -ForegroundColor Yellow
        return $null
    }
}

# Function to update existing app
function Update-ExistingApp {
    param($AppObject, $PackagePath = ".\teams-app-package.zip")
    
    Write-Host "`n🔄 Updating Existing Teams App..." -ForegroundColor Green
    
    if (-not (Test-Path $PackagePath)) {
        Write-Host "   ❌ Package file not found: $PackagePath" -ForegroundColor Red
        return $false
    }
    
    try {
        Write-Host "   📦 Reading package: $PackagePath" -ForegroundColor Yellow
        $packageBytes = [System.IO.File]::ReadAllBytes((Resolve-Path $PackagePath))
        
        Write-Host "   🔄 Updating Teams app: $($AppObject.DisplayName)" -ForegroundColor Yellow
        
        # Update the existing app
        $updatedApp = Update-MgTeamApp -TeamsAppId $AppObject.TeamsAppId -ContentBytes $packageBytes
        
        if ($updatedApp) {
            Write-Host "   ✅ App updated successfully!" -ForegroundColor Green
            Write-Host "   📱 Updated App ID: $($updatedApp.Id)" -ForegroundColor White
            return $true
        }
    } catch {
        Write-Host "   ❌ Failed to update app: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    return $false
}

# Function to remove and re-upload app
function Remove-AndReuploadApp {
    param($AppObject, $PackagePath = ".\teams-app-package.zip")
    
    Write-Host "`n🗑️ Removing and Re-uploading Teams App..." -ForegroundColor Green
    
    try {
        Write-Host "   🗑️ Removing existing app: $($AppObject.DisplayName)" -ForegroundColor Yellow
        Remove-MgTeamApp -TeamsAppId $AppObject.TeamsAppId -Confirm:$false
        
        Write-Host "   ⏳ Waiting for removal to complete..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        
        Write-Host "   📦 Re-uploading app package..." -ForegroundColor Yellow
        $packageBytes = [System.IO.File]::ReadAllBytes((Resolve-Path $PackagePath))
        
        $newApp = New-MgTeamApp -DistributionMethod "organization" -ContentBytes $packageBytes
        
        if ($newApp) {
            Write-Host "   ✅ App re-uploaded successfully!" -ForegroundColor Green
            Write-Host "   📱 New App ID: $($newApp.Id)" -ForegroundColor White
            return $true
        }
    } catch {
        Write-Host "   ❌ Failed to remove/re-upload app: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    return $false
}

# Function to show management options
function Show-ManagementOptions {
    param($MatchingApps)
    
    if ($MatchingApps.Count -eq 0) {
        Write-Host "`n❌ No existing apps found to manage" -ForegroundColor Red
        return
    }
    
    Write-Host "`n🎯 Management Options" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $MatchingApps.Count; $i++) {
        $app = $MatchingApps[$i]
        Write-Host "`n[$($i + 1)] $($app.DisplayName)" -ForegroundColor Yellow
        Write-Host "    Teams App ID: $($app.TeamsAppId)" -ForegroundColor White
        Write-Host "    External ID: $($app.ExternalId)" -ForegroundColor White
        Write-Host "    Distribution: $($app.DistributionMethod)" -ForegroundColor White
    }
    
    Write-Host "`nWhat would you like to do?" -ForegroundColor Cyan
    Write-Host "[U] Update existing app with new package" -ForegroundColor White
    Write-Host "[R] Remove and re-upload app" -ForegroundColor White
    Write-Host "[D] Get detailed app information" -ForegroundColor White
    Write-Host "[Q] Quit" -ForegroundColor White
    
    $choice = Read-Host "`nEnter your choice (U/R/D/Q)"
    
    if ($choice.ToUpper() -eq "Q") {
        return
    }
    
    $appIndex = 0
    if ($MatchingApps.Count -gt 1) {
        $appNumber = Read-Host "Which app? (1-$($MatchingApps.Count))"
        $appIndex = [int]$appNumber - 1
        if ($appIndex -lt 0 -or $appIndex -ge $MatchingApps.Count) {
            Write-Host "Invalid selection" -ForegroundColor Red
            return
        }
    }
    
    $selectedApp = $MatchingApps[$appIndex]
    
    switch ($choice.ToUpper()) {
        "U" { 
            Update-ExistingApp -AppObject $selectedApp
        }
        "R" { 
            Remove-AndReuploadApp -AppObject $selectedApp
        }
        "D" { 
            Get-AppDetails -AppObject $selectedApp
        }
        default {
            Write-Host "Invalid choice" -ForegroundColor Red
        }
    }
}

# Main execution
function Main {
    # Connect to Microsoft Graph
    if (-not (Connect-ToGraph)) {
        Write-Host "`n❌ Cannot proceed without Graph connection" -ForegroundColor Red
        return
    }
    
    # Find existing Teams apps
    $existingApps = Find-ExistingTeamsApps
    
    if ($existingApps.Count -eq 0) {
        Write-Host "`n🤔 No existing apps found matching your criteria" -ForegroundColor Yellow
        Write-Host "   This suggests the app might be uploaded under a different name" -ForegroundColor White
        Write-Host "   Or it might be in a different state in the Teams Admin Center" -ForegroundColor White
        
        Write-Host "`n💡 Try these steps:" -ForegroundColor Cyan
        Write-Host "   1. Check Teams Admin Center → Manage apps" -ForegroundColor White
        Write-Host "   2. Search for 'Company Data Plugin' or 'M365 Copilot'" -ForegroundColor White
        Write-Host "   3. Look in 'Blocked apps' or 'Pending approval' sections" -ForegroundColor White
    } else {
        # Show management options
        Show-ManagementOptions -MatchingApps $existingApps
    }
    
    Write-Host "`n✅ Teams app management complete!" -ForegroundColor Green
}

# Execute main function
Main
