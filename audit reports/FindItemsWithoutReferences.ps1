<#
    .SYNOPSIS
        finds items without references
    .DESCRIPTION
        uses the link manager to find any references to items, outputs unreferenced items.
        can toggle audit mode to remove unneeded items
    .NOTES
        Version:        1.0
        Author:         Geoff Morgenne
#>

$auditMode = $true

function HasReference {
    param(
        $Item
    )

    $linkDb = [Sitecore.Globals]::LinkDatabase
    $linkDb.GetReferrerCount($Item) -gt 0
}

function GetItemsWithoutReferences {
	$items = Get-ChildItem -Path "master:/sitecore/content" -Recurse | Where-Object { $_.TemplateName -notmatch "Folder" }
	foreach($item in $items) {
		if(!(HasReference($item))) {
			$item
            if (!$auditMode) {
                Remove-Item -Path $item.ItemPath
            }
		}
	}
}

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

if ($auditMode) {
    Write-Host "NOTE: This script is running in audit mode. Update $auditMode bool to act on removing these items."
}

# output items without links
$props = @{
    InfoTitle = "Unused items"
    InfoDescription = "Lists all items that are not linked to other items."
    PageSize = 25
}

GetItemsWithoutReferences | Show-ListView @props -Property @{Label="Name"; Expression={$_.DisplayName} },
    @{Label="Template ID"; Expression={$_.TemplateID } },
    @{Label="Template Name"; Expression={$_.TemplateName } },
    @{Label="Path"; Expression={$_.ItemPath} }

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################