# Pre-commit Hook for Terraform Security Scanning
# This script runs security scans and validation checks before allowing commitsnd validation checks before allowing commits

param(
    [switch]$SkipSecurity = $false,
    [switch]$SkipFormat = $false,
    [switch]$SkipValidation = $false,
    [switch]$Verbose = $false
)

# Initialize variables
$script:ExitCode = 0
$script:HasErrors = $false
$script:HasWarnings = $false

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    switch ($Color.ToLower()) {
        "red" { Write-Host $Message -ForegroundColor Red }
        "green" { Write-Host $Message -ForegroundColor Green }
        "yellow" { Write-Host $Message -ForegroundColor Yellow }
        "blue" { Write-Host $Message -ForegroundColor Blue }
        "cyan" { Write-Host $Message -ForegroundColor Cyan }
        "magenta" { Write-Host $Message -ForegroundColor Magenta }
        default { Write-Host $Message }
    }
}

# Function to check if a command exists
function Test-CommandExists {
    param([string]$Command)
    
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Function to get staged Terraform files
function Get-StagedTerraformFiles {
    try {
        $stagedFiles = git diff --cached --name-only --diff-filter=ACM
        $terraformFiles = $stagedFiles | Where-Object { $_ -match '\.(tf|tfvars)$' -and $_ -like 'src/*' }
        return $terraformFiles
    } catch {
        Write-ColorOutput "Error getting staged files: $_" "Red"
        return @()
    }
}

# Function to run Terraform format check
function Test-TerraformFormat {
    Write-ColorOutput "`n=== Terraform Format Check ===" "Blue"
    
    if (!(Test-CommandExists "terraform")) {
        Write-ColorOutput "Terraform not found. Please install Terraform." "Red"
        $script:HasErrors = $true
        return $false
    }
    
    try {
        $formatResult = terraform fmt -check -recursive src/ 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ All Terraform files are properly formatted" "Green"
            return $true
        } else {
            Write-ColorOutput "❌ Terraform files are not properly formatted:" "Red"
            Write-ColorOutput $formatResult "Yellow"
            Write-ColorOutput "`nRun 'terraform fmt -recursive src/' to fix formatting issues" "Yellow"
            $script:HasErrors = $true
            return $false
        }
    } catch {
        Write-ColorOutput "Error running Terraform format check: $_" "Red"
        $script:HasErrors = $true
        return $false
    }
}

# Function to run Terraform validation
function Test-TerraformValidation {
    Write-ColorOutput "`n=== Terraform Validation ===" "Blue"
    
    if (!(Test-CommandExists "terraform")) {
        Write-ColorOutput "Terraform not found. Please install Terraform." "Red"
        $script:HasErrors = $true
        return $false
    }
    
    try {
        Push-Location src
        
        # Initialize Terraform (without backend for validation)
        Write-ColorOutput "Initializing Terraform..." "Gray"
        $initResult = terraform init -backend=false 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "❌ Terraform initialization failed:" "Red"
            Write-ColorOutput $initResult "Yellow"
            $script:HasErrors = $true
            return $false
        }
        
        # Validate Terraform configuration
        Write-ColorOutput "Validating Terraform configuration..." "Gray"
        $validateResult = terraform validate 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Terraform validation passed" "Green"
            return $true
        } else {
            Write-ColorOutput "❌ Terraform validation failed:" "Red"
            Write-ColorOutput $validateResult "Yellow"
            $script:HasErrors = $true
            return $false
        }
    } catch {
        Write-ColorOutput "Error running Terraform validation: $_" "Red"
        $script:HasErrors = $true
        return $false
    } finally {
        Pop-Location
    }
}

