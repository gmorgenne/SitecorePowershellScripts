<#
    .SYNOPSIS
        Templates Report Generator
    .DESCRIPTION
        Script that outputs the templates + field definitions in Sitecore. Can export to Excel, CSV, Html, Json.
    .NOTES
        Version:        1.0
        Author:         Geoff Morgenne
#>

$templateOutputItems = [System.Collections.ArrayList]@()
$renderingOutputItems = [System.Collections.ArrayList]@()
$selectedTemplateDir = Get-Item master:\templates
$selectedRenderingDir = Get-Item master:\layout\renderings
$count = 0

######################################################################

# show a prompt to pick the path to find items
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

function ExportRendering {
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$rendering
	)
	$reportItem = @{
		"ID" = $rendering.Id
        "Rendering Name" = $rendering.Name
        "Parameters Template Name" = ""
        "Parameter Fields" = ""
        "Template Name" = ""
        "Fields" = ""
        "Inherited Fields" = ""
	}
	$baseItemFields = @()
	if ($rendering["Datasource Template"] -ne "") {
		$template = Get-Item $rendering["Datasource Template"]
		if ($null -eq $template) { continue; }
		$reportItem["Template Name"] = $template.Name
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
			$reportItem["Fields"] = $templateFields | ft Name | Out-String
		}
		if ($baseItemFields.Length -gt 0) {
			$reportItem["Inherited Fields"] = $baseItemFields | select -Property Name | Out-String
		}
	}
	if ($rendering["Parameters Template"] -ne "") {
		$parametersTemplate = Get-Item $rendering["Parameters Template"]
		$reportItem["Parameters Template Name"] = $parametersTemplate.Name
		$parameterTemplateFields = $parametersTemplate.Axes.GetDescendants() | Where-Object { !($_.Name -eq "__Standard Values") -and $_.TemplateId -eq "{455A3E98-A627-4B40-8035-E683A0331AC7}" }
		if ($parameterTemplateFields.Length -gt 0) {
			$reportItem["Parameter Fields"] = $parameterTemplateFields | select -Property Name | Out-String
		}
	}
	$renderingOutputItems.Add([pscustomobject]$reportItem) > $null
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
}

function OutputTemplateItem {
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$template
	)
    $templateFields = $template.Axes.GetDescendants() | Where-Object { !($_.Name -eq "__Standard Values") }
	foreach ($templateField in $templateFields) {
        $reportItem = BuildTemplateReportItem $template $templateField
        $templateOutputItems.Add([pscustomobject]$reportItem) > $null
	}
}

function BuildTemplateReportItem {
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$template,
        [Parameter(Mandatory=$true, Position=1)][Sitecore.Data.Items.Item]$templateField
	)
    $reportItem = @{
        "Template Name" = $template.Name
    }
    $reportItem["Template Displayname"] = $template.DisplayName
    $reportItem["Template Path"] = $template.FullPath
    $reportItem["Field Type"] = $templateField.Fields["Type"].Value
    $reportItem["Field Name"] = $templateField.Name
    $reportItem["Field DisplayName"] = $templateField.DisplayName
    $reportItem["Field Template"] = $templateField.TemplateName
    $reportItem["Field Path"] = $templateField.Paths.FullPath
    $reportItem["Field Source"] = $templateField.Fields["Source"].Value
    $reportItem["Short Description"] = $templateField.Fields["__Short description"].Value
    $reportItem["Long Description"] = $templateField.Fields["__Long description"].Value
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
$templateAuditProps = @{
    Title = "Templates Field Audit"
    InfoTitle = "Audit of field definitions for all templates"
    InfoDescription = "Detailed export of all Templates and their field definitions"
    PageSize = 50
}
$renderingAuditProps = @{
    Title = "Rendering Field Audit"
    InfoTitle = "Audit of field definitions for all renderings"
    InfoDescription = "Detailed export of all Renderings and their field definitions"
    PageSize = 50
}
$templateOutputItems | Show-ListView @templateAuditProps
$renderingOutputItems | Show-ListView @renderingAuditProps

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################