# Find all instances of a rendering    
# Change it's dynamic placeholder

########## global variables ############
# paths to get items to update
$searchPath = '/sitecore/content/Milwaukee Tool/Home'

# rendering id to search for to build dynamic placeholder
# (this is the rendering that has the dynamic placeholder)
$renderingToFind = '{9571F606-30E4-455A-9911-CCE1329F3905}'

# rendering id to update
$rendering = ''
$datasourceID = ''

# placeholder key to replace existing placeholder key
# (this will be the beginning of the dynamic placeholder)
$placeholderKey = 'body-scripts'

############### main ####################
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$pages = @( Get-Item -Path $pagePath ) + @( Get-ChildItem $pagePath -recurse ) + @( Get-ChildItem $productPagesPath -recurse ) + @( Get-ChildItem $templates -recurse )

foreach ($page in $pages) {
	$renderings = Get-Rendering -Item $page
	$renderingToUpdate = $renderings | Where-Object { $_.ItemID -eq $rendering }
	if ($renderingToUpdate.Length -gt 0) {
		Write-Host "updating " $page.Name 
		
		#find rendering to find's unique id for building dynamic placeholder
		$renderingToFindInstance = $renderings | Where-Object { $_.ItemID -eq $renderingToFind }
		if ($renderingToFindInstance.Length -gt 0) {
			$rUniqueId = $renderingToFindInstance[0].UniqueId
			$placeholderKey += "-$($rUniqueId)-0"
			Write-Host "recommendations result template placeholder: " $placeholderKey
			#	Add-Rendering -Item $page -Instance $recommendationsResultRendering -Datasource $datasourceID -Placeholder $placeholderKey
		} else {
			Write-Host "rendering not on page, placeholder can't be calculated"
		}
	}
}

Write-Host "------------------------" -f white
Write-Host "End Script" -f green
Write-Host "------------------------" -f white