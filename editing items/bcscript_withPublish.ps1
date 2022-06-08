## find brightcove ids and stuff for vimeo
$searchPath = "/sitecore/content/"

# ids and paths to templates & renderings
$useLinkManager = $true
$templateIdToMatch = "{888294CB-89E6-4D7F-A778-B6763BD831A2}" # _video template
$logDate = $(Get-Date).toString("yyyy_MM_dd-HH-mm-ss")
$logFileName = "vimeo-conversion$logDate.log"
$logFile = "C:\inetpub\wwwroot\temp\$logFileName"

$listofFields = @(
    "Action Brightcove Video ID",
    "BrightCove Video ID",
    "Brightcove Video ID",
    "Data Video Id",
    "Bright Cove Video ID",
    "BrightcoveVideoID",
    "Video ID",
    "Brightcove Video"
)
$templateToSkipList = @(
	"{E2DDFDFE-B2ED-4ACC-9910-8FD1EA8799C7}", # InnovationsPromo
	"{854B9BB8-0081-4B89-A9A5-36CBA093C38D}", # USP hero
	"{65ED3868-2EB3-4C8C-84C6-795E1B8F7570}" #kiosk background container
)

######################################################################

function Template-Check {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)][Sitecore.Data.Items.Item]$item
    )

    $template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item)
    if ($template.InheritsFrom($templateIdToMatch) -and -not $templateToSkipList.Contains($template.ID)) {
        return $item
    }
}

function Get-ParentPage($item) {
    if (($item.Parent -ne $null) -and ($item -ne $null)) {
        $hasTemplate = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item.Parent).InheritsFrom("{3175C387-F4FD-4256-A78B-9763C69E5F96}")

        if ($hasTemplate) {
            return $item.Parent
        }
        Get-ParentPage($item.Parent)
    }
}

function Get-ItemUrl($item) {
    $site = [Sitecore.Sites.SiteContext]::GetSite("website")

    New-UsingBlock(New-Object -TypeName "Sitecore.Sites.SiteContextSwitcher" -ArgumentList $site) {
        $urlOptions = [Sitecore.Links.LinkManager]::GetDefaultUrlOptions()
        $urlOptions.AlwaysIncludeServerUrl = $True
        $urlOptions.ShortenUrls = $True
        $urlOptions.SiteResolving = $True;
        $url = [Sitecore.Links.LinkManager]::GetItemUrl($item, $urlOptions)
        return $url
    }
}

function Get-Brightcove-VideoID ($item) {
    $itemTemplate = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item)

    if (-not ([string]::IsNullOrEmpty($item.Fields["Vimeo Video ID"].value))) {
        return "Done"
    }
    else {
        if ($itemTemplate.ID -eq "{4897FE3A-29E1-45EC-890B-558CB4BACB6A}") {



            if ($item.Fields["Action Brightcove Video ID"]) {
                return $item.Fields["Action Brightcove Video ID"]
            }
            else {
                return $item.Fields["Brightcove Video ID"]
            }
        }
        elseif ($itemTemplate.ID -eq "{615C05C6-DC99-4DC1-BB66-CE480C2AEBB4}") {
            return $item.Fields["Brightcove Video Id"]
        }
        elseif ($itemTemplate.ID -eq "{6e80f65a-5d7a-4d04-b82d-e9357cff1a94}" -or $itemTemplate.ID -eq "{d285e46d-0454-4d87-ba54-9d9e00ecbb59}") {
            return $item.Fields["Data Video Id"]
        }
        elseif ($itemTemplate.ID -eq "{19d35d7e-7d01-415a-868f-4ce675debe41}") {
            return $item.Fields["Action Brightcove Video ID"]
        }
        elseif ($itemTemplate.ID -eq "{e2ddfdfe-b2ed-4acc-9910-8fd1ea8799c7}") {
            return $item.Fields["Bright Cove Video ID"]
        }
        else {
            foreach ($field in $listofFields) {
                if ($item.Fields[$field] -ne $null) {
                    return $item.Fields[$field]
                }
            }
            return $null
        }
    }
}

