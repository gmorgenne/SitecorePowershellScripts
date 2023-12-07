<#
    .SYNOPSIS
        Templates Report Generator
    .DESCRIPTION
        Script that outputs the templates + field definitions in Sitecore. Can export to Excel, CSV, Html, Json.
    .NOTES
        Version:        1.0
        Author:         Geoff Morgenne
#>

# show a prompt to pick the path to find items
$selectedRenderingDir = Get-Item master:\layout\renderings
$selectedTemplateDir = Get-Item master:\templates
$prompt = @{
    Parameters = @(
        @{ Name = "selectedRenderingDir"; Title="Select the root for the renderings report"; Tooltip="Select the rendering folder to use for the output"; Root="/sitecore/layout/renderings" }    
        @{ Name = "selectedTemplateDir"; Title="Select the root for the templates report"; Tooltip="Select the template folder to use for the output"; Root="/sitecore/templates/" }
    )
    Title = "Rendering & Templates Report Generator"
    Description = "Outputs the field definitions etc... as configured in Sitecore"
    Width = 500
    Height = 480
    OkButtonName = "Proceed"
    CancelButtonName = "Abort"
    ShowHints = $true
    Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

$result = Read-Variable @prompt
if ($result -ne "ok") {
	exit
}

######################################################################

class ReportItem
{
    [String] $Path
    [String] $Type
    [String] $Name
    [String] $Fields
    [Int] $LinkCount
}

class ReportRenderingItem
{
    [String] $RenderingName
    [String] $RenderingPath
    [String] $RenderingDatasourceLocationField
    [String] $ParametersTemplateName = ""
    [String] $ParameterFields = ""
    [String] $DatasourceTemplateName = ""
    [String] $DatasourceTemplateFields = ""
    [String] $DatasourceInheritedFields = ""
}

class ReportTemplateItem 
{
    [String] $TemplateName
    [String] $TemplatePath
    [String] $FieldName
    [String] $FieldDisplayName
    [String] $FieldType
    [String] $FieldSource
    [String] $FieldShortDescription
    [String] $FieldLongDescription
    [String] $FieldTemplate
    [String] $FieldPath
}

$reportItems = New-Object Collections.Generic.List[ReportItem]
$reportRenderingItems = New-Object Collections.Generic.List[ReportRenderingItem]
$reportTemplateItems = New-Object Collections.Generic.List[ReportTemplateItem]

######################################################################

function CountLinks{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item
	)
	$links = $item | Get-ItemReferrer
	return $links.length
}

