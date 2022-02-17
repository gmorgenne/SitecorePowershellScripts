# take a csv of brightcove to vimeo mappings
# build a hash table of mapping data
# get items that inherit _video template
# foreach item get brightcove video id from item, lookup vimeo id, update vimeo field

$videoTemplatePath = "/sitecore/templates/Foundation/Models/Videos/_Video"
$videoTemplateId = "{888294CB-89E6-4D7F-A778-B6763BD831A2}"

function Filter-Items{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item
	}
	
	$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item)
	if ($template.InheritsFrom($templateId)) {
		return $item
	}
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

# build hash table from csv data
$lookup = @{}
foreach ($row in $resultSet) {
	$brightcoveId = $row.Brightcove
	$vimeoId = $row.Vimeo
	$lookup.Add($brightcoveId, $vimeoId)
	Write-Host "Add dictionary item for brightcove id: " $brightcoveId " and vimeo id: " $vimeoId
}

Write-Host "lookup table: " $lookup

# find items that inherit _video 
$foundItems = @(Get-ChildItem -Path "/sitecore/content" -Recurse) + @(Get-ChildItem -Path "/sitecore/media library/Product Videos" -Recurse) | Where-Object { Filter-Items $_ }
foreach ($foundItem in $foundItems) {
	#$updateItem = Get-Item $foundItem.ItemId
	Write-Host "Updating this item: " $updateItem.Name " in this path: " $updateItem.Paths.Path
	
	# TODO: here's the tricky bit...
	# microsoft doc: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7.2
	# have to figure out what this item's brightcove video id is, which you could probably write a function for?
	# another tricky element here is that some things could have 2 brightcove video id fields... (I know the product detail promo does, but I don't think anything else does...)
	# then look it up in the $lookup table to get it's vimeo counterpart
	# then you can do something like this:
	#$brightcoveId = $foundItem.Fields["Brightcove Video ID"]
	#$vimeoId = $lookup.$brightcoveId
	
	#$updateItem.Editing.BeginEdit()
	#$updateItem.Fields["Vimeo Video ID"].Value = $vimeoId
	#$updateItem.Editing.EndEdit()
}

Remove-Item $filePath
$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white