function GetFromList($language) {
    $list = Get-Items
    foreach ($foundItem in $list) {
        $brightcoveId = Get-Brightcove-VideoID($foundItem)
        if ($brightcoveId -eq "Done") {
            $ancestorItem = Get-ParentPage($foundItem)
            if ($ancestorItem) {
                $itemUrl = Get-ItemUrl($ancestorItem)
                Write-Host "done:" $foundItem.ID $itemUrl "," $foundItem.Language "," $foundItem.Paths.Path "," $foundItem.Template.Name -f yellow
				LogWrite("done: $($foundItem.ID),$itemUrl,$($foundItem.Language),$($foundItem.Paths.Path),$($foundItem.Template.Name)")
            }
            else {
                Write-Host "done:" $foundItem.ID " -- Vimeo ID: "$foundItem.Fields["Vimeo Video ID"].value" already found, nothing changed. Item is not link to a page. Language - " $foundItem.Language "," $foundItem.Paths.Path "," $foundItem.Template.Name -f yellow
				LogWrite("done: $($foundItem.ID),-- Vimeo ID: $($foundItem.Fields["Vimeo Video ID"].value) already found, nothing changed. Item is not link to a page. Language - $($foundItem.Language),$($foundItem.Paths.Path),$($foundItem.Template.Name)")
            }
        }
        elseif (-not ([string]::IsNullOrEmpty($brightcoveId.Value))) {
            $vimeoId = $lookup[$brightcoveId.Value]
            if (([string]::IsNullOrEmpty($vimeoId)) -and (-not ([string]::IsNullOrEmpty($brightcoveId.Value)))) {
                $ancestorItem = Get-ParentPage($foundItem)
                if ($ancestorItem) {
                    $itemUrl = Get-ItemUrl($ancestorItem)
                    Write-Host "novimeo:" $foundItem.ID "," $brightcoveId "," "has no matching Vimeo ID" "," $itemUrl "," $foundItem.Language "," $foundItem.Paths.Path "," $foundItem.Template.Name -f red
					LogWrite("novimeo: $($foundItem.ID),$brightcoveId,has no matching Vimeo ID,$itemUrl,$($foundItem.Language),$($foundItem.Paths.Path),$($foundItem.Template.Name)")
                }
                else {
                    Write-Host "novimeo:" $foundItem.ID "," $brightcoveId "," "has no matching Vimeo ID" "," $foundItem.Language "," $foundItem.Paths.Path "," $foundItem.Template.Name -f red 
					LogWrite("novimeo: $($foundItem.ID),$brightcoveId,has no matching Vimeo ID,no URL,$($foundItem.Language),$($foundItem.Paths.Path),$($foundItem.Template.Name)")
                }
            }
            else {
                 New-UsingBlock (New-Object Sitecore.Globalization.LanguageSwitcher $language) {
                     $foundItem.Editing.BeginEdit()
                     $foundItem.Fields["{711288F0-3D69-41A5-8499-20358578AFA3}"].Value = $vimeoId
                     $foundItem.Editing.EndEdit()
                     Publish-Item -Item $foundItem
                 }
                Write-Host "converted:" $foundItem.ID "," $brightcoveId "," $vimeoId "," $itemUrl "," $foundItem.Language "," $foundItem.Paths.Path "," $foundItem.Template.Name -f green
				LogWrite("converted: $($foundItem.ID),$brightcoveId,$vimeoId,$itemUrl,$($foundItem.Language),$($foundItem.Paths.Path),$($foundItem.Template.Name)")
            }
            
        }
        else {
            $ancestorItem = Get-ParentPage($foundItem)
            if ($ancestorItem) {
                $itemUrl = Get-ItemUrl($ancestorItem)
                Write-Host "nobrightcove" $foundItem.ID " -- No Brightcove ID found. be sure to add the missing fields before running complete. URL: " $itemUrl "Language: " $foundItem.Language "," $foundItem.Paths.Path "," $foundItem.Template.Name -f cyan
				LogWrite("nobrightcove: $($foundItem.ID), -- No Brightcove ID found. be sure to add the missing fields before running complete. URL: $itemUrl, Language: $($foundItem.Language),$($foundItem.Paths.Path), Template: $($foundItem.Template.Name)")
            }
            else {
                Write-Host "nobrightcove" $foundItem.ID " -- No Brightcove ID found. be sure to add the missing fields before running complete. Item is not link to a page." "Language: " $foundItem.Language "," $foundItem.Paths.Path "," $foundItem.Template.Name -f cyan
				LogWrite("nobrightcove: $($foundItem.ID), -- No Brightcove ID found. be sure to add the missing fields before running complete. Item is not link to a page., Language: $($foundItem.Language),$($foundItem.Paths.Path), Template: $($foundItem.Template.Name)")
            }
        }
    }
}

function LogWrite($logMessage) {
	Add-Content $logFile -value $logMessage
}

function Get-Items {
	if ($useLinkManager) {
		return Get-Item $templateIdToMatch | Get-ItemReferrer 
	} else {
		return Get-ChildItem -Path $searchPath -Language $language -Recurse | Where-Object { Template-Check $_ }
	}
}

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white
LogWrite("------------------------ Begin Script: $StartTime ------------------------")

# use sitecore config to find data folder setting
# create folder for \temp\upload if it doesn"t exist
# then upload csv
$dataFolder = [Sitecore.Configuration.Settings]::DataFolder
$tempFolder = $dataFolder + "\temp\upload";
$filePath = Receive-File -Path $tempFolder -Overwrite

if ($filePath -eq "cancel") {
    exit
}
$resultSet = Import-Csv $filePath
$rowsCount = ($resultSet | Measure-Object).Count
if ($rowsCount -le 0) {
    Write-Host "No data in file or file not found"
    Remove-Item $filePath
    exit
}

# build hash table from csv data
$lookup = @{}
foreach ($row in $resultSet) {
    $brightcoveId = $row.Brightcove
    $vimeoId = $row.Vimeo
    if (-not $lookup.Contains($brightcoveId)) {
        $lookup.Add($brightcoveId, $vimeoId)
    }
}

GetFromList('en')
GetFromList('en-CA')
GetFromList('fr-CA')
GetFromList('es-US')

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
LogWrite("------------------------ End Script - Total Time: $totalTime ------------------------")
$stream = New-Object System.IO.StreamReader($logFile)
Out-Download -InputObject $stream.BaseStream -Name $logFileName
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################