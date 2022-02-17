
class ComboKit
{
	[String] $Title
	[String] $SKU
	[String] $ItemId
	[String] $Path
	[String] $ProductSkus
	[String] $ProductTitles
}

$comboKits = Get-Item "/sitecore/templates/Project/Milwaukee Tool/Product Types/Combo Kit" | Get-ItemReferrer
$results = New-Object Collections.Generic.List[ComboKit]
foreach ($comboKit in $comboKits) {
	$productsField = [Sitecore.Data.Fields.MultilistField]$comboKit.Fields["Products"]
	$products = $productsField.GetItems()
	$skus = ""
	$titles = ""
	foreach ($product in $products) {
		$skus = $skus + $product.Fields["SKU"] + ", "
		$titles = $titles + $product.Fields["Title"] + ", "
	}
	$k = New-Object ComboKit
	$k.Title = $comboKit.Fields["Title"]
	$k.SKU = $comboKit.Fields["SKU"]
	$k.ItemId = $comboKit.ID
	$k.Path = $comboKit.Paths.FullPath
	$k.ProductSkus = $skus.Substring(0, $skus.Length - 1)
	$k.ProductTitles = $titles.Substring(0, $titles.Length - 1)
	$results.Add($k)
}
$props = @{
        Title = "Combo Kit Report"
        PageSize = 25
    }
$results | Show-ListView @props -Property @{Label="Name"; Expression={$_.Title} }, 
    @{Label="SKU"; Expression={$_.SKU} },
    @{Label="ItemId"; Expression={$_.ItemId} },
    @{Label="Path"; Expression={$_.Path} },
    @{Label="ProductSkus"; Expression={$_.ProductSkus} },
    @{Label="ProductTitles"; Expression={$_.ProductTitles} }