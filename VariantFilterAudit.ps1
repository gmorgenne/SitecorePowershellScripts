# variant filter audit
# find product by path
# audit children of product based on variant filters
# requires variant filters to exist and path to be the super sku page

$searchPath = '/sitecore/content/Milwaukee Tool/Products Repository/North America'
#$searchPath = '/sitecore/content/Milwaukee Tool/Products Repository/North America/Safety/Personal Protection Equipment/Vests/Class-3-High-Visibility-Mesh-Safety-Vest'

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$foundItems = Get-ChildItem $searchPath -Recurse
$variantFilters = $foundItems | Where-Object { $_.TemplateID -eq "{5DEEB615-8032-4259-8ABB-07F22CDF3472}" }
$products = $foundItems | Where-Object { Is-Product $_ }
$fields = '@{Label="Name"; Expression={$_.Fields["Title"]} }, @{Label="SKU"; Expression={$_.Fields["SKU"]} }, @{Label="ItemId"; Expression={$_.ID} }, @{Label="Path"; Expression={$_.Paths.FullPath} }, '
foreach($filter in $variantFilters) {
	$field = $filter.Fields["Field Name"]
	Write-Host "filter field found: " $field
	$fields += '@{ Label = "'+$field+'"; Expression = { $_.Fields["'+$field+'"] }; },'
}
$fields = $fields.Substring(0, $fields.Length - 1)
$fieldsConverted = Invoke-Expression $fields
$props = @{
    Title = "Product Variant Filter Report"
    PageSize = 50
}
$products | Show-ListView @props -Property $fieldsConverted

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################

function Is-Product{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$product
	)
	
	$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($product)
    if ($template.InheritsFrom("{A819D3F6-DD02-47DD-9897-5BA714E39152}")) { #base product
		return $product
	}
}