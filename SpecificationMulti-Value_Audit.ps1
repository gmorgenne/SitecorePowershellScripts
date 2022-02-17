# get all specification multi-value fields
# then, audit unique display/actual values per fields 
#Get-ChildItem -Path "/sitecore/templates" -Recurse | Where-Object {$_.Fields["{AB162CC0-DC80-4ABF-8871-998EE5D7BA32}"] -like "specification multi-value"} | Show-ListView -Property FullPath, Id
#Get-ChildItem -Path "/sitecore/templates" -Recurse | Where-Object {$_.Fields["{AB162CC0-DC80-4ABF-8871-998EE5D7BA32}"] -like "specification multi-value"} | Show-ListView -Property Name

#$searchPath = "/sitecore/content/Milwaukee Tool/Products Repository/North America"
$searchPath = "/sitecore/content/Milwaukee Tool/Products Repository/North America/Accessories/Drilling/Carbide Hammer Drill Bits/Carbide Hammer Drill Bits"

######################################################################

function Convert-Field-Value{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][String]$value
	)
	
	if ($value) {
		$parseValue = [Sitecore.Web.WebUtil]::ParseUrlParameters($value);
		$actual = $parseValue["Actual"]
		$display = $parseValue["Display"]
		return "Display= " + $display + ", Actual= " + $actual
	} else {
		return "N/A"
	}
}

function Template-Check{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item,
		[Parameter(Mandatory=$true, Position=1)][Collections.Generic.List[String]]$templateIds
	)
	
	$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item)
	foreach ($id in $templateIds) {
		if ($template.InheritsFrom($id)) {
			return $item
		}
	}
}

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white


$fields = '@{Label="Name"; Expression={$_.Fields["Title"]} }, @{Label="SKU"; Expression={$_.Fields["SKU"]} }, @{Label="ItemId"; Expression={$_.ID} }, @{Label="Path"; Expression={$_.Paths.FullPath} }, '
$templateIds = New-Object Collections.Generic.List[String]
$specMVFields = Get-ChildItem "/sitecore/templates" -Recurse | Where-Object {$_.Fields["{AB162CC0-DC80-4ABF-8871-998EE5D7BA32}"] -like "specification multi-value"}
foreach ($field in $specMVFields) {
	# build export fields list
	$fields += '@{ Label = "' + $field.Name + '"; Expression = { Convert-Field-Value $_.Fields["' + $field.Name + '"] }; },'
	# build list of template ids
	$section = $field.Parent
	$template = $section.Parent
	$templateId = $template.ID
	if (!$templateIds.Contains($templateid)) {
	    $templateIds.Add($templateId)
	}
}

$products = Get-ChildItem -Path $searchPath -Recurse | Where-Object { Template-Check $_ $templateIds }

$fields = $fields.Substring(0, $fields.Length - 1)
$fieldsConverted = Invoke-Expression $fields
$props = @{
    Title = "Specification Multi-Value Report"
    PageSize = 50
}
$products | Show-ListView @props -Property $fieldsConverted


$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################