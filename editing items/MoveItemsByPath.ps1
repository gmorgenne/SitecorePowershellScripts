# Move item by path, by template or name
$sourcePath = "/sitecore/content/Global/Configuration/Horizontal Alignments"
$destinationPaths = "/sitecore/content/Global/Configuration/Vertical Alignments"
$where = "" #this is optional and looks at item name
$byName = $false
$byTemplate = $false
$auditMode = $true

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
		if ($template.InheritsFrom($where)) {
			return $item
		}
	}
	else { return $item }
}

Write-Host "script starting..."
if ($auditMode) {
	$items = Get-ChildItem -Path $pathToItems -Recurse | Where-Object { Filter-Items $_ } | foreach-object { Write-Host "Item[AUDIT MODE]: " $_.Name; }
}
else {
	$items = Get-ChildItem -Path $pathToItems -Recurse | Where-Object { Filter-Items $_ } | foreach-object { Write-Host "Item: " $_.Name; Move-Item -Path $_.Paths.Path -Destination $pathToMove }
}
Write-Host "script finished"