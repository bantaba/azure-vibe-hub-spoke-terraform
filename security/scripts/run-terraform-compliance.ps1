# Run Terraform Compliance Tests
# Policy-as-code testing using BDD-style feature files

param(
    [string]$PlanFile = "",
    [string]$PoliciesPath = "security/policies",
    [string]$ReportsPath = "security/reports",
    [string]$SourcePath = "src",
    [switch]$GeneratePlan = $true,
    [switch]$Verbose = $false,
    [switch]$FailOnError = $true,
    [string]$Features = ""  # Specific feature file to test (optional)
)

$ErrorActionPreference = "Continue"
$testStartTime = Get-Date

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    $colorMap = @{
        "Red" = [ConsoleColor]::Red
        "Green" = [ConsoleColor]::Green
        "Yellow" = [ConsoleColor]::Yellow
        "Blue" = [ConsoleColor]::Blue
        "Cyan" = [ConsoleColor]::Cyan
        "Magenta" = [ConsoleColor]::Magenta
        "Gray" = [ConsoleColor]::Gray
        "White" = [ConsoleColor]::White
    }
    
    Write-Host $Message -ForegroundColor $colorMap[$Color]
}

Write-ColorOutput "╔══════════════════════════════════════════════════════════════╗" "Cyan"
Write-ColorOutput "║          Terraform Compliance Policy Testing                ║" "Cyan"
Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"
Write-ColorOutput ""

# Check if terraform-compliance is installed
Write-ColorOutput "Checking prerequisites..." "Blue"
try {
    $tcVersion = terraform-compliance --version 2>&1
    Write-ColorOutput "  ✓ Terraform Compliance installed: $tcVersion" "Green"
} catch {
    Write-ColorOutput "  ✗ Terraform Compliance not found" "Red"
    Write-ColorOutput ""
    Write-ColorOutput "Please install Terraform Compliance:" "Yellow"
    Write-ColorOutput "  .\security\scripts\install-terraform-compliance.ps1" "Cyan"
    exit 1
}

# Check if Terraform is installed
try {
    $tfVersion = terraform version -json 2>&1 | ConvertFrom-Json
    Write-ColorOutput "  ✓ Terraform installed: $($tfVersion.terraform_version)" "Green"
} catch {
    Write-ColorOutput "  ✗ Terraform not found" "Red"
    exit 1
}

# Check if policies directory exists
if (!(Test-Path $PoliciesPath)) {
    Write-ColorOutput "  ✗ Policies directory not found: $PoliciesPath" "Red"
    exit 1
}
Write-ColorOutput "  ✓ Policies directory found" "Green"

# Check if source directory exists
if (!(Test-Path $SourcePath)) {
    Write-ColorOutput "  ✗ Source directory not found: $SourcePath" "Red"
    exit 1
}
Write-ColorOutput "  ✓ Source directory found" "Green"

# Create reports directory if needed
if (!(Test-Path $ReportsPath)) {
    New-Item -ItemType Directory -Path $ReportsPath -Force | Out-Null
    Write-ColorOutput "  ✓ Reports directory created" "Yellow"
} else {
    Write-ColorOutput "  ✓ Reports directory exists" "Green"
}

# Generate Terraform plan if needed
if ($GeneratePlan -or [string]::IsNullOrEmpty($PlanFile)) {
    Write-ColorOutput ""
    Write-ColorOutput "Generating Terraform plan..." "Blue"
    
    try {
        Push-Location $SourcePath
        
        # Initialize Terraform
        Write-ColorOutput "  Initializing Terraform..." "Gray"
        $initOutput = terraform init -backend=false 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "  ✗ Terraform init failed" "Red"
            Pop-Location
            exit 1
        }
        Write-ColorOutput "  ✓ Terraform initialized" "Green"
        
        # Generate plan
        Write-ColorOutput "  Generating plan..." "Gray"
        $planOutput = terraform plan -out=tfplan 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "  ✗ Terraform plan failed" "Red"
            Pop-Location
            exit 1
        }
        Write-ColorOutput "  ✓ Plan generated" "Green"
        
        # Convert plan to JSON
        Write-ColorOutput "  Converting plan to JSON..." "Gray"
        $jsonOutput = terraform show -json tfplan 2>&1
        $jsonOutput | Out-File -FilePath "tfplan.json" -Encoding UTF8
        
        if (Test-Path "tfplan.json") {
            Write-ColorOutput "  ✓ Plan converted to JSON" "Green"
            $PlanFile = "tfplan.json"
        } else {
            Write-ColorOutput "  ✗ Failed to convert plan to JSON" "Red"
            Pop-Location
            exit 1
        }
        
        Pop-Location
    } catch {
        Pop-Location
        Write-ColorOutput "  ✗ Error generating plan: $_" "Red"
        exit 1
    }
} else {
    # Use provided plan file
    if (!(Test-Path $PlanFile)) {
        Write-ColorOutput "  ✗ Plan file not found: $PlanFile" "Red"
        exit 1
    }
    Write-ColorOutput "  ✓ Using existing plan file: $PlanFile" "Green"
}

