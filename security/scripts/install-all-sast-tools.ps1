# Install All SAST Tools Script
# This script installs Checkov, TFSec, and Terrascan for comprehensive security scanning

param(
    [switch]$Force,
    [switch]$SkipCheckov,
    [switch]$SkipTFSec,
    [switch]$SkipTerrascan,
    [string]$InstallPath = "$env:USERPROFILE\bin"
)

Write-Host "Installing SAST Tools for Terraform Security Scanning" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$installationResults = @{}

# Function to run installation script
function Invoke-InstallScript {
    param(
        [string]$ScriptName,
        [string]$ToolName,
        [switch]$Force
    )
    
    $scriptFile = Join-Path $scriptPath $ScriptName
    
    if (!(Test-Path $scriptFile)) {
        Write-Host "Installation script not found: $scriptFile" -ForegroundColor Red
        return $false
    }
    
    try {
        Write-Host "`nInstalling $ToolName..." -ForegroundColor Blue
        
        $params = @{}
        if ($Force) { $params.Force = $true }
        if ($InstallPath -ne "$env:USERPROFILE\bin") { $params.InstallPath = $InstallPath }
        
        & $scriptFile @params
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$ToolName installation completed successfully!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "$ToolName installation failed with exit code: $LASTEXITCODE" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "Error installing $ToolName`: $_" -ForegroundColor Red
        return $false
    }
}

# Install Checkov
if (!$SkipCheckov) {
    Write-Host "`n=== Installing Checkov ===" -ForegroundColor Cyan
    $installationResults["Checkov"] = Invoke-InstallScript "install-checkov.ps1" "Checkov" -Force:$Force
} else {
    Write-Host "`nSkipping Checkov installation" -ForegroundColor Yellow
    $installationResults["Checkov"] = "Skipped"
}

# Install TFSec
if (!$SkipTFSec) {
    Write-Host "`n=== Installing TFSec ===" -ForegroundColor Cyan
    $installationResults["TFSec"] = Invoke-InstallScript "install-tfsec.ps1" "TFSec" -Force:$Force
} else {
    Write-Host "`nSkipping TFSec installation" -ForegroundColor Yellow
    $installationResults["TFSec"] = "Skipped"
}

# Install Terrascan
if (!$SkipTerrascan) {
    Write-Host "`n=== Installing Terrascan ===" -ForegroundColor Cyan
    $installationResults["Terrascan"] = Invoke-InstallScript "install-terrascan.ps1" "Terrascan" -Force:$Force
} else {
    Write-Host "`nSkipping Terrascan installation" -ForegroundColor Yellow
    $installationResults["Terrascan"] = "Skipped"
}

# Display installation summary
Write-Host "`n=== Installation Summary ===" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

$successCount = 0
$failureCount = 0

foreach ($tool in $installationResults.Keys) {
    $result = $installationResults[$tool]
    $status = switch ($result) {
        $true { "SUCCESS"; $successCount++; "Green" }
        $false { "FAILED"; $failureCount++; "Red" }
        "Skipped" { "SKIPPED"; "Yellow" }
        default { "UNKNOWN"; "Gray" }
    }
    
    Write-Host "$tool`: " -NoNewline
    Write-Host $status[0] -ForegroundColor $status[1]
}

Write-Host "`nTools successfully installed: $successCount" -ForegroundColor Green
if ($failureCount -gt 0) {
    Write-Host "Tools failed to install: $failureCount" -ForegroundColor Red
}

# Create reports directory
$reportsDir = "security/reports"
if (!(Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
    Write-Host "`nCreated reports directory: $reportsDir" -ForegroundColor Yellow
}

# Display usage instructions
Write-Host "`n=== Usage Instructions ===" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan
Write-Host "To run all SAST tools:" -ForegroundColor White
Write-Host "  .\security\scripts\run-sast-scan.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "To run individual tools:" -ForegroundColor White
Write-Host "  checkov --config-file security/sast-tools/.checkov.yaml" -ForegroundColor Gray
Write-Host "  tfsec --config-file security/sast-tools/.tfsec.yml src/" -ForegroundColor Gray
Write-Host "  terrascan scan --config-path security/sast-tools/.terrascan_config.toml" -ForegroundColor Gray
Write-Host ""
Write-Host "Reports will be saved to: $reportsDir" -ForegroundColor Yellow

if ($failureCount -eq 0 -and $successCount -gt 0) {
    Write-Host "`nAll SAST tools are ready to use!" -ForegroundColor Green
    exit 0
} elseif ($failureCount -gt 0) {
    Write-Host "`nSome tools failed to install. Please check the error messages above." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nNo tools were installed." -ForegroundColor Yellow
    exit 0
}