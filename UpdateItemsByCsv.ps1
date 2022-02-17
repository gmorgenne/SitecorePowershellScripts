## upload csv
## parse each row
## find images in media library based on first field, image name
## update alt text & keywords

function Item-Lookup{
	param(
		[Parameter(Mandatory=$true, Position=0)][string]$name
	)
	$criteria = @(@{Filter = "Equals"; Field = "_name"; Value = $name}, @{Filter = "DescendantOf"; Value = (Get-Item "/sitecore/media library") })
	$props = @{
		Index = "sitecore_master_index"
		Criteria = $criteria
	}
	$results = Find-Item @props
	return $results
}

$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

# use sitecore config to find data folder setting
# create folder for \temp\upload if it doesn't exist
# then upload csv
$dataFolder = [Sitecore.Configuration.Settings]::DataFolder
$tempFolder = $dataFolder + "\temp\upload"
$filePath = Receive-File -Path $tempFolder -overwrite

if($filePath -eq "cancel"){
    exit
}

$resultSet =  Import-Csv $filePath

$rowsCount = ($resultSet | Measure-Object).Count

if($rowsCount -le 0){
	Write-Host "No data in file or file not found"
    Remove-Item $filePath
    exit
}

foreach ($row in $resultSet) {
	$fileName = $row.Filename
	$altText = $row.AltText
	$keywords = $row.Keywords
	Write-Host "Find: " $fileName " and add alt text: " $altText " and keywords: " $keywords
	$foundItems = Item-Lookup $fileName
	#$foundItemsCount = ($foundItems | Measure-Object).Count
	foreach ($foundItem in $foundItems) {
		$updateItem = Get-Item $foundItem.ItemId
		Write-Host "Updating this item: " $updateItem.Name " in this path: " $updateItem.Paths.Path
		$updateItem.Editing.BeginEdit()
		$updateItem.Fields["Alt"].Value = $altText
		$updateItem.Fields["Keywords"].Value = $keywords
		$updateItem.Editing.EndEdit()
	}
}

Remove-Item $filePath
$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white