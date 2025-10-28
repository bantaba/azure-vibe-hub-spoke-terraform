# Security Posture Tracking Module
# Provides functions for security posture calculation, trend analysis, and reporting

# Function to calculate security posture score
function Get-SecurityPostureScore {
    param(
        [int]$CriticalFindings = 0,
        [int]$HighFindings = 0,
        [int]$MediumFindings = 0,
        [int]$LowFindings = 0,
        [int]$InfoFindings = 0,
        [hashtable]$Weights = @{
            "CRITICAL" = 10
            "HIGH" = 7
            "MEDIUM" = 4
            "LOW" = 1
            "INFO" = 0
        },
        [hashtable]$Thresholds = @{
            "low" = 50
            "medium" = 200
            "high" = 500
        }
    )
    
    # Calculate raw risk score
    $riskScore = ($CriticalFindings * $Weights.CRITICAL) +
                 ($HighFindings * $Weights.HIGH) +
                 ($MediumFindings * $Weights.MEDIUM) +
                 ($LowFindings * $Weights.LOW) +
                 ($InfoFindings * $Weights.INFO)
    
    # Calculate normalized security score (0-100, higher is better)
    $totalFindings = $CriticalFindings + $HighFindings + $MediumFindings + $LowFindings + $InfoFindings
    
    if ($totalFindings -eq 0) {
        $securityScore = 100
        $riskLevel = "low"
    } else {
        $maxRisk = $Thresholds.high
        $normalizedRisk = [Math]::Min($riskScore / $maxRisk, 1.0)
        $securityScore = [Math]::Max(0, 100 - ($normalizedRisk * 100))
        
        if ($riskScore -lt $Thresholds.low) {
            $riskLevel = "low"
        } elseif ($riskScore -lt $Thresholds.medium) {
            $riskLevel = "medium"
        } else {
            $riskLevel = "high"
        }
    }
    
    return @{
        "security_score" = [Math]::Round($securityScore, 1)
        "risk_score" = $riskScore
        "risk_level" = $riskLevel
        "total_findings" = $totalFindings
        "severity_breakdown" = @{
            "critical" = $CriticalFindings
            "high" = $HighFindings
            "medium" = $MediumFindings
            "low" = $LowFindings
            "info" = $InfoFindings
        }
    }
}

# Function to analyze security trends
function Get-SecurityTrends {
    param(
        [array]$HistoricalData,
        [int]$MinDataPoints = 2
    )
    
    if ($HistoricalData.Count -lt $MinDataPoints) {
        return @{
            "trend_available" = $false
            "message" = "Insufficient data points for trend analysis"
        }
    }
    
    # Sort by timestamp (newest first)
    $sortedData = $HistoricalData | Sort-Object timestamp -Descending
    
    # Calculate trend over different periods
    $trends = @{
        "trend_available" = $true
        "short_term" = Get-TrendDirection -Data ($sortedData | Select-Object -First 7)  # Last 7 data points
        "medium_term" = Get-TrendDirection -Data ($sortedData | Select-Object -First 14) # Last 14 data points
        "long_term" = Get-TrendDirection -Data $sortedData # All data points
        "velocity" = Get-TrendVelocity -Data ($sortedData | Select-Object -First 5) # Last 5 data points
    }
    
    return $trends
}

# Function to determine trend direction
function Get-TrendDirection {
    param([array]$Data)
    
    if ($Data.Count -lt 2) {
        return @{
            "direction" = "unknown"
            "confidence" = 0
            "change_percent" = 0
        }
    }
    
    $latest = $Data[0]
    $previous = $Data[-1]  # Oldest in the set
    
    $riskChange = $latest.risk_score - $previous.risk_score
    if ($previous.risk_score -gt 0) {
        $changePercent = ($riskChange / $previous.risk_score) * 100
    } else {
        $changePercent = 0
    }
    
    # Determine direction and confidence
    $direction = "stable"
    $confidence = 0
    
    if ([Math]::Abs($changePercent) -gt 5) {
        if ($changePercent -lt 0) {
            $direction = "improving"
        } else {
            $direction = "degrading"
        }
        
        # Calculate confidence based on consistency
        $confidence = Get-TrendConfidence -Data $Data -Direction $direction
    }
    
    return @{
        "direction" = $direction
        "confidence" = $confidence
        "change_percent" = [Math]::Round($changePercent, 2)
        "risk_change" = $riskChange
    }
}

