# Find all instances of a rendering    
# change the placeholder               

########## global variables ############
# paths to get items to update
$searchPath = '/sitecore/content/Milwaukee Tool/Home'

# rendering guid for Coveo Search Resources
$rendering = '{9571F606-30E4-455A-9911-CCE1329F3905}'

# placeholder key to replace existing placeholder key with
$placeholderKey = 'body-scripts'

############### main ####################
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$pages = @( Get-ChildItem $searchPath -recurse )

foreach ($page in $pages) {
	$renderings = Get-Rendering -Item $page
	$renderingToUpdate = $renderings | Where-Object { $_.ItemID -eq $rendering }
	if ($renderingToUpdate.Length -gt 0) {
		Write-Host "updating " $page.Name 
		$renderingToUpdate.Placeholder = $placeholderKey
		Set-Rendering -Item $page -Instance $renderingToUpdate
	}
}

Write-Host "------------------------" -f white
Write-Host "End Script" -f green
Write-Host "------------------------" -f white