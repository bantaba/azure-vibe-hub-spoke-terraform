# Checkov Installation Script for Windows
# This script installs Checkov and its dependencies

param(
    [switch]$Force,
    [string]$Version = "latest"
)

Write-Host "Installing Checkov for Terraform security scanning..." -ForegroundColor Green

# Check if Python is installed
try {
    $pythonVersion = python --version 2>&1
    Write-Host "Found Python: $pythonVersion" -ForegroundColor Yellow
} catch {
    Write-Error "Python is not installed or not in PATH. Please install Python 3.7+ first."
    exit 1
}

# Check if pip is available
try {
    $pipVersion = pip --version 2>&1
    Write-Host "Found pip: $pipVersion" -ForegroundColor Yellow
} catch {
    Write-Error "pip is not available. Please ensure pip is installed with Python."
    exit 1
}

# Install or upgrade Checkov
try {
    if ($Version -eq "latest") {
        Write-Host "Installing latest version of Checkov..." -ForegroundColor Blue
        if ($Force) {
            pip install --upgrade --force-reinstall checkov
        } else {
            pip install --upgrade checkov
        }
    } else {
        Write-Host "Installing Checkov version $Version..." -ForegroundColor Blue
        if ($Force) {
            pip install --upgrade --force-reinstall checkov==$Version
        } else {
            pip install checkov==$Version
        }
    }
    
    Write-Host "Checkov installation completed successfully!" -ForegroundColor Green
    
    # Verify installation
    $checkovVersion = checkov --version 2>&1
    Write-Host "Installed Checkov version: $checkovVersion" -ForegroundColor Yellow
    
} catch {
    Write-Error "Failed to install Checkov: $_"
    exit 1
}

# Create reports directory if it doesn't exist
$reportsDir = "security/reports"
if (!(Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force
    Write-Host "Created reports directory: $reportsDir" -ForegroundColor Yellow
}

Write-Host "Checkov is ready to use!" -ForegroundColor Green
Write-Host "Run 'checkov --config-file security/sast-tools/.checkov.yaml' to scan your Terraform code." -ForegroundColor Cyan