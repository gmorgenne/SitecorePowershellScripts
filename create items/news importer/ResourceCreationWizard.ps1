<#
    .SYNOPSIS
        creates news and events items via a wizard UI
	.DESCRIPTION
        wizard for creating items
	.NOTES
		Geoff Morgenne
#>

######################################################################

$selectedTemplate = Get-Item -Path "master:/sitecore/templates/Feature/CCG/Resources/Resource"

######################################################################

$parentItem = Get-Item -Path .

# show a prompt to pick news or event
$newItemType = $newItemName = ""
$typeOptions = @{
    "News"  = "News"
    "Event" = "Event"
}
$typePrompt = @{
    Parameters  = @(
        @{ Name = "newItemType"; Title = "Choose the type of item to create"; Options = $typeOptions; Value = "Type of item to create:"; }
        @{ Name = "newItemName"; Title = "Provide a name for the new item"; Value = "" }
    )
    Title       = "Resource Wizard - Select Type"
    Description = "Select type of item to create."
    Width       = 400
    Height      = 400
    Icon        = "Office/32x32/astrologer.png"
}
$typeResult = Read-Variable @typePrompt
if ($typeResult -eq "cancel") { exit }

$newItemPath = "$($parentItem.Paths.Path)/$newItemName"
Write-Host "create type: $newItemType at $newItemPath"

# clean proposed item name, search for item, if not found create item
$cleanedNewItemName = [Sitecore.Data.Items.ItemUtil]::ProposeValidItemName($newItemName)
$criteria = @(
    @{ Filter = "Equals"; Field = "_latestversion"; Value = "1"; }, 
    @{ Filter = "Equals"; Field = "_templatename"; Value = "Resource"; }, 
    @{ Filter = "DescendantOf"; Value = $parentItem; },
    @{ Filter = "Equals"; Field = "OpenGraphTitle"; Value = $cleanedNewItemName; }
)
$queryProps = @{
    Index    = "sitecore_master_index"
    Criteria = $criteria
}
$findItemResult = Find-Item @queryProps
if ($findItemResult) {
    $existingItem = $findItemResult.GetItem()
    Write-Host "An item with that name already exists: $($existingItem.ID)"
    exit
}
Write-Host "Item doesn't exist, so create a new one."
$newItem = New-Item -Path $newItemPath -ItemType $selectedTemplate.ID
$fields = @(
    "ResourcePostDate",
    "ResourceExpireDate",
    "ResourceTitle",
    "ResourceTeaser",
    "ResourceBody",
    "ResourceImage",
    "ResourceSites",
    "ResourceTags",
    "ResourceAuthor",
    "ResourceAudience"
)
if ($newItemType -eq "Event") {
    $newItem.Editing.BeginEdit() 
    $newItem["ResourceType"] = "{40755284-ECE8-439F-842C-CCA7E137E5D1}"
    $newItem.Editing.EndEdit()
    $eventFields = @(
        "EventStartDate",
        "EventEndDate",
        "EventLocation",
        "EventCity",
        "EventStateProvince",
        "EventCountry",
        "EventUrl",
        "ExternalEvent"
    )
    $fields += $eventFields
}

Show-FieldEditor -Path $newItem.Paths.Path -Name $fields -Title "Edit New Item Fields" -Width 600 -Height 800 -PreserveSections

Write-Host "new item: $($newItem.ID)"

# publish item