# Function to calculate trend confidence
function Get-TrendConfidence {
    param(
        [array]$Data,
        [string]$Direction
    )
    
    if ($Data.Count -lt 3) {
        return 50  # Low confidence with limited data
    }
    
    $consistentChanges = 0
    $totalChanges = 0
    
    for ($i = 0; $i -lt ($Data.Count - 1); $i++) {
        $current = $Data[$i]
        $next = $Data[$i + 1]
        
        $change = $current.risk_score - $next.risk_score
        $totalChanges++
        
        if ($Direction -eq "improving" -and $change -lt 0) {
            $consistentChanges++
        } elseif ($Direction -eq "degrading" -and $change -gt 0) {
            $consistentChanges++
        }
    }
    
    if ($totalChanges -eq 0) {
        return 0
    }
    
    return [Math]::Round(($consistentChanges / $totalChanges) * 100, 1)
}

# Function to calculate trend velocity
function Get-TrendVelocity {
    param([array]$Data)
    
    if ($Data.Count -lt 2) {
        return @{
            "velocity" = 0
            "acceleration" = 0
            "description" = "Insufficient data"
        }
    }
    
    # Calculate velocity (change per time unit)
    $timeSpan = ($Data[0].timestamp - $Data[-1].timestamp).TotalDays
    $riskChange = $Data[0].risk_score - $Data[-1].risk_score
    
    if ($timeSpan -gt 0) {
        $velocity = $riskChange / $timeSpan
    } else {
        $velocity = 0
    }
    
    # Calculate acceleration if we have enough data points
    $acceleration = 0
    if ($Data.Count -ge 3) {
        $midPoint = [Math]::Floor($Data.Count / 2)
        $recentVelocity = Get-VelocityBetweenPoints -Point1 $Data[0] -Point2 $Data[$midPoint]
        $olderVelocity = Get-VelocityBetweenPoints -Point1 $Data[$midPoint] -Point2 $Data[-1]
        $acceleration = $recentVelocity - $olderVelocity
    }
    
    # Describe velocity
    $description = if ([Math]::Abs($velocity) -lt 0.1) {
        "Stable"
    } elseif ($velocity -lt 0) {
        "Improving"
    } else {
        "Degrading"
    }
    
    return @{
        "velocity" = [Math]::Round($velocity, 3)
        "acceleration" = [Math]::Round($acceleration, 3)
        "description" = $description
        "time_span_days" = [Math]::Round($timeSpan, 1)
    }
}

# Helper function to calculate velocity between two points
function Get-VelocityBetweenPoints {
    param($Point1, $Point2)
    
    $timeSpan = ($Point1.timestamp - $Point2.timestamp).TotalDays
    $riskChange = $Point1.risk_score - $Point2.risk_score
    
    if ($timeSpan -gt 0) {
        return $riskChange / $timeSpan
    } else {
        return 0
    }
}

