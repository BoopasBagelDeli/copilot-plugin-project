#!/usr/bin/env pwsh
<#
.SYNOPSIS
Test M365 Copilot Ecosystem Plugin Connections

.DESCRIPTION
Comprehensive testing script to validate all Microsoft ecosystem plugin connections
and provide sample queries for M365 Copilot testing.

.NOTES
Author: GitHub Copilot & M365 Copilot Integration
Date: July 22, 2025
#>

param(
    [switch]$WarmUpServices,
    [switch]$TestHealthEndpoints,
    [switch]$ShowSampleQueries
)

$Services = @{
    "EntraID" = @{
        Name = "EntraID Connector"
        Url = "https://func-entraid-copilot-app-zmkh7vbjhb6ca.azurewebsites.net"
        Icon = "🔐"
        Category = "Identity & Access Management"
    }
    "AzureMonitor" = @{
        Name = "Azure Monitor Connector"
        Url = "https://func-azuremon-copilot-app-zmkh7vbjhb6ca.azurewebsites.net"
        Icon = "📊"
        Category = "Monitoring & Analytics"
    }
    "AzureDevOps" = @{
        Name = "Azure DevOps Connector"
        Url = "https://func-azuredevops-copilot-app-zmkh7vbjhb6ca.azurewebsites.net"
        Icon = "🔧"
        Category = "DevOps & CI/CD"
    }
    "GitHub" = @{
        Name = "GitHub Connector"
        Url = "https://func-github-copilot-app-zmkh7vbjhb6ca.azurewebsites.net"
        Icon = "📋"
        Category = "Source Control"
    }
    "GitHubActions" = @{
        Name = "GitHub Actions Connector"
        Url = "https://func-ghactions-copilot-app-zmkh7vbjhb6ca.azurewebsites.net"
        Icon = "⚡"
        Category = "Automation & Workflows"
    }
    "AzureRepos" = @{
        Name = "Azure Repos Connector"
        Url = "https://func-azurerepos-copilot-app-zmkh7vbjhb6ca.azurewebsites.net"
        Icon = "📚"
        Category = "Azure Source Control"
    }
}

function Show-TestHeader {
    Write-Host "🚀 M365 Copilot Ecosystem Plugin Connection Testing" -ForegroundColor Magenta
    Write-Host "====================================================" -ForegroundColor Magenta
    Write-Host "Test Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host "Total Services: $($Services.Count)" -ForegroundColor Gray
    Write-Host ""
}

function Test-ServiceWarmup {
    Write-Host "🔥 Warming up Azure Function Apps..." -ForegroundColor Yellow
    Write-Host "This may take 30-60 seconds for cold start..." -ForegroundColor Gray
    Write-Host ""
    
    $jobs = @()
    
    foreach ($serviceKey in $Services.Keys) {
        $service = $Services[$serviceKey]
        Write-Host "   🌡️  Warming up $($service.Name)..." -ForegroundColor Cyan
        
        # Start background job to warm up service
        $job = Start-Job -ScriptBlock {
            param($url, $serviceName)
            try {
                $response = Invoke-RestMethod -Uri $url -Method GET -TimeoutSec 60
                return @{
                    Service = $serviceName
                    Status = "Warmed"
                    Response = $response
                    Success = $true
                }
            }
            catch {
                return @{
                    Service = $serviceName
                    Status = "Failed"
                    Error = $_.Exception.Message
                    Success = $false
                }
            }
        } -ArgumentList $service.Url, $service.Name
        
        $jobs += @{
            Job = $job
            ServiceKey = $serviceKey
        }
    }
    
    # Wait for all jobs to complete
    Write-Host "   ⏳ Waiting for all services to respond..." -ForegroundColor Yellow
    
    foreach ($jobInfo in $jobs) {
        $result = Receive-Job -Job $jobInfo.Job -Wait
        $service = $Services[$jobInfo.ServiceKey]
        
        if ($result.Success) {
            Write-Host "   ✅ $($service.Icon) $($result.Service): Ready" -ForegroundColor Green
        }
        else {
            Write-Host "   ❌ $($service.Icon) $($result.Service): $($result.Error)" -ForegroundColor Red
        }
        
        Remove-Job -Job $jobInfo.Job
    }
    
    Write-Host ""
}

