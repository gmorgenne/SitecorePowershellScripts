$productPagesPath = '/sitecore/content/Milwaukee Tool/Products Repository/North America'
$QuickViewDevice = Get-Item '/sitecore/layout/Devices/Quick View'
$GlovesProducts = New-Object Collections.Generic.List[Sitecore.Data.Items.Item]
$ProductVariantFilter = "{FF38E484-E38C-4BC9-B823-E390142B00B6}"
$ProductVariantOptions = "{6ADE08C1-6711-484A-917E-06C0589D6F00}"
$ProductVariantOptionsRendering = Get-Item -Path '/sitecore/layout/Renderings/Feature/Products/ProductVariantOptions' | New-Rendering -Placeholder $placeholderKey
$placeholderKey = 'product-split-details'

Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$products = Get-ChildItem $productPagesPath -Recurse

foreach($product in $products) {
    $template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($product)
	if ($template.InheritsFrom("{F251C6B4-E199-4606-BF1A-8FC83ED6E3AD}")) { #gloves
		$GlovesProducts.Add($product)
	}
}

foreach ($glove in $GlovesProducts) {
	$qvRenderings = Get-Rendering -Item $glove -Device $QuickViewDevice
	$variantOptionsRendering = $qvRenderings | Where-Object { $_.ItemID -eq $ProductVariantOptions }
	$variantFilterQuickViewRendering = $qvRenderings | Where-Object { $_.ItemID -eq $ProductVariantFilter }
	if ($variantOptionsRendering.Length + $variantFilterQuickViewRendering.Length -eq 0) {
		Write-Host $glove.Name " adding variant options"
		Add-Rendering -Item $glove -Instance $ProductVariantOptionsRendering -Placeholder $placeholderKey -Device $QuickViewDevice

	}
}


Write-Host "------------------------" -f white
Write-Host "End Script" -f green
Write-Host "------------------------" -f white