# Function to run quick security scan
function Invoke-QuickSecurityScan {
    Write-ColorOutput "`n=== Quick Security Scan ===" "Blue"
    
    $scanSuccess = $true
    $issuesFound = 0
    
    # Check if any security tools are available
    $availableTools = @()
    if (Test-CommandExists "checkov") { $availableTools += "checkov" }
    if (Test-CommandExists "tfsec") { $availableTools += "tfsec" }
    if (Test-CommandExists "terrascan") { $availableTools += "terrascan" }
    
    if ($availableTools.Count -eq 0) {
        Write-ColorOutput "⚠️  No security scanning tools found (checkov, tfsec, terrascan)" "Yellow"
        Write-ColorOutput "Consider installing security tools for better pre-commit validation" "Yellow"
        $script:HasWarnings = $true
        return $true
    }
    
    # Create temporary reports directory
    $tempReportsDir = "temp-reports"
    if (!(Test-Path $tempReportsDir)) {
        New-Item -ItemType Directory -Path $tempReportsDir -Force | Out-Null
    }
    
    try {
        # Run available tools with quick scan options
        foreach ($tool in $availableTools) {
            Write-ColorOutput "Running $tool quick scan..." "Gray"
            
            switch ($tool) {
                "checkov" {
                    try {
                        $checkovResult = checkov -d src/ --quiet --compact --framework terraform --output cli 2>&1
                        if ($LASTEXITCODE -ne 0) {
                            $issuesFound++
                            Write-ColorOutput "⚠️  Checkov found security issues" "Yellow"
                            if ($Verbose) {
                                Write-ColorOutput $checkovResult "Gray"
                            }
                        } else {
                            Write-ColorOutput "✅ Checkov scan passed" "Green"
                        }
                    } catch {
                        Write-ColorOutput "Error running Checkov: $_" "Yellow"
                        $script:HasWarnings = $true
                    }
                }
                "tfsec" {
                    try {
                        $tfsecResult = tfsec src/ --no-color --concise-output 2>&1
                        if ($LASTEXITCODE -ne 0) {
                            $issuesFound++
                            Write-ColorOutput "⚠️  TFSec found security issues" "Yellow"
                            if ($Verbose) {
                                Write-ColorOutput $tfsecResult "Gray"
                            }
                        } else {
                            Write-ColorOutput "✅ TFSec scan passed" "Green"
                        }
                    } catch {
                        Write-ColorOutput "Error running TFSec: $_" "Yellow"
                        $script:HasWarnings = $true
                    }
                }
                "terrascan" {
                    try {
                        $terrascanResult = terrascan scan -i terraform -d src/ --non-recursive --verbose 2>&1
                        if ($LASTEXITCODE -ne 0) {
                            $issuesFound++
                            Write-ColorOutput "⚠️  Terrascan found security issues" "Yellow"
                            if ($Verbose) {
                                Write-ColorOutput $terrascanResult "Gray"
                            }
                        } else {
                            Write-ColorOutput "✅ Terrascan scan passed" "Green"
                        }
                    } catch {
                        Write-ColorOutput "Error running Terrascan: $_" "Yellow"
                        $script:HasWarnings = $true
                    }
                }
            }
        }
        
        if ($issuesFound -gt 0) {
            Write-ColorOutput "`n⚠️  Security scan found $issuesFound potential issues" "Yellow"
            Write-ColorOutput "Run 'scripts/security/run-sast-scan.ps1' for detailed analysis" "Yellow"
            $script:HasWarnings = $true
        } else {
            Write-ColorOutput "✅ Quick security scan passed" "Green"
        }
        
        return $true
        
    } finally {
        # Clean up temporary directory
        if (Test-Path $tempReportsDir) {
            Remove-Item -Path $tempReportsDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Function to check for sensitive data
function Test-SensitiveData {
    Write-ColorOutput "`n=== Sensitive Data Check ===" "Blue"
    
    $sensitivePatterns = @(
        @{ Pattern = "password\s*=\s*[`"'][^`"']+[`"']"; Description = "Hardcoded password" }
        @{ Pattern = "secret\s*=\s*[`"'][^`"']+[`"']"; Description = "Hardcoded secret" }
        @{ Pattern = "api_key\s*=\s*[`"'][^`"']+[`"']"; Description = "Hardcoded API key" }
        @{ Pattern = "access_key\s*=\s*[`"'][^`"']+[`"']"; Description = "Hardcoded access key" }
        @{ Pattern = "private_key\s*=\s*[`"'][^`"']+[`"']"; Description = "Hardcoded private key" }
        @{ Pattern = "token\s*=\s*[`"'][^`"']+[`"']"; Description = "Hardcoded token" }
        @{ Pattern = "connection_string\s*=\s*[`"'][^`"']+[`"']"; Description = "Hardcoded connection string" }
    )
    
    $stagedFiles = Get-StagedTerraformFiles
    $sensitiveDataFound = $false
    
    foreach ($file in $stagedFiles) {
        if (Test-Path $file) {
            $content = Get-Content $file -Raw
            
            foreach ($pattern in $sensitivePatterns) {
                if ($content -match $pattern.Pattern) {
                    Write-ColorOutput "❌ Potential sensitive data found in $file" "Red"
                    Write-ColorOutput "   Pattern: $($pattern.Description)" "Yellow"
                    $sensitiveDataFound = $true
                }
            }
        }
    }
    
    if ($sensitiveDataFound) {
        Write-ColorOutput "`n❌ Sensitive data detected in staged files!" "Red"
        Write-ColorOutput "Please remove hardcoded secrets and use Azure Key Vault or variables instead" "Yellow"
        $script:HasErrors = $true
        return $false
    } else {
        Write-ColorOutput "✅ No sensitive data detected" "Green"
        return $true
    }
}

# Function to check file size limits
function Test-FileSizeLimits {
    Write-ColorOutput "`n=== File Size Check ===" "Blue"
    
    $maxFileSize = 1MB # 1MB limit
    $stagedFiles = git diff --cached --name-only --diff-filter=ACM
    $oversizedFiles = @()
    
    foreach ($file in $stagedFiles) {
        if (Test-Path $file) {
            $fileSize = (Get-Item $file).Length
            if ($fileSize -gt $maxFileSize) {
                $oversizedFiles += @{
                    File = $file
                    Size = [math]::Round($fileSize / 1MB, 2)
                }
            }
        }
    }
    
    if ($oversizedFiles.Count -gt 0) {
        Write-ColorOutput "⚠️  Large files detected:" "Yellow"
        foreach ($file in $oversizedFiles) {
            Write-ColorOutput "   $($file.File): $($file.Size) MB" "Yellow"
        }
        Write-ColorOutput "Consider using Git LFS for large files" "Yellow"
        $script:HasWarnings = $true
    } else {
        Write-ColorOutput "✅ All files are within size limits" "Green"
    }
    
    return $true
}

# Main execution
Write-ColorOutput "🔍 Running Pre-commit Validation" "Cyan"
Write-ColorOutput "================================" "Cyan"

# Get staged Terraform files
$stagedTerraformFiles = Get-StagedTerraformFiles

if ($stagedTerraformFiles.Count -eq 0) {
    Write-ColorOutput "No Terraform files staged for commit. Skipping Terraform-specific checks." "Yellow"
    
    # Still run general checks
    Test-FileSizeLimits | Out-Null
    
    Write-ColorOutput "`n✅ Pre-commit validation completed" "Green"
    exit 0
}

Write-ColorOutput "Found $($stagedTerraformFiles.Count) staged Terraform files:" "Gray"
foreach ($file in $stagedTerraformFiles) {
    Write-ColorOutput "  - $file" "Gray"
}

# Run validation checks
$checks = @()

if (!$SkipFormat) {
    $checks += @{ Name = "Terraform Format"; Function = { Test-TerraformFormat } }
}

if (!$SkipValidation) {
    $checks += @{ Name = "Terraform Validation"; Function = { Test-TerraformValidation } }
}

$checks += @{ Name = "Sensitive Data Check"; Function = { Test-SensitiveData } }
$checks += @{ Name = "File Size Check"; Function = { Test-FileSizeLimits } }

if (!$SkipSecurity) {
    $checks += @{ Name = "Quick Security Scan"; Function = { Invoke-QuickSecurityScan } }
}

# Execute all checks
foreach ($check in $checks) {
    try {
        & $check.Function | Out-Null
    } catch {
        Write-ColorOutput "Error in $($check.Name): $_" "Red"
        $script:HasErrors = $true
    }
}

# Summary
Write-ColorOutput "`n" "White"
Write-ColorOutput "=== Pre-commit Validation Summary ===" "Cyan"

if ($script:HasErrors) {
    Write-ColorOutput "❌ Pre-commit validation FAILED" "Red"
    Write-ColorOutput "Please fix the errors above before committing" "Yellow"
    $script:ExitCode = 1
} elseif ($script:HasWarnings) {
    Write-ColorOutput "⚠️  Pre-commit validation completed with warnings" "Yellow"
    Write-ColorOutput "Consider addressing the warnings for better code quality" "Yellow"
} else {
    Write-ColorOutput "✅ Pre-commit validation PASSED" "Green"
}

Write-ColorOutput "`nTip: Use 'git commit --no-verify' to skip pre-commit hooks if needed" "Gray"

exit $script:ExitCode