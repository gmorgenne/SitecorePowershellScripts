# rendering guid for email signup
$rendering = '{E4274F52-1E87-42F0-B890-F4B202C7C9C9}'
$pages = @(Get-Item "/sitecore/layout/Renderings/Feature/Components/Forms/EmailSignup" | Get-ItemReferrer)

############### main ####################
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white
foreach ($page in $pages) {
	$renderings = Get-Rendering -Item $page
	$renderingToUpdate = $renderings | Where-Object { $_.ItemID -eq $rendering }
	if ($renderingToUpdate.Length -gt 0) {
		Write-Host "updating " $page.Name $page.Paths.Path
		Remove-Rendering -Item $page -Instance $renderingToUpdate
	}
}
Write-Host "------------------------" -f white
Write-Host "End Script" -f green
Write-Host "------------------------" -f white