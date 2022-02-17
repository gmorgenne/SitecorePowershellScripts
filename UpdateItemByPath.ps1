# find children of provided path that inherit template
# update particular field
######################################################################

# update these: 
$searchPath = "/sitecore/content/Milwaukee Tool/Products Repository/North America/Safety/Personal Protection Equipment/Vests"
$template = "{366698BE-EC46-453C-A27D-6CB14DFCEA3D}" # safety gear
$field = "Configurable"
$value = "1"

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$foundItems = Get-ChildItem $searchPath -Recurse

foreach ($foundItem in $foundItems) {
	$foundItemTemplate = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($foundItem)
	if ($foundItemTemplate.InheritsFrom($template)) { 
		Write-Host "Updating this item: " $foundItem.Name " field: " $field " value: " $value " in this path: " $foundItem.Paths.Path
		#$foundItem.Editing.BeginEdit()
		#$foundItem.Fields[$field].Value = $value
		#$foundItem.Editing.EndEdit()
	}
}

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################