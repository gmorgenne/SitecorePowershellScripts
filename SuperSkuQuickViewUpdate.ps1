### get list of all products that inherit from accessory family, hand tool family, gear, or glove
### if variant list in quick view, remove it
### if product has variant filter, variant options, or hand tool list -> add that rendering to quick view
### written 11-16-2020

########## global variables ############
# paths to get items to update
$productPagesPath = '/sitecore/content/Milwaukee Tool/Products Repository/North America'
#$productPagesPath = '/sitecore/templates'

# devices
$DefaultDevice = Get-Item '/sitecore/layout/Devices/Default'
$QuickViewDevice = Get-Item '/sitecore/layout/Devices/Quick View'

# lists
$AccessoryFamilies = New-Object Collections.Generic.List[Sitecore.Data.Items.Item]
$GearProducts = New-Object Collections.Generic.List[Sitecore.Data.Items.Item]
$GlovesProducts = New-Object Collections.Generic.List[Sitecore.Data.Items.Item]
$HandToolFamilies = New-Object Collections.Generic.List[Sitecore.Data.Items.Item]

# placeholder key to set new rendering
$placeholderKey = 'product-split-details'

# renderings to look for
$HandToolFamilyItemList = "{C9B01A2F-6A07-479B-AE84-ACDC28DF0040}"
$ProductVariantFilter = "{FF38E484-E38C-4BC9-B823-E390142B00B6}"
$ProductVariantList = "{27188139-1AB6-4810-BD83-D6759FAF733B}"
$ProductVariantOptions = "{6ADE08C1-6711-484A-917E-06C0589D6F00}"

# set up new renderings to add
$HandToolFamilyItemListRendering = Get-Item -Path '/sitecore/layout/Renderings/Feature/Products/HandToolFamilyItemList' | New-Rendering -Placeholder $placeholderKey
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
    if ($template.InheritsFrom("{3F911AA6-6C99-4D21-8645-581FD0A41359}")) { #accessory families
		$AccessoryFamilies.Add($product)
	}
	if ($template.InheritsFrom("{6C2F5441-1E78-496C-BF2F-3943460519A9}")) { #gear families
		$GearProducts.Add($product)
	}
	if ($template.InheritsFrom("{F251C6B4-E199-4606-BF1A-8FC83ED6E3AD}")) { #gloves
		$GlovesProducts.Add($product)
	}
	if ($template.InheritsFrom("{765630F3-FB93-4CF2-AF6C-DE7087DDED27}")) { #hand tool families
		$HandToolFamilies.Add($product)
	}
}

foreach ($acc in $AccessoryFamilies) {
	$qvRenderings = Get-Rendering -Item $acc -Device $QuickViewDevice
	$renderingToRemove = $qvRenderings | Where-Object { $_.ItemID -eq $ProductVariantList }
	if ($renderingToRemove.Length -gt 0) {
		Write-Host "updating " $acc.Name " removing variant list"
		Remove-Rendering -Item $acc -Instance $renderingToRemove -Device $QuickViewDevice
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

foreach ($glove in $GlovesProducts) {
	$renderings = Get-Rendering -Item $glove -Device $DefaultDevice -FinalLayout
	$qvRenderings = Get-Rendering -Item $glove -Device $QuickViewDevice
	$renderingToRemove = $qvRenderings | Where-Object { $_.ItemID -eq $ProductVariantList }
	if ($renderingToRemove.Length -gt 0) {
		Write-Host "updating " $glove.Name " removing variant list"
		Remove-Rendering -Item $glove -Instance $renderingToRemove -Device $QuickViewDevice
	}
	$variantOptionsRendering = $renderings | Where-Object { $_.ItemID -eq $ProductVariantOptions }
	$variantOptionsQuickViewRendering = $qvRenderings | Where-Object { $_.ItemID -eq $ProductVariantOptions }
	if ($variantOptionsRendering.Length -gt 0 -and $variantOptionsQuickViewRendering.Length -eq 0) {
		Write-Host "updating " $glove.Name " adding variant options"
		Add-Rendering -Item $glove -Instance $ProductVariantOptionsRendering -Placeholder $placeholderKey -Device $QuickViewDevice
	} elseif ($variantOptionsQuickViewRendering.Length -gt 1) {
		Write-Host $glove.name "has more than 1 variant option rendering in quick view"
	}
	$variantFilterRendering = $renderings | Where-Object { $_.ItemID -eq $ProductVariantFilter }
	$variantFilterQuickViewRendering = $qvRenderings | Where-Object { $_.ItemID -eq $ProductVariantFilter }
	if ($variantFilterRendering.Length -gt 0 -and $variantFilterQuickViewRendering.Length -eq 0) {
		Write-Host "updating " $glove.Name " adding variant filter"
		Add-Rendering -Item $glove -Instance $ProductVariantFilterRendering -Placeholder $placeholderKey -Device $QuickViewDevice
	} elseif ($variantFilterQuickViewRendering.Length -gt 1) {
		Write-Host $glove.name "has more than 1 variant filter rendering in quick view"
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
	} elseif ($variantOptionsQuickViewRendering.Length -gt 1) {
		Write-Host $ht.name "has more than 1 variant option rendering in quick view"
	}
	$variantFilterRendering = $renderings | Where-Object { $_.ItemID -eq $ProductVariantFilter }
	$variantFilterQuickViewRendering = $qvRenderings | Where-Object { $_.ItemID -eq $ProductVariantFilter }
	if ($variantFilterRendering.Length -gt 0 -and $variantFilterQuickViewRendering.Length -eq 0) {
		Write-Host "updating " $ht.Name " adding variant filter"
		Add-Rendering -Item $ht -Instance $ProductVariantFilterRendering -Placeholder $placeholderKey -Device $QuickViewDevice
	} elseif ($variantFilterQuickViewRendering.Length -gt 1) {
		Write-Host $ht.name "has more than 1 variant filter rendering in quick view"
	}
	$handToolItemListRendering = $renderings | Where-Object { $_.ItemID -eq $HandToolFamilyItemList }
	$handToolItemListQuickViewRendering = $qvRenderings | Where-Object { $_.ItemID -eq $HandToolFamilyItemList }
	if ($handToolItemListRendering.Length -gt 0 -and $handToolItemListQuickViewRendering.Length -eq 0) {
		Write-Host "updating " $ht.Name " adding hand tool item list"
		Add-Rendering -Item $ht -Instance $HandToolFamilyItemListRendering -Placeholder $placeholderKey -Device $QuickViewDevice
	} elseif ($handToolItemListQuickViewRendering.Length -gt 1) {
		Write-Host $ht.name "has more than 1 hand tool item list rendering in quick view"
	}
}

Write-Host "------------------------" -f white
Write-Host "End Script" -f green
Write-Host "------------------------" -f white