# Install Terraform Compliance
# Policy-as-code testing framework using BDD-style tests

param(
    [switch]$Force = $false,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          Terraform Compliance Installation Script           ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if Python is installed
Write-Host "Checking Python installation..." -ForegroundColor Blue
try {
    $pythonVersion = python --version 2>&1
    Write-Host "  ✓ Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Python not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Python is required to install Terraform Compliance." -ForegroundColor Yellow
    Write-Host "Please install Python 3.7+ from https://www.python.org/downloads/" -ForegroundColor Yellow
    exit 1
}

# Check if pip is available
Write-Host "Checking pip installation..." -ForegroundColor Blue
try {
    $pipVersion = pip --version 2>&1
    Write-Host "  ✓ pip found: $pipVersion" -ForegroundColor Green
} catch {
    Write-Host "  ✗ pip not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "pip is required to install Terraform Compliance." -ForegroundColor Yellow
    Write-Host "Please ensure pip is installed with Python." -ForegroundColor Yellow
    exit 1
}

# Check if terraform-compliance is already installed
Write-Host ""
Write-Host "Checking existing installation..." -ForegroundColor Blue
try {
    $existingVersion = terraform-compliance --version 2>&1
    if ($Force) {
        Write-Host "  ⚠ Terraform Compliance already installed: $existingVersion" -ForegroundColor Yellow
        Write-Host "  Force flag set - reinstalling..." -ForegroundColor Yellow
    } else {
        Write-Host "  ✓ Terraform Compliance already installed: $existingVersion" -ForegroundColor Green
        Write-Host ""
        Write-Host "Use -Force to reinstall" -ForegroundColor Gray
        exit 0
    }
} catch {
    Write-Host "  Terraform Compliance not found - proceeding with installation" -ForegroundColor Gray
}

# Install terraform-compliance (latest version)
Write-Host ""
Write-Host "Installing Terraform Compliance (latest version)..." -ForegroundColor Blue
try {
    if ($Force) {
        # Upgrade to latest version
        if ($Verbose) {
            pip install --upgrade terraform-compliance
        } else {
            pip install --upgrade terraform-compliance --quiet
        }
    } else {
        # Install latest version
        if ($Verbose) {
            pip install --upgrade terraform-compliance
        } else {
            pip install --upgrade terraform-compliance --quiet
        }
    }
    
    Write-Host "  ✓ Installation completed" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Installation failed: $_" -ForegroundColor Red
    exit 1
}

# Verify installation
Write-Host ""
Write-Host "Verifying installation..." -ForegroundColor Blue
try {
    $version = terraform-compliance --version 2>&1
    Write-Host "  ✓ Terraform Compliance installed successfully" -ForegroundColor Green
    Write-Host "  Version: $version" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Verification failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                  Installation Successful                     ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Create policy files in security/policies/" -ForegroundColor Gray
Write-Host "2. Run: terraform-compliance -f security/policies/ -p tfplan.json" -ForegroundColor Gray
Write-Host "3. See documentation: https://terraform-compliance.com/" -ForegroundColor Gray
Write-Host ""