# Determine which features to test
$featureFiles = @()
if ([string]::IsNullOrEmpty($Features)) {
    # Test all feature files
    $featureFiles = Get-ChildItem -Path $PoliciesPath -Filter "*.feature" -File
    Write-ColorOutput ""
    Write-ColorOutput "Testing all policy features ($($featureFiles.Count) files)..." "Blue"
} else {
    # Test specific feature file
    $featurePath = Join-Path $PoliciesPath $Features
    if (!(Test-Path $featurePath)) {
        Write-ColorOutput "  ✗ Feature file not found: $featurePath" "Red"
        exit 1
    }
    $featureFiles = @(Get-Item $featurePath)
    Write-ColorOutput ""
    Write-ColorOutput "Testing specific feature: $Features..." "Blue"
}

# Run Terraform Compliance tests
$allResults = @()
$totalPassed = 0
$totalFailed = 0
$totalSkipped = 0

foreach ($feature in $featureFiles) {
    Write-ColorOutput ""
    Write-ColorOutput "=== Testing: $($feature.Name) ===" "Cyan"
    
    try {
        # Build terraform-compliance command
        $planPath = if ($PlanFile.StartsWith($SourcePath)) { $PlanFile } else { Join-Path $SourcePath $PlanFile }
        $featurePath = $feature.FullName
        
        # Run terraform-compliance
        $complianceArgs = @(
            "-f", $featurePath,
            "-p", $planPath
        )
        
        if ($Verbose) {
            $complianceArgs += "--verbose"
        }
        
        Write-ColorOutput "  Running compliance tests..." "Gray"
        $output = & terraform-compliance @complianceArgs 2>&1
        $exitCode = $LASTEXITCODE
        
        # Parse results
        $outputText = $output | Out-String
        
        # Extract test counts from output
        $passedMatch = [regex]::Match($outputText, "(\d+) passed")
        $failedMatch = [regex]::Match($outputText, "(\d+) failed")
        $skippedMatch = [regex]::Match($outputText, "(\d+) skipped")
        
        $passed = if ($passedMatch.Success) { [int]$passedMatch.Groups[1].Value } else { 0 }
        $failed = if ($failedMatch.Success) { [int]$failedMatch.Groups[1].Value } else { 0 }
        $skipped = if ($skippedMatch.Success) { [int]$skippedMatch.Groups[1].Value } else { 0 }
        
        $totalPassed += $passed
        $totalFailed += $failed
        $totalSkipped += $skipped
        
        # Store results
        $result = @{
            Feature = $feature.Name
            Passed = $passed
            Failed = $failed
            Skipped = $skipped
            ExitCode = $exitCode
            Output = $outputText
        }
        $allResults += $result
        
        # Display summary
        if ($exitCode -eq 0) {
            Write-ColorOutput "  ✓ All tests passed: $passed scenarios" "Green"
        } else {
            Write-ColorOutput "  ✗ Tests failed: $failed scenarios" "Red"
            Write-ColorOutput "  Passed: $passed, Skipped: $skipped" "Yellow"
        }
        
    } catch {
        Write-ColorOutput "  ✗ Error running tests: $_" "Red"
        $result = @{
            Feature = $feature.Name
            Passed = 0
            Failed = 1
            Skipped = 0
            ExitCode = 1
            Output = $_.ToString()
        }
        $allResults += $result
        $totalFailed++
    }
}

# Generate summary report
$testEndTime = Get-Date
$duration = $testEndTime - $testStartTime

Write-ColorOutput ""
Write-ColorOutput "╔══════════════════════════════════════════════════════════════╗" "Cyan"
Write-ColorOutput "║              Compliance Test Summary                         ║" "Cyan"
Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"
Write-ColorOutput ""
Write-ColorOutput "Total Scenarios:" "White"
Write-ColorOutput "  Passed:  $totalPassed" "Green"
Write-ColorOutput "  Failed:  $totalFailed" $(if ($totalFailed -gt 0) { "Red" } else { "Green" })
Write-ColorOutput "  Skipped: $totalSkipped" "Yellow"
Write-ColorOutput ""
Write-ColorOutput "Duration: $($duration.ToString('mm\:ss'))" "Gray"

# Save detailed report
$report = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    test_type = "terraform_compliance"
    summary = @{
        total_features = $featureFiles.Count
        total_passed = $totalPassed
        total_failed = $totalFailed
        total_skipped = $totalSkipped
        duration_seconds = $duration.TotalSeconds
    }
    results = $allResults
}

$reportPath = "$ReportsPath/terraform-compliance-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').json"
$report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
Write-ColorOutput "Report saved: $reportPath" "Cyan"

# Cleanup
if ($GeneratePlan) {
    try {
        Push-Location $SourcePath
        if (Test-Path "tfplan") {
            Remove-Item "tfplan" -Force
        }
        if (Test-Path "tfplan.json") {
            Remove-Item "tfplan.json" -Force
        }
        Pop-Location
    } catch {
        Pop-Location
    }
}

# Exit with appropriate code
Write-ColorOutput ""
if ($totalFailed -eq 0) {
    Write-ColorOutput "✅ All compliance tests passed!" "Green"
    exit 0
} else {
    Write-ColorOutput "❌ Some compliance tests failed!" "Red"
    if ($FailOnError) {
        exit 1
    } else {
        exit 0
    }
}
