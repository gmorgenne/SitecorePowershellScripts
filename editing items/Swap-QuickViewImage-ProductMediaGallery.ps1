########################################
# swap quick view image with           #
# product media gallery                #
#                                      #
# written 12-17-20                     #
########################################

########## global variables ############
# paths to get items to update
$pagePath = '/sitecore/content/Milwaukee Tool/Home'
$productPagesPath = '/sitecore/content/Milwaukee Tool/Products Repository/North America'
$projectTemplatesPath = '/sitecore/templates/Project'
$featureTemplatesPath = '/sitecore/templates/Feature'

#device
$QuickViewDevice = Get-Item '/sitecore/layout/Devices/Quick View'

# rendering guid for quick view
$rendering = '{6A4A4554-899D-44C1-8AC1-AADDB868375F}'

#product media gallery
$mediaGalleryRendering = '{5624157E-FD8E-4028-8A7A-ABBB56D0C18C}'
$mediaGalleryRenderingPath = '/sitecore/layout/Renderings/Feature/Products/ProductMediaGallery'
$mediaGalleryPlaceholder = 'product-split-featured'
$mediaGalleryRenderingInstance = Get-Item -Path $mediaGalleryRenderingPath | New-Rendering -Placeholder $mediaGalleryPlaceholder

############### main ####################
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$pages = @( Get-Item -Path $pagePath ) + @( Get-ChildItem $pagePath -recurse ) + @( Get-ChildItem $productPagesPath -recurse ) + @( Get-ChildItem $projectTemplatesPath -recurse ) + @( Get-ChildItem $featureTemplatesPath -recurse )

foreach ($page in $pages) {
	$renderings = Get-Rendering -Item $page -Device $QuickViewDevice
	$renderingToUpdate = $renderings | Where-Object { $_.ItemID -eq $rendering }
	if ($renderingToUpdate.Length -gt 0) {
		Write-Host "updating " $page.Name $page.Paths.Path
		Remove-Rendering -Item $page -Instance $renderingToUpdate -Device $QuickViewDevice
		$mediaGalleryExists = $renderings | Where-Object { $_.ItemID -eq $mediaGalleryRendering }
		if ($mediaGalleryExists.Length -eq 0) {
			Write-Host "adding product media gallery to " $page.Name
			Add-Rendering -Item $page -Instance $mediaGalleryRenderingInstance  -Placeholder $mediaGalleryPlaceholder -Device $QuickViewDevice
		}
	}
}

Write-Host "------------------------" -f white
Write-Host "End Script" -f green
Write-Host "------------------------" -f white