function ExportRendering {
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$rendering
	)
    $reportItem = BuildRenderingAsReportItem $rendering
    $renderingReportItem = New-Object ReportRenderingItem
    $renderingReportItem.RenderingName = $rendering.Name
    $renderingReportItem.RenderingPath = $rendering.FullPath
    $renderingReportItem.RenderingDatasourceLocationField = $rendering["Datasource Location"]
	$fields = @()

	if ($rendering["Datasource Template"] -ne "") {
		$template = Get-Item $rendering["Datasource Template"]
		if ($null -eq $template) { continue; }
        $renderingReportItem.DatasourceTemplateName = $template.Name
        $baseItemFields = @()
		if ($null -ne $template.Fields["__Base template"] -and $template.Fields["__Base template"].Value -ne "" -and $template.Fields["__Base template"].Value.Split("|").Length -gt 0) {
			$baseTemplates = $template.Fields["__Base template"].Value.Split("|")
			foreach ($t in $baseTemplates) {
				$baseItem = Get-Item $t
				if ($baseItem.Id -eq "{1930BBEB-7805-471A-A3BE-4858AC7CF696}" -or $baseItem.Id -eq "{3A95184A-37A8-4462-8BB4-2307D1A28EFA}") {
					continue
				}
				$baseItemFields += $baseItem.Axes.GetDescendants() | Where-Object { !($_.Name -eq "__Standard Values") -and $_.TemplateId -eq "{455A3E98-A627-4B40-8035-E683A0331AC7}" }
			}
		}
		$templateFields = $template.Axes.GetDescendants() | Where-Object { !($_.Name -eq "__Standard Values") -and $_.TemplateId -eq "{455A3E98-A627-4B40-8035-E683A0331AC7}" }
		if ($templateFields.Length -gt 0) {
            $fieldList = $templateFields | foreach-object { $_.Name } | Out-String
            $renderingReportItem.DatasourceTemplateFields = $fieldList
            $fields += $fieldList
		}
		if ($baseItemFields.Length -gt 0) {
			$baseItemFieldsList = $baseItemFields | foreach-object { $_.Name } | Out-String
            $renderingReportItem.DatasourceInheritedFields = $baseItemFieldsList
            $fields += $baseItemFieldsList
		}
	}
	if ($rendering["Parameters Template"] -ne "") {
		$parametersTemplate = Get-Item $rendering["Parameters Template"]
		
        $renderingReportItem.ParametersTemplateName = $parametersTemplate.Name
		$parameterTemplateFields = $parametersTemplate.Axes.GetDescendants() | Where-Object { !($_.Name -eq "__Standard Values") -and $_.TemplateId -eq "{455A3E98-A627-4B40-8035-E683A0331AC7}" }
		if ($parameterTemplateFields.Length -gt 0) {
			$parameterFieldsList = $parameterTemplateFields | foreach-object { $_.Name } | Out-String
            $renderingReportItem.$ParameterFields = $parameterFieldsList
            $fields += $parameterFieldsList
		}
	}
    if ($fields.Length -gt 0) {
        $reportItem.Fields = $fields
    }
	$reportRenderingItems.Add($renderingReportItem)
    $reportItems.Add($reportItem)
}

function BuildRenderingAsReportItem {
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$rendering
	)
    $reportItem = New-Object ReportItem
    $reportItem.Path = $rendering.FullPath
    $reportItem.Type = "Rendering"
    $reportItem.Name = $rendering.Name
    $reportItem.Fields = ""
    $reportItem.LinkCount = CountLinks $rendering
    return $reportItem
}

function ExportTemplate {
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$template
	)
    Write-Host "Template" $template.FullPath "has the following CCG base templates" -ForegroundColor "yellow"

	# First go per template through all the base templates and their fields
	# It turns out when we use the Templatemanager to get the base templates we don't get back all the base templates
	# Hence we read the '__Base template' field.
	[Sitecore.Text.ListString]$ids = $template.Fields["__Base template"].Value
	if ($null -ne $ids) {
		foreach ($baseTemplate in $ids) {
			$baseTemplateItem = Get-Item -Path master: -Id $baseTemplate
			if ($baseTemplateItem.FullPath -like '*CCG*') { # TODO: instead of like '*CCG*' maybe not standard/sitecore template?
				Write-Host $baseTemplateItem.FullPath -ForegroundColor "green"
                OutputTemplateItem $baseTemplateItem
			}
		}
	}
    OutputTemplateItem $template
    $reportItem = BuildTemplateAsReportItem $template
    $reportItems.Add($reportItem)
}

function OutputTemplateItem {
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$template
	)
    $templateFields = $template.Axes.GetDescendants() | Where-Object { !($_.Name -eq "__Standard Values") }
	foreach ($templateField in $templateFields) {
        $templateReportItem = BuildTemplateReportItem $template $templateField
        $reportTemplateItems.Add($templateReportItem)
	}
}

function BuildTemplateReportItem {
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$template,
        [Parameter(Mandatory=$true, Position=1)][Sitecore.Data.Items.Item]$templateField
	)
    $reportItem = New-Object ReportTemplateItem
    $reportItem.TemplateName = $template.Name
    $reportItem.TemplateDisplayname = $template.DisplayName
    $reportItem.TemplatePath = $template.FullPath
    $reportItem.FieldType = $templateField.Fields["Type"].Value
    $reportItem.FieldName = $templateField.Name
    $reportItem.FieldDisplayName = $templateField.DisplayName
    $reportItem.FieldTemplate = $templateField.TemplateName
    $reportItem.FieldPath = $templateField.Paths.FullPath
    $reportItem.FieldSource = $templateField.Fields["Source"].Value
    $reportItem.ShortDescription = $templateField.Fields["__Short description"].Value
    $reportItem.LongDescription = $templateField.Fields["__Long description"].Value
    return $reportItem
}

