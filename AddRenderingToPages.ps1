########## variables ############
# paths to get items to update
$pagePath = '/sitecore/content/Milwaukee Tool/Home'
$productPagesPath = '/sitecore/content/Milwaukee Tool/Products Repository/North America'
$projectTemplates = '/sitecore/templates/Project/Milwaukee Tool'
$featureTemplates = '/sitecore/templates/Feature'

$renderingToAddPath = "/sitecore/layout/Renderings/Feature/Search/CoveoPageViewAnalytics"
$renderingToAddId = "{9247C892-D270-441D-8625-92AA80A5A7A1}"
$datasourceId = "{A47E2709-A7FC-469B-B8F5-6E362CE38882}" #/sitecore/content/Milwaukee Tool/Global/Global Search Components/Coveo Page View Analytics
$placeholder = "analytics"

# setup rendering to add
$renderingInstance = Get-Item -Path $renderingToAddPath | New-Rendering -Placeholder $placeholder -Cacheable -VaryByData #[ClearOnIndexUpdate|VaryByData|VaryByDevice|VaryByLogin|VaryByParm|VaryByQueryString|VaryByUser]

############### main ####################
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

# build list of pages & standard values to update by path and ensuring it has a layout
$pages = @( Get-Item -Path $pagePath ) + @( Get-ChildItem $pagePath -recurse) + @( Get-ChildItem $productPagesPath -recurse) + @( Get-ChildItem $projectTemplates -recurse) + @( Get-ChildItem $featureTemplates -recurse)
#$pages = @( Get-ChildItem $projectTemplates -recurse) + @( Get-ChildItem $featureTemplates -recurse)
$pages = $pages | Where-Object { (Get-Rendering -Item $_ -FinalLayout) -ne $null }

# foreach page see if it uses the rendering for primary menu, if so add additional renderings for updated mobile nav
foreach ($page in $pages) {
	$renderings = Get-Rendering -Item $page
	$renderingToDetermineUpdate = $renderings | Where-Object { $_.ItemID -eq $renderingToAddId }
	if ($renderingToDetermineUpdate.Length -eq 0) {
		Write-Host "updating " $page.Name
		Add-Rendering -Item $page -Instance $renderingInstance -Datasource $datasourceId -Placeholder $placeholder
	}
}

Write-Host "------------------------" -f white
Write-Host "End Script" -f green
Write-Host "------------------------" -f white