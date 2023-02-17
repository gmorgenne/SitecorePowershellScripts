<#
	.SYNOPSIS
        copies items from one site to another
	.DESCRIPTION
        only processes paths that inhert from app route, data folder, dictionary, and media folders
        tests if an item already exists in the new site
        copies item, if it's a page it will update the page design and template
        outputs log in not run in audit mode
	.NOTES
		Geoff Morgenne
#>

$srcPath = "/sitecore/content/site1/Home"
$destPath = "/sitecore/content/site2/Home"
$newTemplatePath = '/sitecore/templates/Project/Site2/Site2 App Route'
$newPageDesign = '{0F6C0EB7-76AE-4A68-B047-24D30AA11040}' # Site2 Page Design
$audit = $true

[System.IO.Directory]::CreateDirectory("$apppath\App_Data\temp\")
$logDate = $(Get-Date).toString("yyyy_MM_dd-HH-mm-ss")
$logFileName = "item-copy-$logDate.log"
$logFile = "$apppath\App_Data\temp\$logFileName"


######################################################################

function ShouldProcess-Item {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][string]$path
	)

    $item = Get-Item -Path $path
    $validItem = $false
	if ($item) {
		$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item)
		if ($template.InheritsFrom("{F53A9979-5CD3-447D-8241-6A504AFF762E}")) { # App Route
			$validItem = $true
		}
        if ($template.InheritsFrom("{A29D272E-9D48-453C-9E9D-B47585FA7F20}")) { # JSS Data Folder
			$validItem = $true
		}
        if ($template.InheritsFrom("{0A2847E6-9885-450B-B61E-F9E6528480EF}")) { # Dictionary
			$validItem = $true
		}
        if ($template.InheritsFrom("{E8E8C94F-4248-43C3-A79F-99FBB49D78E6}")) { # Media Folder
			$validItem = $true
		}
	}
    return $validItem
}

function Write-LogExtended {
    param(
        [string]$logFilePath,
        [string]$Message,
        [System.ConsoleColor]$ForegroundColor = $host.UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$BackgroundColor = $host.UI.RawUI.BackgroundColor
    )
    if ($audit) {
        $message = "[AUDIT] $message"
    }

    $stamp = $(Get-Date).toString("yyyy_MM_dd-HH-mm-ss")
    Add-Content $logFilePath -Value "$stamp $message"
    Write-Host $message -ForegroundColor $ForegroundColor -BackgroundColor $backgroundColor
}

######################################################################
$StartTime = $(get-date)
Write-LogExtended $logFile "------------------------"
Write-LogExtended $logFile "Begin Script" green
Write-LogExtended $logFile "------------------------"

if ($audit) {
    Write-LogExtended $logFile "This is an audit, no changes will be made"
}

if (-not(ShouldProcess-Item $srcPath)) {
    Write-LogExtended $logFile "source path is not a valid item to copy"
    return
}
$items = Get-ChildItem -path $srcPath -recurse
foreach ($item in $items) {
    # check if item can be copied by building path to dest
    $itemPath = $item.Paths.FullPath
    $relativePath = $itemPath.Replace($srcPath, "")
    $testPath = $destPath + $relativePath
    $testItem = Test-Path -Path $testPath
    if ($testItem) {
        Write-LogExtended $logFile "Item already exists! $testPath" red
    } else {
        # if item is a page, let's copy the local datasources if any and change page design & template
        Write-LogExtended $logFile "Copying item to $testPath" green
        if (!$audit) {
            Copy-Item -Path $itemPath -Destination $testPath
        }
        $renderings = Get-Rendering -item $item -FinalLayout
        if ($renderings -ne $null) {
            Write-LogExtended $logFile "    item is a page, copy then update template and page design for $relativePath"
		    if (!$audit) {
                $newItem = Get-Item -Path $testPath
		        Set-ItemTemplate -Path $testPath -Template $newTemplatePath
		        $newItem.Editing.BeginEdit()
		        $newItem.Fields["Page Design"].Value = $newPageDesign 
		        $newItem.Editing.EndEdit()

		        # check for datasources that are located in the site data folder
                $newItemRenderings = Get-Rendering -item $newItem -FinalLayout
                foreach ($rendering in $newItemRenderings) {
                    $datasourceID = $rendering.Datasource
                    if ([Sitecore.Data.ID]::IsID($datasourceID)) {
                        $datasourceItem = Get-Item -path $srcPath -ID $datasourceID
                        Write-LogExtended $logFile "    new item has a datasource that may need to be updated: $($datasourceItem.Paths.FullPath)" yellow
                    }
                }
            }
        }
    }
}

######################################################################

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-LogExtended $logFile "------------------------"
Write-LogExtended $logFile "End Script - Total time: $totalTime" green
Write-LogExtended $logFile "------------------------"

if (!$audit) {
    $stream = New-Object System.IO.StreamReader($logFile)
    Out-Download -InputObject $stream.BaseStream -Name $logFileName
}
Remove-Item $logFile
######################################################################