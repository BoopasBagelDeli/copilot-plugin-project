#!/bin/bash

# GitHub Repository Setup Script for Microsoft 365 Copilot Plugin Project
# This script helps you create a GitHub repository and push your code

echo "🚀 Microsoft 365 Copilot Plugin - GitHub Setup"
echo "================================================="

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed. Please install Git first."
    exit 1
fi

# Check if GitHub CLI is installed
if command -v gh &> /dev/null; then
    HAS_GITHUB_CLI=true
else
    HAS_GITHUB_CLI=false
fi

echo ""
echo "📋 Setup Instructions:"
echo "1. Create a new repository on GitHub (https://github.com/new)"
echo "2. Repository name: 'copilot-plugin-project' (or your preferred name)"
echo "3. Description: 'Microsoft 365 Copilot Plugin with Azure Functions'"
echo "4. Set to Public or Private as needed"
echo "5. Do NOT initialize with README, .gitignore, or license (we have them)"

echo ""
read -p "Enter your GitHub repository URL (e.g., https://github.com/username/copilot-plugin-project.git): " REPO_URL

if [[ -z "$REPO_URL" ]]; then
    echo "❌ Repository URL is required."
    exit 1
fi

echo ""
echo "🔧 Initializing Git repository..."

# Initialize git repository if not already initialized
if [[ ! -d ".git" ]]; then
    git init
    echo "✅ Git repository initialized"
else
    echo "✅ Git repository already exists"
fi

# Add all files
echo "📁 Adding files to git..."
git add .

# Check git status
echo ""
echo "📊 Git Status:"
git status --short

# Create initial commit
echo ""
echo "💾 Creating initial commit..."
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

if [[ $? -eq 0 ]]; then
    echo "✅ Initial commit created successfully"
else
    echo "❌ Failed to create initial commit"
    exit 1
fi

# Add remote origin
echo ""
echo "🔗 Adding remote origin..."
git remote add origin "$REPO_URL"

# Push to GitHub
echo ""
echo "📤 Pushing to GitHub..."
echo "Note: You may be prompted for GitHub authentication"

git push -u origin main

if [[ $? -eq 0 ]]; then
    echo ""
    echo "🎉 SUCCESS! Your code has been pushed to GitHub!"
    echo "Repository URL: $REPO_URL"
else
    echo ""
    echo "⚠️  Push failed. This might be because:"
    echo "1. The repository doesn't exist on GitHub"
    echo "2. You don't have permission to push"
    echo "3. Authentication is required"
    echo ""
    echo "Please create the repository on GitHub first, then run:"
    echo "git push -u origin main"
fi

echo ""
echo "🔨 Next Steps:"
echo "1. Configure GitHub repository secrets for CI/CD:"
echo "   - AZURE_CREDENTIALS (for Azure deployment)"
echo "   - TEAMS_WEBHOOK_URI (for notifications)"
echo ""
echo "2. Enable GitHub Actions if not already enabled"
echo ""
echo "3. Create Azure environment and deploy:"
echo "   azd init"
echo "   azd up"
echo ""
echo "4. Configure Microsoft 365 Copilot plugin in admin center"

echo ""
echo "📚 Documentation:"
echo "- README.md - Project overview and setup"
echo "- docs/architecture.md - System architecture"
echo "- docs/telemetry.md - Monitoring and observability"
echo "- CONTRIBUTING.md - Contributing guidelines"

echo ""
echo "🎯 Project successfully set up on GitHub!"
