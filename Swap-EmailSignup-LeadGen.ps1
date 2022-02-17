########################################
# swap email signup with lead gen      #
#                                      #
#                                      #
# written 12-17-20                     #
########################################

########## global variables ############
# paths to get items to update
$pagePath = '/sitecore/content/Milwaukee Tool/Home'
$productPagesPath = '/sitecore/content/Milwaukee Tool/Products Repository/North America'
$projectTemplatesPath = '/sitecore/templates/Project'
$featureTemplatesPath = '/sitecore/templates/Feature'

# rendering guid for email signup
$rendering = '{E4274F52-1E87-42F0-B890-F4B202C7C9C9}'

#lead gen 
$leadGenRendering = '{91112F55-EECA-41C2-8813-C5E9CB794DDB}'
$leadGenRenderingPath = '/sitecore/layout/Renderings/Feature/Components/Forms/LeadGenPopUp'
$leadGenDatasource = '{7CEBDF13-6956-4F75-B16C-01593EBCB4B9}'
#$leadGenDatasourcePath = '/sitecore/content/Milwaukee Tool/Global/Components/Forms/Lead Gen Pop Up Form'
$leadGenPlaceholder = 'page-content'
$leadGenRenderingInstance = Get-Item -Path $leadGenRenderingPath | New-Rendering -Placeholder $leadGenPlaceholder

############### main ####################
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$pages = @( Get-Item -Path $pagePath ) + @( Get-ChildItem $pagePath -recurse ) + @( Get-ChildItem $productPagesPath -recurse ) + @( Get-ChildItem $projectTemplatesPath -recurse ) + @( Get-ChildItem $featureTemplatesPath -recurse )

foreach ($page in $pages) {
	$renderings = Get-Rendering -Item $page
	$renderingToUpdate = $renderings | Where-Object { $_.ItemID -eq $rendering }
	if ($renderingToUpdate.Length -gt 0) {
		Write-Host "updating " $page.Name $page.Paths.Path
		Remove-Rendering -Item $page -Instance $renderingToUpdate
		$leadGenExists = $renderings | Where-Object { $_.ItemID -eq $leadGenRendering }
		if ($leadGenExists.Length -eq 0) {
			Write-Host "adding lead gen to " $page.Name
			Add-Rendering -Item $page -Instance $leadGenRenderingInstance -Datasource $leadGenDatasource -Placeholder $leadGenPlaceholder
		}
	}
}

Write-Host "------------------------" -f white
Write-Host "End Script" -f green
Write-Host "------------------------" -f white