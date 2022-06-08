########## global variables ############
# paths to get items to update
$pagePath = '/sitecore/content/Milwaukee Tool/Home'
$productPagesPath = '/sitecore/content/Milwaukee Tool/Products Repository/North America'
$templates = '/sitecore/templates'

# rendering ids, datasource id, placeholder
$primaryMenuRenderingId = '{3716FC93-4AA0-446D-A75E-05490C23C255}'
$primaryMenuMobileRenderingId = '{5E491119-1478-4299-8A56-DA853F27612D}'
$primaryMenuMobileRenderingPath = '/sitecore/layout/Renderings/Feature/Navigation/Primary Menu Mobile'
$mobileMenuTopRenderingId = '{12CC7B02-3C1D-440D-9A42-B9AEAE97684D}'
$mobileMenuTopRenderingPath = '/sitecore/layout/Renderings/Feature/Navigation/Mobile Menu Top'
$mobileMenuAccountsRenderingId = '{F2D56CAB-FE94-417B-8858-96B9422B0903}'
$mobileMenuAccountsRenderingPath = '/sitecore/layout/Renderings/Feature/Navigation/Mobile Menu Accounts'
$mobileMenuDatasourceId = '{D9154412-D60F-4E38-AFEF-70ADB5D5D7B1}'
#$mobileMenuDatasourcePath = '/sitecore/content/Milwaukee Tool/Global/Components/Menu/Primary Mobile Menu'
$navbarCenterPlaceholder = 'navbar-center'
$navbarCenterMobilePlaceholder = 'navbar-center-mobile'

# setup renderings to add, note cacheable and vary by data
$primaryMenuMobileRenderingInstance = Get-Item -Path $primaryMenuMobileRenderingPath | New-Rendering -Placeholder $navbarCenterPlaceholder
$mobileMenuTopRenderingInstance = Get-Item -Path $mobileMenuTopRenderingPath | New-Rendering -Placeholder $navbarCenterMobilePlaceholder -Cacheable -VaryByData
$mobileMenuAccountsRenderingInstance = Get-Item -Path $mobileMenuAccountsRenderingPath | New-Rendering -Placeholder $navbarCenterMobilePlaceholder

############### main ####################
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

# build list of pages & standard values to update by path and ensuring it has a layout
#$pages = @( Get-Item -Path $pagePath ) + @( Get-ChildItem $pagePath -recurse ) + @( Get-ChildItem $productPagesPath -recurse ) + @( Get-ChildItem $templates -recurse )
#$pages = $pages | Where-Object { (Get-Rendering -Item $_ -FinalLayout) -ne $null }
$pages = Get-ChildItem $templates -recurse | Where-Object { (Get-Rendering -Item $_ -FinalLayout) -ne $null }

# foreach page see if it uses the rendering for primary menu, if so add additional renderings for updated mobile nav
foreach ($page in $pages) {
	$renderings = Get-Rendering -Item $page
	$renderingToDetermineUpdate = $renderings | Where-Object { $_.ItemID -eq $primaryMenuRenderingId }
	if ($renderingToDetermineUpdate.Length -gt 0) {
		Write-Host "updating " $page.Name 
		$primaryMenuMobileRenderingExists = $renderings | Where-Object { $_.ItemID -eq $primaryMenuMobileRenderingId }
		$mobileMenuTopRenderingExists = $renderings | Where-Object { $_.ItemID -eq $mobileMenuTopRenderingId }
		$mobileMenuAccountsRenderingExists = $renderings | Where-Object { $_.ItemID -eq $mobileMenuAccountsRenderingId }
		if ($primaryMenuMobileRenderingExists.Length -eq 0) {
			Write-Host "adding primary menu mobile rendering"
			Add-Rendering -Item $page -Instance $primaryMenuMobileRenderingInstance -Placeholder $navbarCenterPlaceholder
		}
		if ($mobileMenuTopRenderingExists.Length -eq 0) {
			Write-Host "adding mobile menu top rendering"
			Add-Rendering -Item $page -Instance $mobileMenuTopRenderingInstance -Datasource $mobileMenuDatasourceId -Placeholder $navbarCenterMobilePlaceholder
		}
		if ($mobileMenuAccountsRenderingExists.Length -eq 0) {
			Write-Host "adding mobile menu accounts rendering"
			Add-Rendering -Item $page -Instance $mobileMenuAccountsRenderingInstance -Placeholder $navbarCenterMobilePlaceholder
		}
	}
}

Write-Host "------------------------" -f white
Write-Host "End Script" -f green
Write-Host "------------------------" -f white