<#
    .SYNOPSIS
        finds items with provided text in any field
    .DESCRIPTION
        shows a prompt, lets the content author pick a root to search in
        creates a list of items that contain the provided text in the search root
        generates report to work from or export
    .NOTES
        Version:        1.0
        Author:         Geoff Morgenne
#>

$fieldRequiredValidator = {
    if ([string]::IsNullOrEmpty($variable.Value)) {
        $variable.Error = "Please provide a value."
    }
}

$dialogProps = @{
    Parameters       = @(
        @{ Name = "searchRoot"; Title = "Search Root"; Tooltip = "The starting point when performing a search."; Source = "Datasource=/sitecore/content/"; editor = "droptree"; },
        @{ Name = "fieldValue"; Value = ""; Title = "Search Text"; Tooltip = "The value to search for"; Placeholder = "Search String"; Columns = 12; Validator = $fieldRequiredValidator; }
    )
    Description      = "This report allows you to search the item fields for particular text and display the results"
    Title            = "Search for Text"
    Width            = 700
    Height           = 575
    OkButtonName     = "Proceed"
    CancelButtonName = "Abort"
    ShowHint         = $true
    Icon             = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}
    
$result = Read-Variable @dialogProps
        
if ($result -ne "ok") {
    Exit
}

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white
    
$foundItems = @($searchRoot) + @(Get-ChildItem -Path $searchRoot.Paths.FullPath -Recurse | Initialize-Item)
[System.Collections.ArrayList]$reportItems = @()
foreach ($currentItem in $foundItems) {
    Get-ItemField -Item $currentItem -ReturnType Field -Name $fieldName | ForEach-Object {
        $originalValue = $_.Value
        if ($originalValue -match $fieldValue) {
            $reportItems.Add($currentItem)
        }  
    }
}
    
$reportProps = @{
    Property        = @(
        "ID", "Name", "ItemPath", "Language", "Version"
    )
    Title           = "Find Text Report - $($fieldValue)"
    InfoTitle       = "Report Details"
    InfoDescription = "The following report shows items found with the specified text: $($fieldValue)."
}
$reportItems | Show-ListView @reportProps
Close-Window

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################