### get list of all products that inherit from variant
### if variant list in quick view, remove it
### if product has variant filter, variant options, or hand tool list -> add that rendering to quick view
### written 03-19-2021

########## global variables ############
# paths to get items to update
$productPagesPath = '/sitecore/content/Milwaukee Tool/Products Repository/North America'
#$productPagesPath = '/sitecore/content/Milwaukee Tool/Products Repository/North America/Gear/Heated Gear/Heated Jackets'
#$productPagesPath = '/sitecore/templates'

# devices
$DefaultDevice = Get-Item '/sitecore/layout/Devices/Default'
$QuickViewDevice = Get-Item '/sitecore/layout/Devices/Quick View'

# lists
$GearProducts = New-Object Collections.Generic.List[Sitecore.Data.Items.Item]

# placeholder key to set new rendering
$placeholderKey = 'product-split-details'

# renderings to look for
$ProductVariantFilter = "{FF38E484-E38C-4BC9-B823-E390142B00B6}"
$ProductVariantList = "{27188139-1AB6-4810-BD83-D6759FAF733B}"
$ProductVariantOptions = "{6ADE08C1-6711-484A-917E-06C0589D6F00}"

# set up new renderings to add
$ProductVariantFilterRendering = Get-Item -Path '/sitecore/layout/Renderings/Feature/Products/ProductVariantFilter' | New-Rendering -Placeholder $placeholderKey
$ProductVariantOptionsRendering = Get-Item -Path '/sitecore/layout/Renderings/Feature/Products/ProductVariantOptions' | New-Rendering -Placeholder $placeholderKey
#########################################

############### main ####################
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$products = Get-ChildItem $productPagesPath -Recurse

foreach($product in $products) {
    $template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($product)
	if ($template.InheritsFrom("{20452D9A-31C3-4B8C-9D5E-8F54224D9A23}")) { #variant
		$GearProducts.Add($product)
	}
}

foreach ($gear in $GearProducts) {
	$renderings = Get-Rendering -Item $gear -Device $DefaultDevice -FinalLayout
	$qvRenderings = Get-Rendering -Item $gear -Device $QuickViewDevice
	$renderingToRemove = $qvRenderings | Where-Object { $_.ItemID -eq $ProductVariantList }
	if ($renderingToRemove.Length -gt 0) {
		Write-Host "updating " $gear.Name " removing variant list"
		Remove-Rendering -Item $gear -Instance $renderingToRemove -Device $QuickViewDevice
	}
	$variantOptionsRendering = $renderings | Where-Object { $_.ItemID -eq $ProductVariantOptions }
	$variantOptionsQuickViewRendering = $qvRenderings | Where-Object { $_.ItemID -eq $ProductVariantOptions }
	if ($variantOptionsRendering.Length -gt 0 -and $variantOptionsQuickViewRendering.Length -eq 0) {
		Write-Host "updating " $gear.Name " adding variant options"
		Add-Rendering -Item $gear -Instance $ProductVariantOptionsRendering -Placeholder $placeholderKey -Device $QuickViewDevice
	} elseif ($variantOptionsQuickViewRendering.Length -gt 1) {
		Write-Host $gear.name "has more than 1 variant option rendering in quick view"
	}
	$variantFilterRendering = $renderings | Where-Object { $_.ItemID -eq $ProductVariantFilter }
	$variantFilterQuickViewRendering = $qvRenderings | Where-Object { $_.ItemID -eq $ProductVariantFilter }
	if ($variantFilterRendering.Length -gt 0 -and $variantFilterQuickViewRendering.Length -eq 0) {
		Write-Host "updating " $gear.Name " adding variant filter"
		Add-Rendering -Item $gear -Instance $ProductVariantFilterRendering -Placeholder $placeholderKey -Device $QuickViewDevice
	} elseif ($variantFilterQuickViewRendering.Length -gt 1) {
		Write-Host $gear.name "has more than 1 variant filter rendering in quick view"
	}
}

Write-Host "------------------------" -f white
Write-Host "End Script" -f green
Write-Host "------------------------" -f white