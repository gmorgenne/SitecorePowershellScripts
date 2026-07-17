Write-Output "Starting"

$MaxAttempts = 10
$WarmUpUrls = @(
    "https://site.co/",
    "https://site.co/pathname"
)

function Invoke-WarmUp {
    param([string]$Url)
    Write-Output "Warming up $Url"
    try {
        $stopwatch = [Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -UseBasicParsing $Url -MaximumRedirection 10
        $stopwatch.Stop()
        $statusCode = [int]$response.StatusCode
        Write-Output "$statusCode Warmed up $Url in $($stopwatch.ElapsedMilliseconds) ms"
    } catch {
        Write-Output "Warm up request failed for $Url"
        $_.Exception | Format-List -Force
    }
}

function Wait-ForUrl {
    param([string]$Url)
    $statusCode = 0
    for ($i = 0; $i -lt $MaxAttempts; $i++) {
        try {
            Write-Output "Checking $Url (attempt $($i + 1)/$MaxAttempts)"
            $stopwatch = [Diagnostics.Stopwatch]::StartNew()
            $response = Invoke-WebRequest -UseBasicParsing $Url -MaximumRedirection 0
            $stopwatch.Stop()
            $statusCode = [int]$response.StatusCode
            Write-Output "$statusCode $Url responded in $($stopwatch.ElapsedMilliseconds) ms"
            if ($statusCode -ge 200 -and $statusCode -lt 400) {
                return $true
            }
        } catch {
            Write-Output "Check failed for $Url"
            $_.Exception | Format-List -Force
        }
        Start-Sleep -Seconds 5
    }
    return $false
}

# Phase 1: Fire warm-up requests for all URLs
Write-Output "`n--- Warm-up Phase ---"
foreach ($url in $WarmUpUrls) {
    Invoke-WarmUp -Url $url
}

# Phase 2: Poll all URLs until they respond successfully
Write-Output "`n--- Health Check Phase ---"
$failedUrls = @()
foreach ($url in $WarmUpUrls) {
    $ok = Wait-ForUrl -Url $url
    if (-not $ok) {
        $failedUrls += $url
    }
}

# Summary
Write-Output "`n--- Summary ---"
if ($failedUrls.Count -eq 0) {
    Write-Output "All URLs warmed up successfully."
} else {
    Write-Output "Warm up FAILED for the following URLs:"
    foreach ($url in $failedUrls) {
        Write-Output "  - $url"
    }
    exit 1
}

Write-Output "Done"