function BuildTemplateAsReportItem {
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$template
	)
    $templateItem = [Sitecore.Data.Items.TemplateItem]$template
    $templateFields = $templateItem.Fields | Where-Object { -not $_.Name.StartsWith("__") }

    $reportItem = New-Object ReportItem
    $reportItem.Path = $template.FullPath
    $reportItem.Type = "Template"
    $reportItem.Name = $template.Name
    $reportItem.Fields = $templateFields | foreach-object { $_.Name } | Out-String
    $reportItem.LinkCount = CountLinks $template
    return $reportItem
}

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$renderings = Get-ChildItem -Path $selectedRenderingDir.FullPath -Recurse
foreach ($rendering in $renderings) {
    if ($rendering.Template.Name -eq "Rendering folder") { continue; }
	ExportRendering $rendering
}

$templates = Get-ChildItem -Path $selectedTemplateDir.FullPath -Recurse | Where-Object { $_.TemplateName -eq "Template" } | Initialize-Item
foreach ($template in $templates) {
	ExportTemplate $template
}

######################################################################

# prep & create output
$reportProps = @{
    Title = "Rendering And Template Field Audit"
    InfoTitle = "Audit of all fields for Renerings & Templates"
    InfoDescription = "High-Level overview of all fields for renderings & templates"
    PageSize = 50
}
$renderingAuditProps = @{
    Title = "Rendering Field Audit"
    InfoTitle = "Audit of field definitions for all renderings"
    InfoDescription = "Detailed export of all Renderings and their field definitions"
    PageSize = 50
}
$templateAuditProps = @{
    Title = "Templates Field Audit"
    InfoTitle = "Audit of field definitions for all templates"
    InfoDescription = "Detailed export of all Templates and their field definitions"
    PageSize = 50
}

$reportItems | Show-ListView @$reportProps -Property @{Label="Path"; Expression={$_.Path} },
@{Label="Type"; Expression={$_.Type} },
@{Label="Name"; Expression={$_.Name} },
@{Label="Fields"; Expression={$_.Fields} },
@{Label="Link Count"; Expression={$_.LinkCount} }

$reportRenderingItems | Show-ListView @renderingAuditProps -Property @{Label="Path"; Expression={$_.RenderingPath} },
@{Label="Name"; Expression={$_.RenderingName} },
@{Label="Datasource Location Field"; Expression={$_.RenderingDatasourceLocationField} },
@{Label="Parameters Template Name"; Expression={$_.ParametersTemplateName} },
@{Label="Parameter Fields"; Expression={$_.ParameterFields} },
@{Label="Datasource Template Name"; Expression={$_.DatasourceTemplateName} },
@{Label="Datasource Template Fields"; Expression={$_.DatasourceTemplateFields} },
@{Label="Datasource Inherited Fields"; Expression={$_.DatasourceInheritedFields} }

$reportTemplateItems | Show-ListView @templateAuditProps -Property @{Label="Path"; Expression={$_.TemplatePath} },
@{Label="Template Name"; Expression={$_.TemplateName} },
@{Label="Field Name"; Expression={$_.FieldName} },
@{Label="Field Display Name"; Expression={$_.FieldDisplayName} },
@{Label="Field Type"; Expression={$_.FieldType} },
@{Label="Field Source"; Expression={$_.FieldSource} },
@{Label="Field Short Description"; Expression={$_.FieldShortDescription} },
@{Label="Field Long Description"; Expression={$_.FieldLongDescription} },
@{Label="Field or Section"; Expression={$_.FieldTemplate} },
@{Label="Field Path"; Expression={$_.FieldPath} }

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################