#!/usr/bin/env pwsh
# Teams App Package Creator for M365 Copilot Plugin Registration
# Creates a Teams app package ready for Teams Admin Center upload

param(
    [string]$OutputPath = "teams-app-package.zip",
    [switch]$CreateIcons = $false
)

Write-Host "🚀 Creating Teams App Package for M365 Copilot Plugin" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

# Check required files
$requiredFiles = @(
    "teams-app\manifest.json",
    "teams-app\plugin_manifest.json"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "❌ Missing required files: $($missingFiles -join ', ')" -ForegroundColor Red
    Write-Host "Run this script from the project root directory." -ForegroundColor Red
    exit 1
}

# Check for icon files
$iconFiles = @("teams-app\color.png", "teams-app\outline.png")
$missingIcons = @()
foreach ($icon in $iconFiles) {
    if (-not (Test-Path $icon)) {
        $missingIcons += $icon
    }
}

if ($missingIcons.Count -gt 0) {
    Write-Host "⚠️  Missing icon files: $($missingIcons -join ', ')" -ForegroundColor Yellow
    
    if ($CreateIcons) {
        Write-Host "🎨 Creating placeholder icons..." -ForegroundColor Yellow
        
        # Create simple placeholder icons using PowerShell and .NET
        Add-Type -AssemblyName System.Drawing
        
        # Create color icon (192x192)
        $colorBitmap = New-Object System.Drawing.Bitmap(192, 192)
        $colorGraphics = [System.Drawing.Graphics]::FromImage($colorBitmap)
        $colorBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 120, 212))
        $colorGraphics.FillRectangle($colorBrush, 0, 0, 192, 192)
        
        $font = New-Object System.Drawing.Font("Arial", 24, [System.Drawing.FontStyle]::Bold)
        $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $colorGraphics.DrawString("CP", $font, $textBrush, 70, 80)
        
        $colorBitmap.Save("teams-app\color.png", [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Host "✅ Created teams-app\color.png" -ForegroundColor Green
        
        # Create outline icon (32x32)
        $outlineBitmap = New-Object System.Drawing.Bitmap(32, 32)
        $outlineGraphics = [System.Drawing.Graphics]::FromImage($outlineBitmap)
        $outlineGraphics.Clear([System.Drawing.Color]::Transparent)
        
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 2)
        $outlineGraphics.DrawRectangle($pen, 2, 2, 28, 28)
        
        $smallFont = New-Object System.Drawing.Font("Arial", 8, [System.Drawing.FontStyle]::Bold)
        $outlineGraphics.DrawString("CP", $smallFont, $textBrush, 8, 11)
        
        $outlineBitmap.Save("teams-app\outline.png", [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Host "✅ Created teams-app\outline.png" -ForegroundColor Green
        
        # Cleanup
        $colorGraphics.Dispose()
        $colorBitmap.Dispose()
        $outlineGraphics.Dispose()
        $outlineBitmap.Dispose()
        $colorBrush.Dispose()
        $textBrush.Dispose()
        $pen.Dispose()
        $font.Dispose()
        $smallFont.Dispose()
    }
    else {
        Write-Host "Use -CreateIcons switch to create placeholder icons, or add your own icons." -ForegroundColor Yellow
        Write-Host "Required: teams-app\color.png (192x192) and teams-app\outline.png (32x32)" -ForegroundColor Yellow
        exit 1
    }
}

# Create ZIP package
Write-Host "📦 Creating Teams app package..." -ForegroundColor Yellow

if (Test-Path $OutputPath) {
    Remove-Item $OutputPath -Force
}

# Create the ZIP file
$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
[System.IO.Compression.ZipFile]::CreateFromDirectory("teams-app", $OutputPath, $compressionLevel, $false)

Write-Host "✅ Teams app package created: $OutputPath" -ForegroundColor Green

# Validate package contents
Write-Host "`n📋 Package Contents:" -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($OutputPath)
foreach ($entry in $zip.Entries) {
    Write-Host "  - $($entry.Name)" -ForegroundColor Gray
}
$zip.Dispose()

Write-Host "`n🎯 Next Steps:" -ForegroundColor Green
Write-Host "1. Upload $OutputPath to Teams Admin Center" -ForegroundColor White
Write-Host "   → https://admin.teams.microsoft.com" -ForegroundColor Gray
Write-Host "2. Go to Teams apps → Manage apps → Upload app" -ForegroundColor White
Write-Host "3. Configure app policies and user access" -ForegroundColor White
Write-Host "4. Enable in Microsoft 365 Admin Center" -ForegroundColor White
Write-Host "   → https://admin.microsoft.com → Settings → Integrated apps" -ForegroundColor Gray

Write-Host "`n⚠️  Prerequisites:" -ForegroundColor Yellow
Write-Host "- Complete Azure AD permissions setup in Azure Portal" -ForegroundColor White
Write-Host "- Global Admin or Teams Administrator access required" -ForegroundColor White
Write-Host "- M365 Copilot license for testing users" -ForegroundColor White

Write-Host "`n🎉 Ready for M365 Copilot Plugin Registration!" -ForegroundColor Cyan
