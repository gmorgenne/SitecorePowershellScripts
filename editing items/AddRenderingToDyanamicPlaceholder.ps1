
# path to get items to update
#$searchPath = "/sitecore/templates"
#$searchPath = "/sitecore/content/Milwaukee Tool/Home"
#$searchPath = "/sitecore/content/Milwaukee Tool/Products Repository/North America"
$searchPath = "/sitecore/content/Milwaukee Tool/Home/thd-Packout"
$renderingToAddPath = "/sitecore/layout/Renderings/Feature/Search/FacetValueSuggestions"
$renderingIdToFind = "{2356A970-CFDE-473D-9568-51FEF1290B64}" # Global Search Box
$datasourceId = "{49879AF1-2A92-417D-86B7-D1B4317A45A4}"
$basePlaceholder = "searchbox-components"
$renderingToAdd = Get-Item -Path $renderingToAddPath | New-Rendering

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$pages = @( Get-ChildItem $searchPath -recurse) 
$pages = $pages | Where-Object { (Get-Rendering -Item $_ -FinalLayout) -ne $null }

foreach ($page in $pages) {
	$renderings = Get-Rendering -Item $page
	$renderingsToDetermineUpdate = $renderings | Where-Object { $_.ItemID -eq $renderingIdToFind }
	if ($renderingsToDetermineUpdate.Length -gt 1) {
		foreach ($renderingToDetermineUpdate in $renderingsToDetermineUpdate) {
			$renderingUniqueId = $renderingToDetermineUpdate.UniqueId
			$placeholder = "$($basePlaceholder)-$($renderingUniqueId)-0"
			Write-Host $page.Paths.FullPath " add rendering to dynamic placeholder " $placeholder
			#Add-Rendering -Item $page -Instance $renderingToAdd -Datasource $datasourceId -Placeholder $placeholder
		}
	}
}

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################