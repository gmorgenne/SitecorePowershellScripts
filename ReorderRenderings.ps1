### swap order of two renderings
### written 11-20-2020
### need to find all items that reference product filters and where to buy, make sure filters is below where to buy

########## global variables ############
# paths to get items to update
$productPagesPath = 'master:/sitecore/content/Milwaukee Tool/Products Repository/North America'
#$productPagesPath = 'master:/sitecore/templates'

# devices
$DefaultDevice = Get-Item 'master:/sitecore/layout/Devices/Default'
$QuickViewDevice = Get-Item 'master:/sitecore/layout/Devices/Quick View'



# placeholder key to set new rendering
$placeholderKey = 'product-split-details'

# renderings to look for
$HandToolFamilyItemList = "{C9B01A2F-6A07-479B-AE84-ACDC28DF0040}"
$ProductFilters = "{51BE663F-7DCD-4700-B5B0-46044E52E18F}"
$ProductVariantFilter = "{FF38E484-E38C-4BC9-B823-E390142B00B6}"
$ProductVariantList = "{27188139-1AB6-4810-BD83-D6759FAF733B}"
$ProductVariantOptions = "{6ADE08C1-6711-484A-917E-06C0589D6F00}"
$ProductWhereToBuy = "{01DDBFCD-9BC9-444C-B9CD-C77E02F767F3}"

# set up new renderings to add
$HandToolFamilyItemListRendering = Get-Item -Path 'master:/sitecore/layout/Renderings/Feature/Products/HandToolFamilyItemList' | New-Rendering -Placeholder $placeholderKey
$ProductVariantFilterRendering = Get-Item -Path 'master:/sitecore/layout/Renderings/Feature/Products/ProductVariantFilter' | New-Rendering -Placeholder $placeholderKey
$ProductVariantOptionsRendering = Get-Item -Path 'master:/sitecore/layout/Renderings/Feature/Products/ProductVariantOptions' | New-Rendering -Placeholder $placeholderKey
#########################################

############### main ####################
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$products = Get-Item -Path 'master:/sitecore/layout/Renderings' -ID $ProductFilters | 
    Get-ItemReferrer | Where-Object { $_.ContentPath.StartsWith($productPagesPath) }
	
foreach($product in $products) {
# turn this into a function perhaps? findIndexOfRendering($product, $rendering)
$renderings = Get-Rendering -Item $product -Device $DefaultDevice
$qvRenderings = Get-Rendering -Item $product -Device $QuickViewDevice

$i=0
$index = 0
$renderings | ForEach-Object {
    $i++
    if($_.ItemID -eq $rendering) {
        $index = i
        Break
    }
  }	
}




foreach ($ht in $HandToolFamilies) {
	$renderings = Get-Rendering -Item $ht -Device $DefaultDevice -FinalLayout
	$qvRenderings = Get-Rendering -Item $ht -Device $QuickViewDevice
	$renderingToRemove = $qvRenderings | Where-Object { $_.ItemID -eq $ProductVariantList }
	if ($renderingToRemove.Length -gt 0) {
		Write-Host "updating " $ht.Name " removing variant list"
		Remove-Rendering -Item $ht -Instance $renderingToRemove -Device $QuickViewDevice
	}
	$variantOptionsRendering = $renderings | Where-Object { $_.ItemID -eq $ProductVariantOptions }
	$variantOptionsQuickViewRendering = $qvRenderings | Where-Object { $_.ItemID -eq $ProductVariantOptions }
	if ($variantOptionsRendering.Length -gt 0 -and $variantOptionsQuickViewRendering.Length -eq 0) {
		Write-Host "updating " $ht.Name " adding variant options"
		Add-Rendering -Item $ht -Instance $ProductVariantOptionsRendering -Placeholder $placeholderKey -Device $QuickViewDevice
	}
	$variantFilterRendering = $renderings | Where-Object { $_.ItemID -eq $ProductVariantFilter }
	$variantFilterQuickViewRendering = $qvRenderings | Where-Object { $_.ItemID -eq $ProductVariantFilter }
	if ($variantFilterRendering.Length -gt 0 -and $variantFilterQuickViewRendering.Length -eq 0) {
		Write-Host "updating " $ht.Name " adding variant filter"
		Add-Rendering -Item $ht -Instance $ProductVariantFilterRendering -Placeholder $placeholderKey -Device $QuickViewDevice
	}
	$handToolItemListRendering = $renderings | Where-Object { $_.ItemID -eq $HandToolFamilyItemList }
	$handToolItemListQuickViewRendering = $qvRenderings | Where-Object { $_.ItemID -eq $HandToolFamilyItemList }
	if ($handToolItemListRendering.Length -gt 0 -and $handToolItemListQuickViewRendering.Length -eq 0) {
		Write-Host "updating " $ht.Name " adding hand tool item list"
		Add-Rendering -Item $ht -Instance $HandToolFamilyItemListRendering -Placeholder $placeholderKey -Device $QuickViewDevice
	}
}






Write-Host "------------------------" -f white
Write-Host "End Script" -f green
Write-Host "------------------------" -f white