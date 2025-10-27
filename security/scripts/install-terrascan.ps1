# Terrascan Installation Script for Windows
# This script downloads and installs Terrascan for policy-as-code security validation

param(
    [string]$Version = "latest",
    [string]$InstallPath = "$env:USERPROFILE\bin",
    [switch]$Force
)

Write-Host "Installing Terrascan for policy-as-code security validation..." -ForegroundColor Green

# Create installation directory if it doesn't exist
if (!(Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force
    Write-Host "Created installation directory: $InstallPath" -ForegroundColor Yellow
}

# Determine the latest version if not specified
if ($Version -eq "latest") {
    try {
        Write-Host "Fetching latest Terrascan version..." -ForegroundColor Blue
        $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/tenable/terrascan/releases/latest"
        $Version = $latestRelease.tag_name.TrimStart('v')
        Write-Host "Latest version found: $Version" -ForegroundColor Yellow
    } catch {
        Write-Error "Failed to fetch latest version. Using default version 1.18.3"
        $Version = "1.18.3"
    }
}

# Construct download URL
$downloadUrl = "https://github.com/tenable/terrascan/releases/download/v$Version/terrascan_$Version`_Windows_x86_64.tar.gz"
$tempFile = Join-Path $env:TEMP "terrascan.tar.gz"
$destinationPath = Join-Path $InstallPath "terrascan.exe"

# Check if Terrascan is already installed
if (Test-Path $destinationPath -and !$Force) {
    try {
        $currentVersion = & $destinationPath version 2>&1
        Write-Host "Terrascan is already installed: $currentVersion" -ForegroundColor Yellow
        Write-Host "Use -Force to reinstall" -ForegroundColor Cyan
        return
    } catch {
        Write-Host "Existing Terrascan installation appears corrupted, reinstalling..." -ForegroundColor Yellow
    }
}

# Download Terrascan
try {
    Write-Host "Downloading Terrascan version $Version..." -ForegroundColor Blue
    Write-Host "Download URL: $downloadUrl" -ForegroundColor Gray
    
    # Use Invoke-WebRequest to download the file
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -UseBasicParsing
    
    Write-Host "Terrascan downloaded successfully!" -ForegroundColor Green
    
} catch {
    Write-Error "Failed to download Terrascan: $_"
    exit 1
}

# Extract the tar.gz file
try {
    Write-Host "Extracting Terrascan..." -ForegroundColor Blue
    
    # Use tar command (available in Windows 10 1803+)
    $extractPath = Join-Path $env:TEMP "terrascan_extract"
    if (Test-Path $extractPath) {
        Remove-Item $extractPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
    
    # Extract using tar
    tar -xzf $tempFile -C $extractPath
    
    # Find the terrascan executable
    $extractedExe = Get-ChildItem -Path $extractPath -Name "terrascan.exe" -Recurse | Select-Object -First 1
    if ($extractedExe) {
        $sourcePath = Join-Path $extractPath $extractedExe
        Copy-Item $sourcePath $destinationPath -Force
        Write-Host "Terrascan extracted and installed successfully!" -ForegroundColor Green
    } else {
        Write-Error "Could not find terrascan.exe in the extracted files"
        exit 1
    }
    
    # Clean up temporary files
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    
} catch {
    Write-Error "Failed to extract Terrascan: $_"
    exit 1
}

# Verify installation
try {
    $terrascanVersion = & $destinationPath version 2>&1
    Write-Host "Terrascan installed successfully: $terrascanVersion" -ForegroundColor Green
    
} catch {
    Write-Error "Failed to verify Terrascan installation: $_"
    exit 1
}

# Add to PATH if not already there
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$InstallPath*") {
    Write-Host "Adding $InstallPath to user PATH..." -ForegroundColor Blue
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$InstallPath", "User")
    Write-Host "Please restart your terminal to use 'terrascan' command globally" -ForegroundColor Cyan
}

# Create reports directory if it doesn't exist
$reportsDir = "security/reports"
if (!(Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force
    Write-Host "Created reports directory: $reportsDir" -ForegroundColor Yellow
}

# Initialize Terrascan with default policies
try {
    Write-Host "Initializing Terrascan with default policies..." -ForegroundColor Blue
    & $destinationPath init
    Write-Host "Terrascan initialization completed!" -ForegroundColor Green
} catch {
    Write-Warning "Failed to initialize Terrascan policies. You may need to run 'terrascan init' manually."
}

Write-Host "Terrascan is ready to use!" -ForegroundColor Green
Write-Host "Run 'terrascan scan --config-path security/sast-tools/.terrascan_config.toml' to scan your Terraform code." -ForegroundColor Cyan
Write-Host "Installation path: $destinationPath" -ForegroundColor Gray