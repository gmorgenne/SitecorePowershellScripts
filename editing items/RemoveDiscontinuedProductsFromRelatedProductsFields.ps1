# rip through discontinued items and replace them as related products

$productPagesPath = '/sitecore/content/Milwaukee Tool/Products Repository/North America'


Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$products = Get-ChildItem $productPagesPath -Recurse

foreach($product in $products) {
	$productPath = $product.Paths.FullPath
	$productId = $product.Id
	$referredItems = Get-Item $productPath | Get-ItemReferrer
	
	foreach($referredItem in $referredItems) {
		# assume it's referredItem because it's in the related product/accessory field
		
		$relatedProducts = $referredItem.Fields["Related Products"]
		$replace = $relatedProducts -match $productId
		if ($replace -eq "True") {
			Write-Host "removing stuff from:  " $referredItem.DisplayName
			$newRelatedProducts = $relatedProducts -replace $productId
			$referredItem.Editing.BeginEdit()
			$referredItem.Fields["Related Products"].Value = $relatedProducts -replace $productId
			$referredItem.Editing.EndEdit()
		}
	}
}

Write-Host "------------------------" -f white
Write-Host "End Script" -f green
Write-Host "------------------------" -f white