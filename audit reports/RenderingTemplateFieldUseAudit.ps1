<#
    .SYNOPSIS
        Rendering Parameter Template Field Use Audit
    .DESCRIPTION
        Prompts for a rendering, builds an export of all uses of that rendering and include
        rendering parameter template field data
        The goal of the export will be to show the different "configurations" of the selected rendering
    .NOTES
        Version:        1.0
        Author:         Geoff Morgenne
#>

# show a prompt to pick the rendering to export
$selectedRendering = Get-Item master:\layout\renderings
$prompt = @{
    Parameters = @(
        @{ Name = "selectedRendering"; Title="Select the root for the renderings report"; Tooltip="Select the rendering folder to use for the output"; Root="/sitecore/layout/renderings" }    
    )
    Title = "Rendering Template Field Use Audit"
    Description = "Select the rendering to output all configurations of the rendering parameter template"
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

if ($selectedRendering["Parameters Template"] -eq "") {
    Write-Host "Selected rendering does not use a rendering parameter template."
    exit
}

######################################################################

class ExportItem
{
    [String] $PageName
    [String] $PagePath
}
$exportItems = New-Object Collections.Generic.List[ExportItem]

######################################################################

function Export-Item {
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$page
	)

    foreach ($rendering in Get-Rendering -Item $page -FinalLayout) {
        if ($rendering.ItemID -eq $selectedRendering.ID) {
            $export = New-Object ExportItem
            $export.PageName = $page.Name
            $export.PagePath = $page.Paths.FullPath
            $renderingParameters = Get-RenderingParameter -Rendering $rendering
            foreach($param in $renderingParameters.GetEnumerator()) {
                $export | Add-Member -MemberType NoteProperty -Name $param.Key -Value $param.Value
            }
            $exportItems.Add($export)
        }
    }
}

function Filter-Items {
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][string]$path
	)

    if(-not($path.StartsWith("/sitecore/content/"))) {
        return $false
    }
    if($path.Contains("Admin") -or $path.Contains("StyleGuide")) {
        return $false
    }

    return $true
}

######################################################################


$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white


# build collection of fields to output
$fields = '@{Label="Page Name"; Expression={$_.PageName} }, @{Label="Page Path"; Expression={$_.PagePath} },'

# create a list of field names on the Standard Template. This will help us filter out extraneous fields.
$standardTemplate = Get-Item -Path "master:" -ID "{1930BBEB-7805-471A-A3BE-4858AC7CF696}"
$standardTemplateTemplateItem = [Sitecore.Data.Items.TemplateItem]$standardTemplate
$standardFields = $standardTemplateTemplateItem.OwnFields + $standardTemplateTemplateItem.Fields | Select-Object -ExpandProperty key -Unique
$standardRenderingParamTemplate = Get-Item -Path "master" -ID "{8CA06D6A-B353-44E8-BC31-B528C7306971}"
$standardRenderingParamTemplateItem = [Sitecore.Data.Items.TemplateItem]$standardRenderingParamTemplate
$standardFields += $standardRenderingParamTemplateItem.OwnFields + $standardRenderingParamTemplateItem.Fields | Select-Object -ExpandProperty key -Unique

# get parameters template of selected rendering
$parametersTemplate = Get-Item $selectedRendering["Parameters Template"]
$parametersTemplateItem = [Sitecore.Data.Items.TemplateItem]$parametersTemplate
$parameterTemplateFields = $parametersTemplateItem.Fields | Where-Object { $standardFields -notcontains $_.Name }

if ($parameterTemplateFields.Length -gt 0) {
    foreach ($field in $parameterTemplateFields) {
        $fields += ' @{ Label = "' + $field.Name + '"; Expression = { $_.' + $field.Name + ' }; },'
    }
}

# get pages that use the selected rendering (filter out stuff like admin & style guide pages)
$pages = $selectedRendering | Get-ItemReferrer | Where-Object { Filter-Items $_.Paths.FullPath }
foreach ($page in $pages) {
    Export-Item $page
}

# prep and export report
$fields = $fields.Substring(0, $fields.Length - 1)
$fieldsConverted = Invoke-Expression $fields
$props = @{
    Title = "$($selectedRendering.Name) Rendering Parameter Template Field Use Audit"
    PageSize = 20
}
$exportItems | Show-ListView @props -Property $fieldsConverted


$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################