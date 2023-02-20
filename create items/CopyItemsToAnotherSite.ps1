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

$audit = $true
$srcPath = "/sitecore/content/tenant/site1/Home"
$destPath = "/sitecore/content/tenant/site2/Home"
$newTemplatePath = "/sitecore/templates/Project/tenant/Site2/Site2 App Route"
$newPageDesign = "{0F6C0EB7-76AE-4A68-B047-24D30AA11040}" # Site2 Page Design
# used in the rendering audit
$destSitePath = "/sitecore/content/tenant/site2"
$globalSitePath = "/sitecore/content/tenant/shared"

# log creation variables, don't update
[System.IO.Directory]::CreateDirectory("$apppath\App_Data\temp\")
$logDate = $(Get-Date).toString("yyyy_MM_dd-HH-mm-ss")
$logFileName = "item-copy-$logDate.log"
$logFile = "$apppath\App_Data\temp\$logFileName"


######################################################################

function Audit-Datasource {
    param(
		[Parameter(Mandatory=$true, Position=0)][string]$datasource
	)

    if ([Sitecore.Data.ID]::IsID($datasource)) {
        $datasourceItem = Get-Item -path "/sitecore/content" -ID $testItemRenderingDatasource
        $datasourceItemPath = $datasourceItem.Paths.FullPath

        if ($datasourceItemPath.StartsWith($globalSitePath)) {
            Write-LogExtended $logFile "    item has a datasource that is shared in a global location: $datasourceItemPath"
        } elseif ($datasourceItemPath.StartsWith($destSitePath)) {
            Write-LogExtended $logFile "    item has a datasource that is shared at the site level: $datasourceItemPath"
        } else {
            Write-LogExtended $logFile "    item has a datasource that may need to be updated: $datasourceItemPath" yellow
        }
    }
}

function ShouldProcess-Item {
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
$items = @( Get-Item -path $srcPath ) + @( Get-ChildItem -path $srcPath -recurse )
foreach ($item in $items) {
    # check if item can be copied by building path to dest
    $itemPath = $item.Paths.FullPath
    $relativePath = $itemPath.Replace($srcPath, "")
    $testPath = $destPath + $relativePath
    $testItemExists = Test-Path -Path $testPath

    # get renderings to use for a rendering audit if it exists 
    # or to update template and page design if it doesn't exist
    $renderings = Get-Rendering -item $item -FinalLayout

    if ($testItemExists) {
        Write-LogExtended $logFile "Item already exists! $testPath" red
        $testItem = Get-Item -Path $testPath
        $testItemRenderings = Get-Rendering -item $testItem -FinalLayout

        # rendering audit
        if (($testItemRenderings -ne $null) -and ($renderings -ne $null)) {
            Write-LogExtended $logFile "   auditing renderings"
            # compare # renderings
            if ($testItemRenderings.Length -ne $renderings.Length) {
                Write-LogExtended $logFile "    different count of renderings" darkred

                $shouldCopyRenderings = Show-Confirm -Title "Copy presentation details to $testPath?"
                if ($shouldCopyRenderings -eq "yes") {
                    Write-LogExtended $logFile "    copying presentation details:"
                    $itemRenderingFieldValue = $item.Fields["__Renderings"].Value
                    $itemFinalRenderingFieldValue = $item.Fields["__Final Renderings"].Value

                    $testItem.Editing.BeginEdit()
                    $testItem.Fields["__Renderings"].Value = $itemRenderingFieldValue
                    if ($itemFinalRenderingFieldValue) {
                        $testItem.Fields["__Final Renderings"].Value = $itemFinalRenderingFieldValue
                    }
                    $testItem.Editing.EndEdit()
                } else {
                    Write-LogExtended $logFile "    skipped copying presentation details"
                }
            }
            # callout if a datasource is missing or stored outside shared site, site data, or local location
            foreach($testItemRendering in $testItemRenderings) {
                $testItemRenderingDatasource = $testItemRendering.Datasource
                Audit-Datasource $testItemRenderingDatasource
            }
            # TODO: rendering parameters? tricky bit here is if there's multiple of the same rendering on both pages.

            Write-LogExtended $logFile "   rendering audit complete"
        }
    } else {
        # if item is a page, let's copy the local datasources if any and change page design & template
        Write-LogExtended $logFile "Copying item to $testPath" green
        if (!$audit) {
            $shouldCopy = Show-Confirm -Title "Copy item to $testPath?"
            if ($shouldCopy -eq "yes") {
                Write-LogExtended $logFile "    successful copy?:"
                Copy-Item -Path $itemPath -Destination $testPath
            } else {
                Write-LogExtended $logFile "    skipped copying"
                continue
            }
        }
        
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
                    Audit-Datasource $datasourceID
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