function Test-HealthEndpoints {
    Write-Host "🏥 Testing Health Endpoints..." -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($serviceKey in $Services.Keys) {
        $service = $Services[$serviceKey]
        $healthUrl = "$($service.Url)/api/health"
        
        try {
            $response = Invoke-RestMethod -Uri $healthUrl -Method GET -TimeoutSec 30
            if ($response.status -eq "healthy") {
                Write-Host "   ✅ $($service.Icon) $($service.Name): Healthy" -ForegroundColor Green
            }
            else {
                Write-Host "   ⚠️  $($service.Icon) $($service.Name): $($response.status)" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "   ❌ $($service.Icon) $($service.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
}

function Show-SampleQueries {
    Write-Host "💬 Sample M365 Copilot Queries to Test Connections" -ForegroundColor Magenta
    Write-Host "==================================================" -ForegroundColor Magenta
    Write-Host ""
    
    Write-Host "🔐 EntraID Connector - Identity & Access Management:" -ForegroundColor Cyan
    Write-Host "   • ""Show me all users who haven't signed in for 30 days""" -ForegroundColor White
    Write-Host "   • ""What roles does john.smith@company.com have assigned?""" -ForegroundColor White
    Write-Host "   • ""List all groups with external members""" -ForegroundColor White
    Write-Host "   • ""Give me a security summary of risky sign-ins this week""" -ForegroundColor White
    Write-Host "   • ""Who are the global administrators in our tenant?""" -ForegroundColor White
    Write-Host ""
    
    Write-Host "📊 Azure Monitor Connector - Monitoring & Analytics:" -ForegroundColor Cyan
    Write-Host "   • ""What alerts are currently active in production?""" -ForegroundColor White
    Write-Host "   • ""Show me CPU performance for our web servers today""" -ForegroundColor White
    Write-Host "   • ""Give me a summary of application errors from yesterday""" -ForegroundColor White
    Write-Host "   • ""Which Azure resources are consuming the most memory?""" -ForegroundColor White
    Write-Host "   • ""Show me performance metrics for our Function Apps""" -ForegroundColor White
    Write-Host ""
    
    Write-Host "🔧 Azure DevOps Connector - DevOps & CI/CD:" -ForegroundColor Cyan
    Write-Host "   • ""What work items are assigned to me this sprint?""" -ForegroundColor White
    Write-Host "   • ""Show me the status of our latest deployment pipeline""" -ForegroundColor White
    Write-Host "   • ""Which builds failed in the last week?""" -ForegroundColor White
    Write-Host "   • ""Give me our current sprint progress summary""" -ForegroundColor White
    Write-Host "   • ""What pull requests need my review?""" -ForegroundColor White
    Write-Host ""
    
    Write-Host "📋 GitHub Connector - Source Control:" -ForegroundColor Cyan
    Write-Host "   • ""Show me open pull requests in our main repositories""" -ForegroundColor White
    Write-Host "   • ""What issues were created this week across our repos?""" -ForegroundColor White
    Write-Host "   • ""Who are the top contributors to our copilot project?""" -ForegroundColor White
    Write-Host "   • ""List recent commits to the main branch""" -ForegroundColor White
    Write-Host "   • ""Show me repositories with the most activity""" -ForegroundColor White
    Write-Host ""
    
    Write-Host "⚡ GitHub Actions Connector - Automation & Workflows:" -ForegroundColor Cyan
    Write-Host "   • ""Show me the status of all deployment workflows""" -ForegroundColor White
    Write-Host "   • ""Which GitHub Actions ran successfully last night?""" -ForegroundColor White
    Write-Host "   • ""Give me our CI/CD pipeline health summary""" -ForegroundColor White
    Write-Host "   • ""What workflows are currently running?""" -ForegroundColor White
    Write-Host "   • ""Show me failed job runs from the past week""" -ForegroundColor White
    Write-Host ""
    
    Write-Host "📚 Azure Repos Connector - Azure Source Control:" -ForegroundColor Cyan
    Write-Host "   • ""Show me recent commits to our Azure DevOps repos""" -ForegroundColor White
    Write-Host "   • ""What pull requests need approval in Azure Repos?""" -ForegroundColor White
    Write-Host "   • ""Give me repository activity summary""" -ForegroundColor White
    Write-Host "   • ""Show me code changes from the last deployment""" -ForegroundColor White
    Write-Host "   • ""Which team members are most active in our repos?""" -ForegroundColor White
    Write-Host ""
    
    Write-Host "🎯 Cross-Service Queries (Advanced):" -ForegroundColor Magenta
    Write-Host "   • ""Show me DevOps activity for users with risky sign-ins""" -ForegroundColor White
    Write-Host "   • ""What's the performance impact of our latest GitHub deployment?""" -ForegroundColor White
    Write-Host "   • ""Give me a security and compliance dashboard for our development team""" -ForegroundColor White
    Write-Host "   • ""Show me the correlation between code commits and system alerts""" -ForegroundColor White
    Write-Host ""
}

function Show-NextSteps {
    Write-Host "📋 Next Steps to Complete M365 Copilot Integration:" -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "1. 🔑 Configure Service Credentials:" -ForegroundColor Cyan
    Write-Host "   • Add GitHub API tokens to Azure Key Vault" -ForegroundColor White
    Write-Host "   • Configure Azure DevOps PATs" -ForegroundColor White
    Write-Host "   • Set up Microsoft Graph permissions" -ForegroundColor White
    Write-Host ""
    
    Write-Host "2. 🔌 Deploy Power Platform Connectors:" -ForegroundColor Cyan
    Write-Host "   • Run deployment scripts in each plugin module" -ForegroundColor White
    Write-Host "   • Test connector authentication" -ForegroundColor White
    Write-Host "   • Create sample Power Automate flows" -ForegroundColor White
    Write-Host ""
    
    Write-Host "3. 🤖 M365 Copilot Integration:" -ForegroundColor Cyan
    Write-Host "   • Enable plugins in M365 Copilot Studio" -ForegroundColor White
    Write-Host "   • Configure natural language processing" -ForegroundColor White
    Write-Host "   • Test conversational queries" -ForegroundColor White
    Write-Host ""
    
    Write-Host "4. 🧪 End-to-End Testing:" -ForegroundColor Cyan
    Write-Host "   • Test each sample query above" -ForegroundColor White
    Write-Host "   • Validate cross-service correlations" -ForegroundColor White
    Write-Host "   • Monitor performance and reliability" -ForegroundColor White
    Write-Host ""
}

# Main execution
Show-TestHeader

if ($WarmUpServices -or $PSCmdlet.ParameterSetName -eq '__AllParameterSets') {
    Test-ServiceWarmup
}

if ($TestHealthEndpoints -or $PSCmdlet.ParameterSetName -eq '__AllParameterSets') {
    Test-HealthEndpoints
}

if ($ShowSampleQueries -or $PSCmdlet.ParameterSetName -eq '__AllParameterSets') {
    Show-SampleQueries
}

Show-NextSteps

Write-Host "🎉 M365 Copilot Ecosystem Testing Complete!" -ForegroundColor Green
Write-Host "Your Microsoft ecosystem plugins are ready for conversational AI!" -ForegroundColor Green
