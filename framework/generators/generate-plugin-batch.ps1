#!/usr/bin/env pwsh
<#
.SYNOPSIS
Batch Plugin Generator for M365 Copilot Ecosystem

.DESCRIPTION
Generates multiple plugin modules simultaneously for rapid development.
Creates 5+ plugins in under 2 hours with shared infrastructure.

.PARAMETER ConfigFile
JSON configuration file containing plugin definitions

.PARAMETER Parallel
Execute plugin generation in parallel

.PARAMETER Deploy
Automatically deploy all plugins after generation

.EXAMPLE
.\generate-plugin-batch.ps1 -ConfigFile "plugin-roadmap.json" -Parallel -Deploy

.NOTES
Author: GitHub Copilot
Date: July 22, 2025
#>

param(
    [Parameter(Mandatory)]
    [string]$ConfigFile,
    
    [switch]$Parallel,
    
    [switch]$Deploy,
    
    [string]$OutputPath = ".",
    
    [switch]$GenerateTests
)

# Function to validate configuration file
function Test-ConfigurationFile {
    param($ConfigPath)
    
    Write-Host "📋 Validating configuration file..." -ForegroundColor Green
    
    if (-not (Test-Path $ConfigPath)) {
        Write-Host "   ❌ Configuration file not found: $ConfigPath" -ForegroundColor Red
        return $false
    }
    
    try {
        $config = Get-Content $ConfigPath | ConvertFrom-Json
        
        # Validate required properties
        if (-not $config.plugins) {
            Write-Host "   ❌ Configuration missing 'plugins' array" -ForegroundColor Red
            return $false
        }
        
        foreach ($plugin in $config.plugins) {
            if (-not $plugin.name -or -not $plugin.type) {
                Write-Host "   ❌ Plugin missing required 'name' or 'type' property" -ForegroundColor Red
                return $false
            }
        }
        
        Write-Host "   ✅ Configuration file validated" -ForegroundColor Green
        Write-Host "   📊 Found $($config.plugins.Count) plugin(s) to generate" -ForegroundColor White
        
        return $true
        
    } catch {
        Write-Host "   ❌ Invalid JSON format: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to show batch generation plan
function Show-GenerationPlan {
    param($Config)
    
    Write-Host "`n🎯 Batch Generation Plan" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    
    $totalPlugins = $Config.plugins.Count
    $estimatedTime = if ($Parallel) { "1.5-2 hours" } else { "$($totalPlugins * 0.5)-$($totalPlugins * 0.75) hours" }
    
    Write-Host "`n📊 Overview:" -ForegroundColor Yellow
    Write-Host "   🔢 Total Plugins: $totalPlugins" -ForegroundColor White
    Write-Host "   ⚡ Execution Mode: $(if ($Parallel) { 'Parallel' } else { 'Sequential' })" -ForegroundColor White
    Write-Host "   ⏱️ Estimated Time: $estimatedTime" -ForegroundColor White
    Write-Host "   🚀 Auto Deploy: $(if ($Deploy) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "   🧪 Generate Tests: $(if ($GenerateTests) { 'Yes' } else { 'No' })" -ForegroundColor White
    
    Write-Host "`n📋 Plugin Details:" -ForegroundColor Yellow
    
    $priorityGroups = $Config.plugins | Group-Object -Property { if ($_.priority) { $_.priority } else { 999 } } | Sort-Object Name
    
    foreach ($group in $priorityGroups) {
        $priority = if ($group.Name -eq "999") { "Default" } else { "Priority $($group.Name)" }
        Write-Host "`n   🎯 $priority:" -ForegroundColor Green
        
        foreach ($plugin in $group.Group) {
            $icon = switch ($plugin.type) {
                "CRM" { "🤝" }
                "ProjectManagement" { "📋" }
                "KnowledgeBase" { "🔍" }
                "BusinessIntelligence" { "📊" }
                "Communication" { "💬" }
                default { "⚙️" }
            }
            
            Write-Host "      $icon $($plugin.name) ($($plugin.type))" -ForegroundColor White
            if ($plugin.description) {
                Write-Host "         📝 $($plugin.description)" -ForegroundColor Gray
            }
        }
    }
}

# Function to generate single plugin
function New-SinglePlugin {
    param($PluginConfig, $OutputPath)
    
    $pluginName = $PluginConfig.name
    $pluginType = $PluginConfig.type
    $description = if ($PluginConfig.description) { $PluginConfig.description } else { "$pluginType integration for M365 Copilot" }
    $endpoints = if ($PluginConfig.endpoints) { $PluginConfig.endpoints } else { @() }
    
    Write-Host "`n🔧 Generating $pluginName ($pluginType)..." -ForegroundColor Green
    
    try {
        # Build generation command
        $generateCmd = @(
            ".\generate-plugin-module.ps1"
            "-PluginType", $pluginType
            "-PluginName", $pluginName
            "-Description", $description
            "-OutputPath", $OutputPath
        )
        
        if ($endpoints.Count -gt 0) {
            $generateCmd += "-Endpoints", ($endpoints -join ",")
        }
        
        if ($GenerateTests) {
            $generateCmd += "-GenerateTests"
        }
        
        # Execute generation
        $result = & $generateCmd[0] @($generateCmd[1..($generateCmd.Length-1)])
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ $pluginName generated successfully" -ForegroundColor Green
            return @{
                Success = $true
                PluginName = $pluginName
                Type = $pluginType
                ModulePath = Join-Path $OutputPath "$pluginName-module"
            }
        } else {
            Write-Host "   ❌ $pluginName generation failed" -ForegroundColor Red
            return @{
                Success = $false
                PluginName = $pluginName
                Type = $pluginType
                Error = "Generation command failed with exit code $LASTEXITCODE"
            }
        }
        
    } catch {
        Write-Host "   ❌ $pluginName generation error: $($_.Exception.Message)" -ForegroundColor Red
        return @{
            Success = $false
            PluginName = $pluginName
            Type = $pluginType
            Error = $_.Exception.Message
        }
    }
}

# Function to generate plugins in parallel
function New-PluginsParallel {
    param($Plugins, $OutputPath)
    
    Write-Host "`n⚡ Starting parallel plugin generation..." -ForegroundColor Cyan
    
    $jobs = @()
    
    foreach ($plugin in $Plugins) {
        $scriptBlock = {
            param($PluginConfig, $OutputPath, $GenerateTests)
            
            # Import the generation function (simplified for parallel execution)
            $pluginName = $PluginConfig.name
            $pluginType = $PluginConfig.type
            $description = if ($PluginConfig.description) { $PluginConfig.description } else { "$pluginType integration for M365 Copilot" }
            
            try {
                # Execute plugin generation
                $generateArgs = @{
                    PluginType = $pluginType
                    PluginName = $pluginName
                    Description = $description
                    OutputPath = $OutputPath
                }
                
                if ($PluginConfig.endpoints) {
                    $generateArgs.Endpoints = $PluginConfig.endpoints
                }
                
                if ($GenerateTests) {
                    $generateArgs.GenerateTests = $true
                }
                
                # Call generation script
                $result = & ".\generate-plugin-module.ps1" @generateArgs
                
                return @{
                    Success = $true
                    PluginName = $pluginName
                    Type = $pluginType
                    ModulePath = Join-Path $OutputPath "$pluginName-module"
                }
                
            } catch {
                return @{
                    Success = $false
                    PluginName = $pluginName
                    Type = $pluginType
                    Error = $_.Exception.Message
                }
            }
        }
        
        $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $plugin, $OutputPath, $GenerateTests
        $jobs += @{
            Job = $job
            PluginName = $plugin.name
            Type = $plugin.type
        }
        
        Write-Host "   🚀 Started job for $($plugin.name)" -ForegroundColor Green
    }
    
    # Wait for all jobs and collect results
    $results = @()
    $completedCount = 0
    $totalJobs = $jobs.Count
    
    Write-Host "`n⏳ Waiting for $totalJobs parallel jobs to complete..." -ForegroundColor Yellow
    
    while ($completedCount -lt $totalJobs) {
        Start-Sleep -Seconds 2
        
        foreach ($jobInfo in $jobs) {
            if ($jobInfo.Job.State -eq "Completed" -and -not $jobInfo.Processed) {
                $result = Receive-Job -Job $jobInfo.Job
                Remove-Job -Job $jobInfo.Job
                
                $jobInfo.Processed = $true
                $completedCount++
                
                if ($result.Success) {
                    Write-Host "   ✅ $($jobInfo.PluginName) completed ($completedCount/$totalJobs)" -ForegroundColor Green
                } else {
                    Write-Host "   ❌ $($jobInfo.PluginName) failed ($completedCount/$totalJobs)" -ForegroundColor Red
                }
                
                $results += $result
            } elseif ($jobInfo.Job.State -eq "Failed" -and -not $jobInfo.Processed) {
                $error = Receive-Job -Job $jobInfo.Job
                Remove-Job -Job $jobInfo.Job
                
                $jobInfo.Processed = $true
                $completedCount++
                
                Write-Host "   ❌ $($jobInfo.PluginName) job failed ($completedCount/$totalJobs)" -ForegroundColor Red
                
                $results += @{
                    Success = $false
                    PluginName = $jobInfo.PluginName
                    Type = $jobInfo.Type
                    Error = "Job execution failed"
                }
            }
        }
        
        # Show progress
        $progress = [math]::Round(($completedCount / $totalJobs) * 100, 1)
        Write-Progress -Activity "Parallel Plugin Generation" -Status "$completedCount of $totalJobs completed" -PercentComplete $progress
    }
    
    Write-Progress -Activity "Parallel Plugin Generation" -Completed
    
    return $results
}

# Function to generate plugins sequentially
function New-PluginsSequential {
    param($Plugins, $OutputPath)
    
    Write-Host "`n📝 Starting sequential plugin generation..." -ForegroundColor Cyan
    
    $results = @()
    $currentIndex = 0
    $totalPlugins = $Plugins.Count
    
    foreach ($plugin in $Plugins) {
        $currentIndex++
        Write-Host "`n📋 Processing plugin $currentIndex of $totalPlugins..." -ForegroundColor Yellow
        
        $result = New-SinglePlugin -PluginConfig $plugin -OutputPath $OutputPath
        $results += $result
        
        # Show progress
        $progress = [math]::Round(($currentIndex / $totalPlugins) * 100, 1)
        Write-Progress -Activity "Sequential Plugin Generation" -Status "$currentIndex of $totalPlugins completed" -PercentComplete $progress
    }
    
    Write-Progress -Activity "Sequential Plugin Generation" -Completed
    
    return $results
}

# Function to deploy generated plugins
function Deploy-GeneratedPlugins {
    param($Results)
    
    Write-Host "`n🚀 Deploying generated plugins..." -ForegroundColor Cyan
    
    $successfulPlugins = $Results | Where-Object { $_.Success }
    
    if ($successfulPlugins.Count -eq 0) {
        Write-Host "   ⚠️  No successful plugins to deploy" -ForegroundColor Yellow
        return
    }
    
    Write-Host "   📊 Deploying $($successfulPlugins.Count) plugin(s)..." -ForegroundColor Green
    
    foreach ($plugin in $successfulPlugins) {
        Write-Host "`n   🔌 Deploying $($plugin.PluginName)..." -ForegroundColor Green
        
        try {
            $originalLocation = Get-Location
            Set-Location $plugin.ModulePath
            
            $deployScript = ".\deploy-$($plugin.PluginName.ToLower()).ps1"
            if (Test-Path $deployScript) {
                & $deployScript -UseSecureConnector
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "   ✅ $($plugin.PluginName) deployed successfully" -ForegroundColor Green
                } else {
                    Write-Host "   ❌ $($plugin.PluginName) deployment failed" -ForegroundColor Red
                }
            } else {
                Write-Host "   ⚠️  Deployment script not found for $($plugin.PluginName)" -ForegroundColor Yellow
            }
            
        } catch {
            Write-Host "   ❌ $($plugin.PluginName) deployment error: $($_.Exception.Message)" -ForegroundColor Red
        } finally {
            Set-Location $originalLocation
        }
    }
}

