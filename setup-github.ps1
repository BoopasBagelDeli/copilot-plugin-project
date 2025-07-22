#!/usr/bin/env pwsh

# GitHub Repository Setup Script for Microsoft 365 Copilot Plugin Project
# This script helps you create a GitHub repository and push your code

Write-Host "🚀 Microsoft 365 Copilot Plugin - GitHub Setup" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green

# Check if git is installed
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git is not installed. Please install Git first."
    exit 1
}

# Check if GitHub CLI is installed
$hasGithubCli = Get-Command gh -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "📋 Setup Instructions:" -ForegroundColor Yellow
Write-Host "1. Create a new repository on GitHub (https://github.com/new)" -ForegroundColor White
Write-Host "2. Repository name: 'copilot-plugin-project' (or your preferred name)" -ForegroundColor White
Write-Host "3. Description: 'Microsoft 365 Copilot Plugin with Azure Functions'" -ForegroundColor White
Write-Host "4. Set to Public or Private as needed" -ForegroundColor White
Write-Host "5. Do NOT initialize with README, .gitignore, or license (we have them)" -ForegroundColor White

Write-Host ""
$repoUrl = Read-Host "Enter your GitHub repository URL (e.g., https://github.com/username/copilot-plugin-project.git)"

if ([string]::IsNullOrWhiteSpace($repoUrl)) {
    Write-Error "Repository URL is required."
    exit 1
}

Write-Host ""
Write-Host "🔧 Initializing Git repository..." -ForegroundColor Blue

# Initialize git repository if not already initialized
if (-not (Test-Path ".git")) {
    git init
    Write-Host "✅ Git repository initialized" -ForegroundColor Green
} else {
    Write-Host "✅ Git repository already exists" -ForegroundColor Green
}

# Add all files
Write-Host "📁 Adding files to git..." -ForegroundColor Blue
git add .

# Check git status
Write-Host ""
Write-Host "📊 Git Status:" -ForegroundColor Yellow
git status --short

# Create initial commit
Write-Host ""
Write-Host "💾 Creating initial commit..." -ForegroundColor Blue
git commit -m "feat: Initial commit - Microsoft 365 Copilot Plugin Project

- Complete declarative plugin architecture with OpenAPI 3.0.1
- Azure Functions backend with Python runtime
- Comprehensive telemetry and monitoring setup
- Infrastructure as Code with Azure Bicep templates
- CI/CD pipelines with GitHub Actions
- Security best practices and governance integration
- Complete documentation and developer guides

Features:
- Search API for data retrieval
- Content analysis API for insights
- Health monitoring endpoints
- Azure AD authentication
- Managed identity integration
- Application Insights telemetry
- Key Vault secrets management

Ready for deployment with 'azd up'"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Initial commit created successfully" -ForegroundColor Green
} else {
    Write-Error "Failed to create initial commit"
    exit 1
}

# Add remote origin
Write-Host ""
Write-Host "🔗 Adding remote origin..." -ForegroundColor Blue
git remote add origin $repoUrl

# Push to GitHub
Write-Host ""
Write-Host "📤 Pushing to GitHub..." -ForegroundColor Blue
Write-Host "Note: You may be prompted for GitHub authentication" -ForegroundColor Yellow

git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "🎉 SUCCESS! Your code has been pushed to GitHub!" -ForegroundColor Green
    Write-Host "Repository URL: $repoUrl" -ForegroundColor White
} else {
    Write-Host ""
    Write-Warning "Push failed. This might be because:"
    Write-Host "1. The repository doesn't exist on GitHub" -ForegroundColor White
    Write-Host "2. You don't have permission to push" -ForegroundColor White
    Write-Host "3. Authentication is required" -ForegroundColor White
    Write-Host ""
    Write-Host "Please create the repository on GitHub first, then run:" -ForegroundColor Yellow
    Write-Host "git push -u origin main" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "🔨 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Configure GitHub repository secrets for CI/CD:" -ForegroundColor White
Write-Host "   - AZURE_CREDENTIALS (for Azure deployment)" -ForegroundColor Gray
Write-Host "   - TEAMS_WEBHOOK_URI (for notifications)" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Enable GitHub Actions if not already enabled" -ForegroundColor White
Write-Host ""
Write-Host "3. Create Azure environment and deploy:" -ForegroundColor White
Write-Host "   azd init" -ForegroundColor Cyan
Write-Host "   azd up" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Configure Microsoft 365 Copilot plugin in admin center" -ForegroundColor White

Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Yellow
Write-Host "- README.md - Project overview and setup" -ForegroundColor White
Write-Host "- docs/architecture.md - System architecture" -ForegroundColor White
Write-Host "- docs/telemetry.md - Monitoring and observability" -ForegroundColor White
Write-Host "- CONTRIBUTING.md - Contributing guidelines" -ForegroundColor White

Write-Host ""
Write-Host "🎯 Project successfully set up on GitHub!" -ForegroundColor Green
