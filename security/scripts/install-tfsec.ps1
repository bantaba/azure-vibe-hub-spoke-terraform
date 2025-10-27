# TFSec Installation Script for Windows
# This script downloads and installs TFSec for Terraform security scanning

param(
    [string]$Version = "latest",
    [string]$InstallPath = "$env:USERPROFILE\bin",
    [switch]$Force
)

Write-Host "Installing TFSec for Terraform security scanning..." -ForegroundColor Green

# Create installation directory if it doesn't exist
if (!(Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force
    Write-Host "Created installation directory: $InstallPath" -ForegroundColor Yellow
}

# Determine the latest version if not specified
if ($Version -eq "latest") {
    try {
        Write-Host "Fetching latest TFSec version..." -ForegroundColor Blue
        $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/aquasecurity/tfsec/releases/latest"
        $Version = $latestRelease.tag_name.TrimStart('v')
        Write-Host "Latest version found: $Version" -ForegroundColor Yellow
    } catch {
        Write-Error "Failed to fetch latest version. Using default version 1.28.1"
        $Version = "1.28.1"
    }
}

# Construct download URL
$downloadUrl = "https://github.com/aquasecurity/tfsec/releases/download/v$Version/tfsec-windows-amd64.exe"
$destinationPath = Join-Path $InstallPath "tfsec.exe"

# Check if TFSec is already installed
if (Test-Path $destinationPath -and !$Force) {
    try {
        $currentVersion = & $destinationPath --version 2>&1
        Write-Host "TFSec is already installed: $currentVersion" -ForegroundColor Yellow
        Write-Host "Use -Force to reinstall" -ForegroundColor Cyan
        return
    } catch {
        Write-Host "Existing TFSec installation appears corrupted, reinstalling..." -ForegroundColor Yellow
    }
}

# Download TFSec
try {
    Write-Host "Downloading TFSec version $Version..." -ForegroundColor Blue
    Write-Host "Download URL: $downloadUrl" -ForegroundColor Gray
    
    # Use Invoke-WebRequest to download the file
    Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationPath -UseBasicParsing
    
    Write-Host "TFSec downloaded successfully!" -ForegroundColor Green
    
} catch {
    Write-Error "Failed to download TFSec: $_"
    exit 1
}

# Make sure the file is executable and verify installation
try {
    $tfsecVersion = & $destinationPath --version 2>&1
    Write-Host "TFSec installed successfully: $tfsecVersion" -ForegroundColor Green
    
} catch {
    Write-Error "Failed to verify TFSec installation: $_"
    exit 1
}

# Add to PATH if not already there
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$InstallPath*") {
    Write-Host "Adding $InstallPath to user PATH..." -ForegroundColor Blue
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$InstallPath", "User")
    Write-Host "Please restart your terminal to use 'tfsec' command globally" -ForegroundColor Cyan
}

# Create reports directory if it doesn't exist
$reportsDir = "security/reports"
if (!(Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force
    Write-Host "Created reports directory: $reportsDir" -ForegroundColor Yellow
}

Write-Host "TFSec is ready to use!" -ForegroundColor Green
Write-Host "Run 'tfsec --config-file security/sast-tools/.tfsec.yml src/' to scan your Terraform code." -ForegroundColor Cyan
Write-Host "Installation path: $destinationPath" -ForegroundColor Gray