# Function to show generation summary
function Show-GenerationSummary {
    param($Results, $StartTime)
    
    $endTime = Get-Date
    $totalTime = $endTime - $StartTime
    
    Write-Host "`n📊 Batch Generation Summary" -ForegroundColor Cyan
    Write-Host "===========================" -ForegroundColor Cyan
    
    $successful = $Results | Where-Object { $_.Success }
    $failed = $Results | Where-Object { -not $_.Success }
    
    Write-Host "`n📈 Results:" -ForegroundColor Yellow
    Write-Host "   ✅ Successful: $($successful.Count)" -ForegroundColor Green
    Write-Host "   ❌ Failed: $($failed.Count)" -ForegroundColor Red
    Write-Host "   📊 Total: $($Results.Count)" -ForegroundColor White
    Write-Host "   ⏱️ Total Time: $($totalTime.ToString('hh\:mm\:ss'))" -ForegroundColor White
    
    if ($successful.Count -gt 0) {
        Write-Host "`n✅ Successfully Generated Plugins:" -ForegroundColor Green
        foreach ($plugin in $successful) {
            $icon = switch ($plugin.Type) {
                "CRM" { "🤝" }
                "ProjectManagement" { "📋" }
                "KnowledgeBase" { "🔍" }
                "BusinessIntelligence" { "📊" }
                "Communication" { "💬" }
                default { "⚙️" }
            }
            Write-Host "   $icon $($plugin.PluginName) ($($plugin.Type))" -ForegroundColor White
            Write-Host "      📁 $($plugin.ModulePath)" -ForegroundColor Gray
        }
    }
    
    if ($failed.Count -gt 0) {
        Write-Host "`n❌ Failed Plugins:" -ForegroundColor Red
        foreach ($plugin in $failed) {
            Write-Host "   ❌ $($plugin.PluginName) ($($plugin.Type))" -ForegroundColor White
            Write-Host "      💥 Error: $($plugin.Error)" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n🎯 Next Steps:" -ForegroundColor Yellow
    Write-Host "   1. 📝 Review generated plugin modules" -ForegroundColor White
    Write-Host "   2. 🔧 Customize business logic as needed" -ForegroundColor White
    Write-Host "   3. 🧪 Test individual plugins" -ForegroundColor White
    if (-not $Deploy) {
        Write-Host "   4. 🚀 Deploy plugins to Power Platform" -ForegroundColor White
    }
    Write-Host "   5. 🎨 Build Power Automate flows and Power Apps" -ForegroundColor White
    Write-Host "   6. 🤖 Test M365 Copilot integration" -ForegroundColor White
    
    # Calculate efficiency gains
    $manualTime = $Results.Count * 4 # 4 hours per plugin manually
    $actualTime = $totalTime.TotalHours
    $efficiency = [math]::Round((($manualTime - $actualTime) / $manualTime) * 100, 1)
    
    Write-Host "`n⚡ Efficiency Gains:" -ForegroundColor Yellow
    Write-Host "   🕒 Manual Development: ~$manualTime hours" -ForegroundColor White
    Write-Host "   ⚡ Automated Generation: $([math]::Round($actualTime, 1)) hours" -ForegroundColor White
    Write-Host "   📈 Time Saved: $efficiency%" -ForegroundColor Green
    
    Write-Host "`n🎉 Batch plugin generation complete!" -ForegroundColor Green
}

# Main execution function
function Main {
    $startTime = Get-Date
    
    Write-Host "🚀 M365 Copilot Plugin Batch Generator" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    
    # Validate configuration file
    if (-not (Test-ConfigurationFile -ConfigPath $ConfigFile)) {
        Write-Host "`n❌ Configuration validation failed. Aborting." -ForegroundColor Red
        return
    }
    
    # Load configuration
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    
    # Show generation plan
    Show-GenerationPlan -Config $config
    
    # Confirm execution
    $confirmation = Read-Host "`n🤔 Proceed with batch generation? (y/N)"
    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-Host "`n⏹️  Batch generation cancelled by user." -ForegroundColor Yellow
        return
    }
    
    # Sort plugins by priority if specified
    $sortedPlugins = if ($config.plugins | Where-Object { $_.priority }) {
        $config.plugins | Sort-Object -Property priority
    } else {
        $config.plugins
    }
    
    # Generate plugins
    $results = if ($Parallel) {
        New-PluginsParallel -Plugins $sortedPlugins -OutputPath $OutputPath
    } else {
        New-PluginsSequential -Plugins $sortedPlugins -OutputPath $OutputPath
    }
    
    # Deploy if requested
    if ($Deploy) {
        Deploy-GeneratedPlugins -Results $results
    }
    
    # Show summary
    Show-GenerationSummary -Results $results -StartTime $startTime
}

# Execute main function
Main