# Function to generate security recommendations
function Get-SecurityRecommendations {
    param(
        [hashtable]$PostureData,
        [hashtable]$TrendData = @{},
        [hashtable]$CategoryAnalysis = @{},
        [array]$TopIssues = @()
    )
    
    $recommendations = @()
    
    # Risk level based recommendations
    switch ($PostureData.risk_level) {
        "high" {
            $recommendations += "🚨 URGENT: Immediate security review required - high risk level detected"
            $recommendations += "🔒 Implement emergency security controls and monitoring"
            $recommendations += "📋 Conduct security incident response assessment"
        }
        "medium" {
            $recommendations += "⚠️ Schedule security review within 48 hours"
            $recommendations += "🔍 Increase security scanning frequency"
            $recommendations += "📊 Monitor security metrics closely"
        }
        "low" {
            $recommendations += "✅ Maintain current security practices"
            $recommendations += "🔄 Continue regular security monitoring"
            $recommendations += "📈 Look for opportunities to improve security posture"
        }
    }
    
    # Critical findings recommendations
    if ($PostureData.severity_breakdown.critical -gt 0) {
        $recommendations += "🔴 Address $($PostureData.severity_breakdown.critical) critical security finding(s) immediately"
    }
    
    # High findings recommendations
    if ($PostureData.severity_breakdown.high -gt 5) {
        $recommendations += "🟠 Prioritize remediation of $($PostureData.severity_breakdown.high) high-severity issues"
    }
    
    # Trend based recommendations
    if ($TrendData.trend_available) {
        switch ($TrendData.short_term.direction) {
            "degrading" {
                $recommendations += "📉 Security posture is declining - investigate recent changes"
                $recommendations += "🔄 Consider rolling back recent infrastructure changes"
            }
            "improving" {
                $recommendations += "📈 Security posture is improving - document successful practices"
                $recommendations += "🎯 Continue current security improvement initiatives"
            }
        }
        
        if ($TrendData.velocity.acceleration -gt 0.5) {
            $recommendations += "⚡ Security degradation is accelerating - immediate action required"
        }
    }
    
    # Category specific recommendations
    if ($CategoryAnalysis.Count -gt 0) {
        $topCategories = $CategoryAnalysis.GetEnumerator() | 
                        Sort-Object { $_.Value.total } -Descending | 
                        Select-Object -First 3
        
        foreach ($category in $topCategories) {
            if ($category.Value.total -gt 0) {
                switch ($category.Name) {
                    "STORAGE" {
                        $recommendations += "💾 Review storage account security: encryption, access controls, and network restrictions"
                    }
                    "NETWORK" {
                        $recommendations += "🌐 Strengthen network security: NSG rules, private endpoints, and segmentation"
                    }
                    "IDENTITY" {
                        $recommendations += "👤 Enhance identity management: RBAC, Key Vault policies, and authentication"
                    }
                    "ENCRYPTION" {
                        $recommendations += "🔐 Implement comprehensive encryption: at rest, in transit, and key management"
                    }
                    "MONITORING" {
                        $recommendations += "📊 Improve monitoring and logging: diagnostic settings and alerting"
                    }
                    "COMPUTE" {
                        $recommendations += "💻 Secure compute resources: VM configurations and access controls"
                    }
                }
            }
        }
    }
    
    # Top issues recommendations
    if ($TopIssues.Count -gt 0) {
        $criticalIssues = $TopIssues | Where-Object { $_.severity -eq "CRITICAL" } | Select-Object -First 3
        foreach ($issue in $criticalIssues) {
            $recommendations += "🎯 Focus on resolving: $($issue.rule_id) ($($issue.count) occurrences)"
        }
    }
    
    return $recommendations
}

# Function to format security posture for display
function Format-SecurityPosture {
    param(
        [hashtable]$PostureData,
        [string]$Format = "text"
    )
    
    switch ($Format.ToLower()) {
        "text" {
            return @"
Security Score: $($PostureData.security_score)/100
Risk Level: $($PostureData.risk_level.ToUpper())
Risk Score: $($PostureData.risk_score)
Total Findings: $($PostureData.total_findings)
  - Critical: $($PostureData.severity_breakdown.critical)
  - High: $($PostureData.severity_breakdown.high)
  - Medium: $($PostureData.severity_breakdown.medium)
  - Low: $($PostureData.severity_breakdown.low)
"@
        }
        "json" {
            return $PostureData | ConvertTo-Json -Depth 3
        }
        "html" {
            $riskClass = switch ($PostureData.risk_level) {
                "low" { "success" }
                "medium" { "warning" }
                "high" { "danger" }
                default { "info" }
            }
            
            return @"
<div class="security-posture">
    <div class="score-display">
        <span class="score-value">$($PostureData.security_score)</span>
        <span class="score-label">/100</span>
    </div>
    <div class="risk-level $riskClass">$($PostureData.risk_level.ToUpper())</div>
    <div class="findings-breakdown">
        <span class="critical">Critical: $($PostureData.severity_breakdown.critical)</span>
        <span class="high">High: $($PostureData.severity_breakdown.high)</span>
        <span class="medium">Medium: $($PostureData.severity_breakdown.medium)</span>
        <span class="low">Low: $($PostureData.severity_breakdown.low)</span>
    </div>
</div>
"@
        }
        default {
            return $PostureData
        }
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Get-SecurityPostureScore',
    'Get-SecurityTrends',
    'Get-SecurityRecommendations',
    'Format-SecurityPosture'
)