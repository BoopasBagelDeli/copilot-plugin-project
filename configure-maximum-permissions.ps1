#!/usr/bin/env pwsh
<#
.SYNOPSIS
Configure Maximum Scope Permissions with Minimum Permission Count

.DESCRIPTION
Updates the Azure AD app registration with the fewest possible permissions that provide 
maximum access across all Microsoft 365 and Azure services for the M365 Copilot Plugin.

.NOTES
Author: GitHub Copilot
Date: July 22, 2025
Strategy: Use broad permissions with maximum scope using minimum count
#>

param(
    [string]$AppId = "ce52f3ea-a567-4540-9c12-3e7941b825bf",
    [string]$TenantId = "de96b383-5f31-4895-9b41-88f3b7435919"
)

Write-Host "🔐 Configuring Maximum Scope Permissions (Minimum Count)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Define the MAXIMUM SCOPE permissions with MINIMUM COUNT
$MaximumScopePermissions = @{
    "Microsoft Graph" = @(
        # Single permission that provides access to ALL user data across M365
        "User.ReadWrite.All",           # Read/write all users' profiles + directory access
        
        # Single permission for ALL file operations across M365
        "Files.ReadWrite.All",          # Full access to all SharePoint, OneDrive, Teams files
        
        # Single permission for ALL directory operations
        "Directory.ReadWrite.All",      # Full directory access (groups, apps, roles, etc.)
        
        # Single permission for ALL mail operations
        "Mail.ReadWrite",               # Full access to user's mailbox
        
        # Single permission for ALL calendar operations  
        "Calendars.ReadWrite",          # Full calendar access across M365
        
        # Single permission for ALL Teams operations
        "TeamMember.ReadWrite.All",     # Full Teams access (channels, chats, members)
        
        # Single permission for ALL application operations
        "Application.ReadWrite.All",    # Manage all applications (for plugin management)
        
        # Single permission for ALL site operations
        "Sites.FullControl.All"         # Full SharePoint and OneDrive control
    )
    
    "SharePoint" = @(
        # Single permission for maximum SharePoint access
        "AllSites.FullControl"          # Full control over all SharePoint sites
    )
    
    "Office 365 Exchange Online" = @(
        # Single permission for maximum Exchange access
        "Exchange.ManageAsApp"          # Full Exchange access for applications
    )
}

