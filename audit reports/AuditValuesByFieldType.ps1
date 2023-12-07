# modify as needed
$searchPath = "/sitecore/content"
$featureTemplateSearchPath = "/sitecore/templates/Feature"
$foundationTemplateSearchPath = "/sitecore/templates/Foundation"
$fieldType = "General Link"
$exportFields = '@{Label="Name"; Expression={$_.Name} }, @{Label="ItemId"; Expression={$_.ID} }, @{Label="Path"; Expression={$_.Paths.FullPath} }, '

# constants, don't change
$fieldTypeID = "{AB162CC0-DC80-4ABF-8871-998EE5D7BA32}"
$templateIds = New-Object Collections.Generic.List[String]
$fieldList = New-Object Collections.Generic.List[String]
$resultItemList = New-Object Collections.Generic.List[Sitecore.Data.Items.Item]

######################################################################

function FieldValue-Check{
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item,
		[Parameter(Mandatory=$true, Position=1)][String]$field
	)
	$value = $item.Fields[$field]
	if ($value -and $value.Value.Length -gt 0) {
	    #Write-Host "    check value of $($item.Name) - $($field) field: $($value) which is of length: $($value.Value.Length)"
	    return $value
	}
	return $null
}

function Template-Check{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item,
		[Parameter(Mandatory=$true, Position=1)][Collections.Generic.List[String]]$templateIds
	)
	
	$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item)
	foreach ($id in $templateIds) {
		if ($template.InheritsFrom($id)) {
			return $item
		}
	}
}

######################################################################

$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

# Create a list of field names on the Standard Template. This will help us filter out extraneous fields.
$standardTemplate = Get-Item -Path "master:" -ID "{1930BBEB-7805-471A-A3BE-4858AC7CF696}"
$standardTemplateTemplateItem = [Sitecore.Data.Items.TemplateItem]$standardTemplate
$standardFields = $standardTemplateTemplateItem.OwnFields + $standardTemplateTemplateItem.Fields | Select-Object -ExpandProperty key -Unique

$templateFields = (Get-ChildItem $featureTemplateSearchPath -Recurse) + (Get-ChildItem $foundationTemplateSearchPath -Recurse)
$foundFields = $templateFields | Where-Object { $_.Fields[$fieldTypeID] -like $fieldType -and $standardFields -notcontains $_.Name }
foreach ($field in $foundFields) {
    #add field to list for export
	$exportFields += '@{ Label = "' + $field.Name + '"; Expression = { $_.Fields["' + $field.Name + '"] }; },'
	$fieldList.Add($field.Name)
	#Write-Host "new export field: $($field.Name)"
	
    # build list of template ids
	$template = $field.Parent.Parent
	$templateId = $template.ID
	if (!$templateIds.Contains($templateid)) {
	    #Write-Host "template selected for export: $($template.Name) - template ID: $templateid"
	    $templateIds.Add($templateId)
	}
}

$results = Get-ChildItem -Path $searchPath -Recurse | Where-Object { Template-Check $_ $templateIds }
foreach ($result in $results) {
    Write-Host "evaluate result: $($result.Name)"
    $resultFieldValues = @()
    $resultHasValues = $false
    foreach ($field in $fieldList) {
        $fieldValue = FieldValue-Check $result $field
        if ($fieldValue) {
            $resultHasValues = $true
            $resultFieldValues += $field
        }
        # if field value, check for link type
    }
    if ($resultHasValues) {
        #Write-Host "  result $($result.Name) should be added to export because there's values on fields:"
        #$resultFieldValues | Foreach-Object { Write-Host "        - $($_)" }
        $resultItemList.Add($result)
    } else {
        Write-Host "  result skipped"
    }
}

# Prep export props
#$trimmedExportFields = $exportFields.Substring(0, $exportFields.Length - 1)
#$fieldsConverted = Invoke-Expression $trimmedExportFields
#$props = @{
#    Title = "Field Type Report"
#    PageSize = 50
#}

# without any filtering
#$results | Show-ListView @props -Property $fieldsConverted

# with filtering
#$resultItemList | Show-ListView @props -Property $fieldsConverted


$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################
