#############
# finds items without references
# attempts delete
###############

function HasReference {
    param(
        $Item
    )

    $linkDb = [Sitecore.Globals]::LinkDatabase
    $linkDb.GetReferrerCount($Item) -gt 0
}

function GetItemsWithoutReferences {
	$items = Get-ChildItem -Path "master:/sitecore/content/WebKiosk/Home/HD" -Recurse | Where-Object { $_.TemplateName -notmatch "Folder" }
	#$items = Get-ChildItem -Path "master:/sitecore/content/WebKiosk/Global" -Recurse | Where-Object { $_.TemplateName -notmatch "Folder" }
	foreach($item in $items) {
		if(!(HasReference($item))) {
			$item
			#Remove-Item -Path $item.ItemPath
		}
	}
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