#	change template by specific template & path

$searchPath = '/sitecore/content/Milwaukee Tool/Products Repository/North America/Accessories/Miscellaneous/Black Iron Press Jaws'
#$searchPath = '/sitecore/content/Milwaukee Tool/Products Repository/North America/Accessories/Miscellaneous/Press Tool Jaws and Rings'
#$searchPath = '/sitecore/content/Milwaukee Tool/Products Repository/North America/Power Tools/Cordless/Press Tools'

$templateToChange = '{DEB4CE12-23EF-416E-8189-DF876CE5AF0C}' #Accessory
$newTemplatePath = '/sitecore/templates/Project/Milwaukee Tool/Product Types/Accessories/Press Tool Accessory'

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$pages = @( Get-ChildItem $searchPath -recurse )
#$pages = $pages | Where-Object { (Get-Rendering -Item $_ -FinalLayout) -ne $null }

foreach($page in $pages) {
	$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($page)
	
	if ($template.InheritsFrom($templateToChange)) { #Accessory
		Write-Host "Changing template for " $page.Name
		#Set-ItemTemplate -Path $page.Paths.Path -Template $newTemplatePath
	}
}

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################