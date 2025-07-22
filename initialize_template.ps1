# M365 Copilot Plugin Template Initializer
# PowerShell script to customize the template for new plugin projects

param(
    [string]$PluginName = "",
    [string]$Description = "",
    [string]$ContactEmail = "",
    [string]$CompanyDomain = "",
    [string]$ProjectPrefix = "",
    [switch]$Interactive = $true
)

function Get-UserInput {
    param(
        [string]$Prompt,
        [string]$Default = ""
    )
    
    if ($Default) {
        $input = Read-Host "$Prompt [$Default]"
        return if ($input) { $input } else { $Default }
    } else {
        return Read-Host $Prompt
    }
}

function Update-JsonFile {
    param(
        [string]$FilePath,
        [hashtable]$Updates
    )
    
    try {
        $content = Get-Content $FilePath -Raw | ConvertFrom-Json
        
        foreach ($key in $Updates.Keys) {
            if ($key -contains '.') {
                # Handle nested properties
                $keys = $key -split '\.'
                $current = $content
                for ($i = 0; $i -lt $keys.Count - 1; $i++) {
                    $current = $current.($keys[$i])
                }
                $current.($keys[-1]) = $Updates[$key]
            } else {
                $content.$key = $Updates[$key]
            }
        }
        
        $content | ConvertTo-Json -Depth 10 | Set-Content $FilePath -Encoding UTF8
        Write-Host "✅ Updated $FilePath" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error updating $FilePath`: $_" -ForegroundColor Red
    }
}

function Update-TextFile {
    param(
        [string]$FilePath,
        [hashtable]$Replacements
    )
    
    try {
        $content = Get-Content $FilePath -Raw
        
        foreach ($key in $Replacements.Keys) {
            $content = $content -replace [regex]::Escape($key), $Replacements[$key]
        }
        
        Set-Content $FilePath $content -Encoding UTF8
        Write-Host "✅ Updated $FilePath" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error updating $FilePath`: $_" -ForegroundColor Red
    }
}

function Test-TemplateFiles {
    $requiredFiles = @(
        'plugins\plugin_manifest.json',
        'plugins\openapi.yaml', 
        'azure.yaml',
        'src\main.py'
    )
    
    $missingFiles = @()
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            $missingFiles += $file
        }
    }
    
    return $missingFiles
}

# Main script
Write-Host "🚀 M365 Copilot Plugin Template Initializer" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

# Verify template files exist
$missingFiles = Test-TemplateFiles
if ($missingFiles.Count -gt 0) {
    Write-Host "❌ Missing required template files: $($missingFiles -join ', ')" -ForegroundColor Red
    Write-Host "Please run this script from the template root directory." -ForegroundColor Red
    exit 1
}

if ($Interactive) {
    Write-Host "`n📝 Please provide the following information for your new plugin:" -ForegroundColor Yellow
    Write-Host ""
    
    $PluginName = Get-UserInput "Plugin name (e.g., 'Sales Intelligence Plugin')" "My Copilot Plugin"
    $Description = Get-UserInput "Plugin description" "A Microsoft 365 Copilot plugin for $($PluginName.ToLower())"
    $ContactEmail = Get-UserInput "Contact email" "support@mycompany.com"
    $CompanyDomain = Get-UserInput "Company domain (without https://)" "mycompany.com"
    $ProjectPrefix = Get-UserInput "Project prefix for Azure resources" "my-plugin"
}

# Validate required parameters
if (-not $PluginName -or -not $Description -or -not $ContactEmail -or -not $CompanyDomain -or -not $ProjectPrefix) {
    Write-Host "❌ Missing required parameters. Use -Interactive switch or provide all parameters." -ForegroundColor Red
    exit 1
}

$CompanyUrl = "https://$CompanyDomain"

Write-Host "`n🔄 Updating template files..." -ForegroundColor Yellow

# Update plugin manifest
$manifestUpdates = @{
    'name_for_human' = $PluginName
    'description_for_human' = $Description
    'description_for_model' = "This plugin enables Microsoft 365 Copilot to $($Description.ToLower())"
    'contact_email' = $ContactEmail
    'legal_info_url' = "$CompanyUrl/legal"
    'privacy_policy_url' = "$CompanyUrl/privacy"
    'logo_url' = "$CompanyUrl/logo.png"
}

Update-JsonFile 'plugins\plugin_manifest.json' $manifestUpdates

# Update OpenAPI specification
$openApiReplacements = @{
    'M365 Copilot Plugin API' = "$PluginName API"
    'Declarative plugin for Microsoft 365 Copilot integration' = $Description
    'support@company.com' = $ContactEmail
}

Update-TextFile 'plugins\openapi.yaml' $openApiReplacements

# Update azure.yaml
$azureReplacements = @{
    'copilot-plugin-project' = $ProjectPrefix
    'copilot-plugin@1.0.0' = "$ProjectPrefix@1.0.0"
}

Update-TextFile 'azure.yaml' $azureReplacements

# Update main.bicep
$bicepReplacements = @{
    'copilot-plugin' = $ProjectPrefix
    'Copilot-Plugin' = $PluginName
}

Update-TextFile 'infra\main.bicep' $bicepReplacements

# Update README.md
$readmeReplacements = @{
    'Microsoft 365 Copilot Plugin Project' = $PluginName
    'This project demonstrates the complete implementation of a declarative Microsoft 365 Copilot plugin' = $Description
    'support@company.com' = $ContactEmail
}

Update-TextFile 'README.md' $readmeReplacements

Write-Host "`n✅ Template initialization complete!" -ForegroundColor Green
Write-Host "`n📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. Review and customize the generated files"
Write-Host "2. Update business logic in src\main.py"
Write-Host "3. Add your specific API endpoints to plugins\openapi.yaml"
Write-Host "4. Run 'azd init' to initialize Azure resources"
Write-Host "5. Run 'azd up' to deploy to Azure"
Write-Host "`n📚 See TEMPLATE_CUSTOMIZATION.md for detailed customization guide" -ForegroundColor Cyan
