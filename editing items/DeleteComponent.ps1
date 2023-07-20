# rendering guid for email signup
$renderingID = "{TH15FAK3-GUID-W1LL-N0T4-MA773R0RW0RK}"
$templatePath = "/sitecore/templates/Feature/Company/CoolFeature1/GarbageComponent"
$renderingToDelete = Get-Item "/sitecore/layout/Renderings/Feature/Company/CoolFeature1/GarbageComponent"
$templateToDelete = Get-Item $templatePath
$pages = @($conversionRendering | Get-ItemReferrer)
$datasources = @($templateToDelete | Get-ItemReferrer)

############### main ####################
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

Write-Host "Remove renderings from pages"
foreach ($page in $pages) {
	$renderings = Get-Rendering -Item $page
	$renderingToUpdate = $renderings | Where-Object { $_.ItemID -eq $renderingID }
	if ($renderingToUpdate.Length -gt 0) {
		Write-Host "    removing rendering from " $page.Name $page.Paths.Path
		Remove-Rendering -Item $page -Instance $renderingToUpdate
	}
}

Write-Host "Deleting data sources"
foreach ($datasource in $datasources) {
    if ($datasource.Paths.Path.StartsWith("/sitecore/content")) {
        Write-Host "    deleting datasource: " $datasource.Name $datasource.Paths.Path
        $datasource | Remove-Item
    }
}

Write-Host "Deleting rendering"
$renderingToDelete | Remove-Item

Write-Host "Deleting template"
Get-ChildItem -Path $templatePath -recurse | Remove-Item
$templateToDelete | Remove-Item

Write-Host "------------------------" -f white
Write-Host "End Script" -f green
Write-Host "------------------------" -f white