function Write-LogExtended {
    param(
        [string]$logFilePath,
        [string]$Message,
        [System.ConsoleColor]$ForegroundColor = $host.UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$BackgroundColor = $host.UI.RawUI.BackgroundColor
    )
    $stamp = $(Get-Date).toString("yyyy_MM_dd-HH-mm-ss")
    Add-Content $logFilePath -Value "$stamp $message"
    Write-Host $message -ForegroundColor $ForegroundColor -BackgroundColor $backgroundColor
}