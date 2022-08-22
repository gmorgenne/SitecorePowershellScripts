<#
	.SYNOPSIS
        import items from csv
	.DESCRIPTION
        upload csv file, process each row, add/update items from csv data
	.NOTES
		Geoff Morgenne
#>

Import-Function "Import-FromCsv"
Import-Function "Write-LogExtended"

######################################################################

# setup variables
[System.IO.Directory]::CreateDirectory("$apppath\App_Data\temp\")
$logDate = $(Get-Date).toString("yyyy_MM_dd-HH-mm-ss")
$logFileName = "news-importer-$logDate.log"
$logFile = "$apppath\App_Data\temp\$logFileName"

$destinationPath = Get-Item -Path "master:/sitecore/content/test"
$selectedTemplate = Get-Item -Path "master:/sitecore/templates/Sample/Sample Item"

######################################################################

$StartTime = $(get-date)
Write-LogExtended $logFile "------------------------" white
Write-LogExtended $logFile "Begin CSV Import - Start Time: $StartTime" green
Write-LogExtended $logFile "------------------------" white

# upload csv, build list of columns in the csv for use when mapping csv columns to sitecore fields
$resultSet = Import-FromCsv
if (-not($resultSet)) { exit }
$resultCount = ($resultSet | Measure-Object).Count
Write-LogExtended $logFile "found $resultCount records from csv"
$columnNames = $resultSet | Get-Member -MemberType NoteProperty | Where-Object { "Name", "Id" -notcontains $_.Name } | Select-Object -ExpandProperty Name
$sourceFieldNames = $columnNames | ForEach-Object { $mappings = [ordered]@{} } { $mappings[$_] = $_ } { $mappings }
$csvOptions = [ordered]@{"-- Skip --" = ""} + $sourceFieldNames
Write-LogExtended $logFile "columns in csv: $columnNames" gray

# setup prompt for destination to create items if they don't exist
$pathTemplatePrompt = @{
	Parameters  = @(
		@{ Name = "destinationPath"; Title = "Choose the path to import items"; }
		@{ Name = "selectedTemplate"; Title = "Confim the template to use for creating items"; }
	)
	Title       = "CSV Import Wizard - Destination & Template"
	Description = "Select destination and template to use."
	Width       = 800
	Height      = 500
	Icon        = "Office/32x32/astrologer.png"
}
$pathTemplateResult = Read-Variable @pathTemplatePrompt
if ($pathTemplateResult -eq "cancel") { exit }
Write-LogExtended $logFile "destination path selected: $($destinationPath.ItemPath) 
template selected: $($selectedTemplate.Name)"

# Create a list of field names on the Standard Template. This will help us filter out extraneous fields.
$standardTemplate = Get-Item -Path "master:" -ID "{1930BBEB-7805-471A-A3BE-4858AC7CF696}"
$standardTemplateTemplateItem = [Sitecore.Data.Items.TemplateItem]$standardTemplate
$standardFields = $standardTemplateTemplateItem.OwnFields + $standardTemplateTemplateItem.Fields | Select-Object -ExpandProperty key -Unique

# build fields list from template fields to map csv columns
$selectedTemplateItem = [Sitecore.Data.Items.TemplateItem]$selectedTemplate
$templateFields = $selectedTemplateItem.Fields | Where-Object { $standardFields -notcontains $_.Name } | Sort-Object
Write-LogExtended $logFile "template fields: $($templateFields | ForEach-Object { $_.Name })" darkgray

# setup prompt for template fields to csv column mapping
$fieldMappingPrefix = "fieldMapping-"
$mappingParameters = @()
$mappingParameters += @{ Name = "info"; Title = "Field Mapping"; Value = "Each label indicates a <b>$($selectedTemplateItem.Name)</b> Template field. Choose from the dropdown of CSV columns to map to the field."; Editor = "info" }
foreach ($templateField in $templateFields) {
	$mappingParameters += @{ Name = "$($fieldMappingPrefix)$($templateField.Name)"; Title = "$($templateField.Name)"; Options = $csvOptions; Value = "$($templateField.Name)"; Columns = 2; }
}
$mappingPrompt = @{
	"Parameters"   = $mappingParameters
	"Title"        = "Resource Import Wizard - Mapping"
	"Description"  = "Map fields from $($selectedTemplateItem.Name) Template to CSV columns."
	"OkButtonName" = "Next"
	Width          = 1600
	Height         = 800
	Icon           = "Office/32x32/astrologer.png"
}
$mappingResult = Read-Variable @mappingPrompt
if ($mappingResult -eq "cancel") { exit }
$fieldMappings = Get-Variable -Name "$($fieldMappingPrefix)*" | Where-Object { $_.Value } | ForEach-Object { $mappings = [ordered]@{} } { $mappings[$_.Name.Replace($fieldMappingPrefix, "")] = $_.Value } { $mappings }
Write-LogExtended $logFile "field mappings have been set: $($fieldMappings.Keys | ForEach-Object { "$($_): $($fieldMappings[$_])"  })" cyan

# then create or update items
New-UsingBlock (New-Object Sitecore.Data.BulkUpdateContext) {
	foreach ($result in $resultSet) {
		# TODO: lookup result to see if it's an add or update
		$item = $null
		if ($item -eq $null) {
			$title = $result.Title
			$itemPath = "$($destinationPath.ItemPath)/$title"
			$item = New-Item -Path $itemPath -ItemType $selectedTemplate.ID
			$item.Editing.BeginEdit()
			foreach ($fieldMapping in $fieldMappings.Keys) {
				$csvFieldName = $fieldMappings[$fieldMapping]
				$fieldValue = $result.$csvFieldName
				# check field type to determine how to set the value
				$field = $selectedTemplateItem.Fields | Where-Object { $_.Name -eq $fieldMapping }
				Write-LogExtended $logFile "field mapping: $fieldMapping, template field: $($field.Name), field type: $($field.Type)"
				switch ($field.Type) {
					"Checkbox" {
						Write-LogExtended $logFile "field is a checkbox, attempt to determine value"
					}
					"Droplink" {
						Write-LogExtended $logFile "field is a droplink, attempt to lookup value"
					}
					"Droptree" {
						Write-LogExtended $logFile "field is a droptree, attempt to lookup value"
					}
					"General Link" {
						Write-LogExtended $logFile "field is a general link, attempt to build value"
					}
					"Image" {
						Write-LogExtended $logFile "field is an image, attempt to lookup value"
					}
					"Integer" {
						Write-LogExtended $logFile "field is an integer, attempt to determine value"
					}
					"Multilist" {
						Write-LogExtended $logFile "field is a multilist, attempt to lookup value"
					}
					"Treelist" {
						Write-LogExtended $logFile "field is a treelist, attempt to lookup value"
					}
					default {
						Write-LogExtended $logFile "set $fieldMapping to value of field $csvFieldName from csv: $fieldValue" gray green
						$item.$fieldMapping = $fieldValue
					}
				}
			}
			$item.Editing.EndEdit()
			Write-LogExtended $logFile "[A] create new item for $title" green
		}
		else {
			Write-LogExtended $logFile "[U] update itemfor $title" yellow
		}
	}
}

#########################################################################

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-LogExtended $logFile "------------------------" white
Write-LogExtended $logFile "End CSV Import - Total time: $totalTime" green
Write-LogExtended $logFile "------------------------" white

$stream = New-Object System.IO.StreamReader($logFile)
Out-Download -InputObject $stream.BaseStream -Name $logFileName
Remove-Item $logFile
######################################################################