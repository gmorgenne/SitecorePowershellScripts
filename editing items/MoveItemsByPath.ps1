<#
    .Synopsis
        Move items from one item to another
    .Description
        shows a prompt to provide options for how to move items
        options include filtering items by name or template
    .Notes
        if name is selected, template filter is not applied
#>
$sourcePath = Get-Item -Path "/sitecore/content"
$destinationPath = Get-Item -Path "/sitecore/content"
$where = "" #this is optional and looks at item name
$selectedTemplate = Get-Item master:\templates
$byName = $false
$byTemplate = $false
$auditMode = $true

$prompt = @{
	Parameters = @(
		@{ Name="sourcePath"; Title="Choose the source to copy"; Tooltip="Only items from this path will be copied."; }
		@{ Name="destinationPath"; Title="Choose the destination"; Tooltip="Items will be copied to this path."; }
		@{ Name="nameInfo"; Title="Filter items by name"; Editor="info" }
		@{ Name="byName"; Title="By Name"; Tooltip="If selected, items will be filtered by name."; Columns="2 first"; }
		@{ Name="where"; Title="Matching Name"; Tooltip="Only items with this value in the name will be copied."; Columns="8 last"; }
		@{ Name="templateInfo"; Title="Filter items by template"; Editor="info" }
		@{ Name="byTemplate"; Title="By Template"; Tooltip="If selected, items will be filtered by template."; Columns="2 first"; }
		@{ Name="selectedTemplate"; Title="Base Template"; Tooltip="Select the template to find items to copy."; Root="/sitecore/templates/"; Columns="8 last"; }
		@{ Name="auditMode"; Title="Audit Mode"; Tooltip="If selected, no items will be copied and output will be a log of what would happen." }
	)
	Title = "Move Items"
	Description = "Select source and destination path."
	Width = 550
	Height = 500
	ShowHints = $true
	Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

$result = Read-Variable @prompt

if ($result -eq "cancel") {
	exit
}

######################################################################

function Filter-Items{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item
	)
	if ($byName) {
		if ($item.Name.Contains($where)) {
			return $item
		}
	}
	elseif ($byTemplate) {
		$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item)
		if ($template.InheritsFrom($selectedTemplate.ID)) {
			return $item
		}
	}
	else { return $item }
}

######################################################################

$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

if ($auditMode) {
	Get-ChildItem -Path $sourcePath.Paths.Path -Recurse | Where-Object { Filter-Items $_ } | foreach-object { Write-Host "Item[AUDIT MODE]:  $($_.Name) will be copied to $($destinationPath.Paths.Path)/$($_.Name) " }
}
else {
	Get-ChildItem -Path $sourcePath.Paths.Path -Recurse | Where-Object { Filter-Items $_ } | foreach-object { Write-Host "Item: $($_.Name) moved."; Move-Item -Path $_.Paths.Path -Destination $destinationPath.Paths.Path }
}

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################