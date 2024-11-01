<#
	.SYNOPSIS
        Lists all content items that inherit from a given template by path
		Includes all fields provided template defines
	.DESCRIPTION
        shows a prompt that can be used to pick a root path and a base template
		the root path is used to find items in that path
		the base template is used to:
			filter the items by that template
			build an output of the fields included in the report
	.NOTES
		based on ItemsWithTemplate by Alex Washtell shipped in SPE Module
		updated by Geoff Morgenne for enhanced output
#>

$root = Get-Item -Path "master:\content"
$selectedTemplate = Get-Item "master:\templates"

######################################################################

# show a prompt to pick the path to search for items
# and the template to use to filter items and build the output
$prompt = @{
    Parameters = @(
        @{ Name="root"; Title="Choose the report root"; Tooltip="Only items from this path will be returned."; Root="/sitecore/content" }
        @{ Name = "selectedTemplate"; Title="Base Template"; Tooltip="Select the template to find items and output fields for the report"; Root="/sitecore/templates/" }
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

function CountLinks{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item
	)
	$links = $item | Get-ItemReferrer
	return $links.length
}

function TemplateCheck{
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

# Create a list of field names on the Standard Template. This will help us filter out extraneous fields.
$standardTemplate = Get-Item -Path "master:" -ID "{1930BBEB-7805-471A-A3BE-4858AC7CF696}"
$standardTemplateTemplateItem = [Sitecore.Data.Items.TemplateItem]$standardTemplate
$standardFields = $standardTemplateTemplateItem.OwnFields + $standardTemplateTemplateItem.Fields | Select-Object -ExpandProperty key -Unique

# build export fields list from template fields:
$selectedTemplateItem = [Sitecore.Data.Items.TemplateItem]$selectedTemplate
$templateFields = $selectedTemplateItem.Fields | Where-Object { $standardFields -notcontains $_.Name }
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
$items = Get-ChildItem -Path "master:$($root.Paths.Path)" -Recurse | Where-Object { TemplateCheck $_ }
$items | Show-ListView @props -Property $fieldsConverted

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################