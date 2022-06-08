# powershell script to move datasources to global:
#	- call to action grid container
#	- full control authoring
#	- innovations promos
#	- product detail promos
#	- promos
#	- section headers
#	
#create global folders for:
#	- product 360s?
#	- usp texts?
#	- banners? (hero header banner)
#	- logo title usp
#	- image galleries
	
$fullControlAuthoringGlobalFolder = "/sitecore/content/WebKiosk/Global/Components/Full Control Authoring"
$innovationPromosGlobalFolder = "/sitecore/content/WebKiosk/Global/Components/Innovations Promos"
$productDetailPromoGlobalFolder = "/sitecore/content/WebKiosk/Global/Components/Product Detail Promos"
$promosGlobalFolder = "/sitecore/content/WebKiosk/Global/Components/Promos"
$sectionHeadersGlobalFolder = "/sitecore/content/WebKiosk/Global/Components/Section Headers"

$itemsToMove = Get-ChildItem -Path "/sitecore/content/WebKiosk/Home/HD" -Recurse

foreach ($item in $itemsToMove) {
	if ($item.TemplateName -eq "Full Control Authoring") {
		Write-Host "Moving Item: " $item.Name " to global Full Control Authoring folder"
		Move-Item -Path $item.Paths.FullPath -Destination $fullControlAuthoringGlobalFolder
	}
	if ($item.TemplateName -eq "InnovationsPromo") {
		Write-Host "Moving Item: " $item.Name " to global InnovationsPromo folder"
		Move-Item -Path $item.Paths.FullPath -Destination $innovationPromosGlobalFolder
	}
	if ($item.TemplateName -eq "ProductDetailPromo") {
		Write-Host "Moving Item: " $item.Name " to global ProductDetailPromo folder"
		Move-Item -Path $item.Paths.FullPath -Destination $productDetailPromoGlobalFolder
	}
	if ($item.TemplateName -eq "Promo") {
		Write-Host "Moving Item: " $item.Name " to global Promos folder"
		Move-Item -Path $item.Paths.FullPath -Destination $promosGlobalFolder
	}
	if ($item.TemplateName -match "Section Header") {
		Write-Host "Moving Item: " $item.Name " to global Section Headers folder"
		Move-Item -Path $item.Paths.FullPath -Destination $sectionHeadersGlobalFolder
	}
}