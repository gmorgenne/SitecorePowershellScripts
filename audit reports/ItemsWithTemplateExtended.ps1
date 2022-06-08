<#
	.SYNOPSIS
        Lists all content items that inherit from a given template by path
		Includes all fields provided template defines
		
	.NOTES
		Alex Washtell
		Geoff Morgenne
#>
$selectedTemplate = Get-Item master:\templates
$root = Get-Item -Path "/sitecore/content"

$prompt = @{
    Parameters = @(
        @{ Name="root"; Title="Choose the report root"; Tooltip="Only items from this path will be returned."; }
        @{ Name = "selectedTemplate"; Title="Base Template"; Tooltip="Select the item to use as a base template for the report"; Root="/sitecore/templates/"}
    )
    Title = "Items With Template Extended Report"
    Description = "Choose the criteria for the report."
    Width = 550
    Height = 300
    ShowHints = $true
    Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

$result = Read-Variable @prompt

if($result -eq "cancel") {
    exit
}

###################################################################### 

function BaseTemplateList{

}

function CountLinks{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item
	)
	$links = $item | Get-ItemReferrer
	return $links.length
}

function Template-Check{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item
	)
	if ($item) {
		$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item)
		if ($template.InheritsFrom($selectedTemplate.ID)) {
			return $item
		}
	}
}

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

# build default field export list: name, ID, path, count of places that item is used
$fields = '@{Label="Name"; Expression={$_.Name} }, @{Label="ItemId"; Expression={$_.ID} }, @{Label="Path"; Expression={$_.Paths.FullPath} }, @{ Label="Uses"; Expression={CountLinks $_ } }, '

# build export fields list from template fields:
$selectedTemplateItem = [Sitecore.Data.Items.TemplateItem]$selectedTemplate
$templateFields = $selectedTemplateItem.Fields | Where-Object { -not $_.Name.StartsWith("__") }
foreach ($field in $templateFields) {
	$fields += '@{ Label = "' + $field.Name + '"; Expression = { $_.Fields["' + $field.Name + '"] }; },'
}
$fields = $fields.Substring(0, $fields.Length - 1)
$fieldsConverted = Invoke-Expression $fields
$props = @{
    Title = "Item Template Report"
    InfoTitle = "Items that inherit from the '$($selectedTemplate.Name)' template"
    InfoDescription = "The following items all inherit from the '$($selectedTemplate.FullPath)' template."
    PageSize = 50
}
$items = Get-ChildItem -path $root.Paths.Path -Recurse | Where-Object { Template-Check $_ }
$items | Show-ListView @props -Property $fieldsConverted

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################