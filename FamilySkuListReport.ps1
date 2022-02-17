# Script for listing super sku child skus

class Product
{
	[String] $DisplayName
	[String] $SKU
	[String] $ItemId
	[String] $Path
	[String] $SkuList
}

$products = Get-ChildItem -Path 'master://sitecore/content/Milwaukee Tool/Products Repository/North America' -Recurse 
$Results = New-Object Collections.Generic.List[Product]

$accFamilyTemplate = "{3F911AA6-6C99-4D21-8645-581FD0A41359}"
$gearFamilyTemplate = "{6C2F5441-1E78-496C-BF2F-3943460519A9}"
$glovesTemplate = "{F251C6B4-E199-4606-BF1A-8FC83ED6E3AD}"
$handToolFamilyTemplate = "{765630F3-FB93-4CF2-AF6C-DE7087DDED27}"

foreach($product in $products) {
    $template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($product)
	
	if ($template.InheritsFrom($accFamilyTemplate) -or $template.InheritsFrom($gearFamilyTemplate) -or $template.InheritsFrom($glovesTemplate) -or $template.InheritsFrom($handToolFamilyTemplate)) {
		$skuList = ''
		$children = Get-ChildItem -Path $product.Paths.FullPath -Recurse
		foreach($child in $children) {
			$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($product)
			if ($template.InheritsFrom("{A819D3F6-DD02-47DD-9897-5BA714E39152}") -and $child.Fields["SKU"].Length -gt 0) { #base product
				$skuList += '|' + $child.Fields["SKU"]
			}
		}
		if ($skuList.Length -gt 0) {
			$p = New-Object Product
			$p.DisplayName = $product.DisplayName
			$p.SKU = $product.Fields["SKU"]
			$p.ItemId = $product.ID
			$p.Path = $product.Paths.FullPath
			$p.SkuList = $skuList
			$Results.Add($p)
		}
	}
}

if ($Results.Count -gt 0) {
	$props = @{
        Title = "Family Sku List"
        PageSize = 25
    }
	$Results | 
		Show-ListView @props -Property @{Label="Name"; Expression={$_.DisplayName} },
		@{Label="ID"; Expression={$_.ItemId} },
		@{Label="SKU"; Expression={$_.SKU} },
		@{Label="SkuList"; Expression={$_.SkuList} },
		@{Label="Path"; Expression={$_.Path} }
}