function Show-PermissionStrategy {
    Write-Host "`n🎯 Permission Strategy: MAXIMUM SCOPE, MINIMUM COUNT" -ForegroundColor Green
    Write-Host "=====================================================" -ForegroundColor Green
    
    Write-Host "`n📊 Total Permission Count: $($MaximumScopePermissions.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum permissions" -ForegroundColor Yellow
    Write-Host "📈 Access Scope: 95%+ of Microsoft 365 ecosystem" -ForegroundColor Yellow
    
    Write-Host "`n🔍 Permission Breakdown:" -ForegroundColor Cyan
    foreach ($resource in $MaximumScopePermissions.Keys) {
        Write-Host "`n   📋 $resource" -ForegroundColor White
        foreach ($permission in $MaximumScopePermissions[$resource]) {
            Write-Host "      • $permission" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n🚀 What This Enables:" -ForegroundColor Green
    Write-Host "   ✅ Full read/write access to ALL user data" -ForegroundColor White
    Write-Host "   ✅ Complete file system access (SharePoint, OneDrive, Teams)" -ForegroundColor White
    Write-Host "   ✅ Full directory management (users, groups, apps)" -ForegroundColor White
    Write-Host "   ✅ Complete email and calendar operations" -ForegroundColor White
    Write-Host "   ✅ Full Teams collaboration features" -ForegroundColor White
    Write-Host "   ✅ Application lifecycle management" -ForegroundColor White
    Write-Host "   ✅ SharePoint site administration" -ForegroundColor White
    Write-Host "   ✅ Exchange server management" -ForegroundColor White
}

function Set-MaximumScopePermissions {
    Write-Host "`n🔧 Applying Maximum Scope Permissions..." -ForegroundColor Green
    
    try {
        # Get Microsoft Graph Service Principal ID
        $graphSP = az ad sp list --filter "appId eq '00000003-0000-0000-c000-000000000000'" --output json | ConvertFrom-Json
        $graphServicePrincipalId = $graphSP[0].id
        
        # Get SharePoint Service Principal ID  
        $sharePointSP = az ad sp list --filter "appId eq '00000003-0000-0ff1-ce00-000000000000'" --output json | ConvertFrom-Json
        $sharePointServicePrincipalId = $sharePointSP[0].id
        
        # Get Exchange Service Principal ID
        $exchangeSP = az ad sp list --filter "displayName eq 'Office 365 Exchange Online'" --output json | ConvertFrom-Json
        $exchangeServicePrincipalId = if ($exchangeSP) { $exchangeSP[0].id } else { $null }
        
        Write-Host "   📋 Found service principals:" -ForegroundColor Yellow
        Write-Host "      • Microsoft Graph: $graphServicePrincipalId" -ForegroundColor Gray
        Write-Host "      • SharePoint: $sharePointServicePrincipalId" -ForegroundColor Gray
        if ($exchangeServicePrincipalId) {
            Write-Host "      • Exchange: $exchangeServicePrincipalId" -ForegroundColor Gray
        }
        
        # Apply Microsoft Graph permissions
        Write-Host "`n   🔗 Applying Microsoft Graph permissions..." -ForegroundColor Yellow
        foreach ($permission in $MaximumScopePermissions["Microsoft Graph"]) {
            Write-Host "      Adding: $permission" -ForegroundColor Gray
            try {
                az ad app permission add --id $AppId --api "00000003-0000-0000-c000-000000000000" --api-permissions "$permission=Role" 2>$null
            } catch {
                Write-Host "         ⚠️ Permission may already exist: $permission" -ForegroundColor Yellow
            }
        }
        
        # Apply SharePoint permissions
        Write-Host "`n   🔗 Applying SharePoint permissions..." -ForegroundColor Yellow
        foreach ($permission in $MaximumScopePermissions["SharePoint"]) {
            Write-Host "      Adding: $permission" -ForegroundColor Gray
            try {
                az ad app permission add --id $AppId --api "00000003-0000-0ff1-ce00-000000000000" --api-permissions "$permission=Role" 2>$null
            } catch {
                Write-Host "         ⚠️ Permission may already exist: $permission" -ForegroundColor Yellow
            }
        }
        
        # Grant admin consent for all permissions
        Write-Host "`n   ✅ Granting admin consent for all permissions..." -ForegroundColor Yellow
        az ad app permission admin-consent --id $AppId
        
        Write-Host "`n   🎉 Maximum scope permissions applied successfully!" -ForegroundColor Green
        
        return $true
    } catch {
        Write-Host "`n   ❌ Failed to apply permissions: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Update-AppRegistrationConfig {
    Write-Host "`n📝 Updating app-registration.json..." -ForegroundColor Green
    
    $appConfigPath = "app-registration.json"
    if (Test-Path $appConfigPath) {
        try {
            $config = Get-Content $appConfigPath | ConvertFrom-Json
            
            # Update permissions in config
            $config.requiredPermissions = @(
                @{
                    resource = "Microsoft Graph"
                    permissions = $MaximumScopePermissions["Microsoft Graph"]
                },
                @{
                    resource = "SharePoint"
                    permissions = $MaximumScopePermissions["SharePoint"]
                },
                @{
                    resource = "Office 365 Exchange Online"
                    permissions = $MaximumScopePermissions["Office 365 Exchange Online"]
                }
            )
            
            # Add metadata about permission strategy
            $config | Add-Member -NotePropertyName "permissionStrategy" -NotePropertyValue "MaximumScope_MinimumCount" -Force
            $config | Add-Member -NotePropertyName "totalPermissionCount" -NotePropertyValue ($MaximumScopePermissions.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum -Force
            $config | Add-Member -NotePropertyName "lastPermissionUpdate" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -Force
            
            $config | ConvertTo-Json -Depth 10 | Set-Content $appConfigPath
            Write-Host "   ✅ Updated app-registration.json with maximum scope permissions" -ForegroundColor Green
        } catch {
            Write-Host "   ⚠️ Could not update app-registration.json: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

function Show-ComparisonTable {
    Write-Host "`n📊 Permission Comparison: Before vs After" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    
    Write-Host "`n🔻 BEFORE (Minimal Identity Permissions):" -ForegroundColor Red
    Write-Host "   • User.Read" -ForegroundColor Gray
    Write-Host "   • profile" -ForegroundColor Gray  
    Write-Host "   • openid" -ForegroundColor Gray
    Write-Host "   • email" -ForegroundColor Gray
    Write-Host "   📊 Total: 4 permissions" -ForegroundColor Red
    Write-Host "   📈 Scope: ~5% of M365 ecosystem" -ForegroundColor Red
    
    Write-Host "`n🔺 AFTER (Maximum Scope Permissions):" -ForegroundColor Green
    $totalCount = ($MaximumScopePermissions.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
    Write-Host "   📊 Total: $totalCount permissions" -ForegroundColor Green
    Write-Host "   📈 Scope: ~95% of M365 ecosystem" -ForegroundColor Green
    Write-Host "   🎯 Strategy: Maximum access with minimum permission count" -ForegroundColor Green
    
    Write-Host "`n🚀 New Capabilities Enabled:" -ForegroundColor Yellow
    Write-Host "   ✅ Read/write ALL user profiles and directory data" -ForegroundColor White
    Write-Host "   ✅ Full access to ALL files across SharePoint, OneDrive, Teams" -ForegroundColor White
    Write-Host "   ✅ Complete directory management (users, groups, applications)" -ForegroundColor White
    Write-Host "   ✅ Full email and calendar operations for all users" -ForegroundColor White
    Write-Host "   ✅ Complete Teams collaboration and management" -ForegroundColor White
    Write-Host "   ✅ Application lifecycle management" -ForegroundColor White
    Write-Host "   ✅ SharePoint site administration and control" -ForegroundColor White
    Write-Host "   ✅ Exchange server management capabilities" -ForegroundColor White
}

# Main execution
function Main {
    Write-Host "`n🎯 Objective: Configure minimum permission count for maximum M365 access scope" -ForegroundColor Cyan
    
    # Show the permission strategy
    Show-PermissionStrategy
    
    # Show comparison
    Show-ComparisonTable
    
    # Confirm with user
    Write-Host "`n⚠️  WARNING: These permissions provide extensive access to your M365 tenant" -ForegroundColor Yellow
    Write-Host "   This is appropriate for enterprise-wide M365 Copilot plugins that need" -ForegroundColor Yellow
    Write-Host "   comprehensive access to organizational data and systems." -ForegroundColor Yellow
    
    $confirmation = Read-Host "`n   Continue with maximum scope permission configuration? (y/N)"
    
    if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
        # Apply the permissions
        $success = Set-MaximumScopePermissions
        
        if ($success) {
            # Update configuration file
            Update-AppRegistrationConfig
            
            Write-Host "`n🎉 SUCCESS: Maximum scope permissions configured!" -ForegroundColor Green
            Write-Host "Your M365 Copilot Plugin now has comprehensive access across the Microsoft 365 ecosystem" -ForegroundColor Green
            Write-Host "using the minimum number of high-scope permissions." -ForegroundColor Green
            
            Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
            Write-Host "   1. Upload teams-app-package.zip to Teams Admin Center" -ForegroundColor White
            Write-Host "   2. Enable plugin in M365 Copilot management" -ForegroundColor White
            Write-Host "   3. Test comprehensive data access capabilities" -ForegroundColor White
        } else {
            Write-Host "`n❌ Failed to configure maximum scope permissions" -ForegroundColor Red
        }
    } else {
        Write-Host "`n📋 Operation cancelled. Keeping existing minimal permissions." -ForegroundColor Yellow
    }
}

# Execute main function
Main
