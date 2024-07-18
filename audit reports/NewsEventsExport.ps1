<#
	.SYNOPSIS
        Exports all Resources for strapi import
#>

#data from sitecore
$resourcesPath = "/sitecore/content/News"
$resourcesTemplate = "{62CAF623-0EE5-467F-AFDD-E82C5B90DD02}"

# data from strapi
$chvSiteId = 1
$cvgSiteId = 3
$hubSiteId = 2
# these are the next available id in each collection we'd import to
$newsEventId = 119
$eventDetailsId = 17
$newsEventTagId = 83
$imageId = 417
# these are used to map to existing strapi news/event tags or create missing ones
$strapiTags = @{
    "Home Video" = @{
		id = 5
		tag = "Home Video"
		locale = "en-US"
		localizations = $null
	}
    "Auction Results" = @{
		id = 6
		tag = "Auction Results"
		locale = "en-US"
		localizations = $null
	}
    "Auctions" = @{
		id = 7
		tag = "Auctions"
		locale = "en-US"
		localizations = $null
	}
    "Company News" = @{
		id = 8
		tag = "Company News"
		locale = "en-US"
		localizations = $null
	}
    "Shows" = @{
		id = 9
		tag = "Shows"
		locale = "en-US"
		localizations = $null
	}
    "Video" = @{
		id = 10
		tag = "Video"
		locale = "en-US"
		localizations = $null
	}
    "Video Games" = @{
		id = 11
		tag = "Video Games"
		locale = "en-US"
		localizations = $null
	}
    "Trading Cards" = @{
		id = 12
		tag = "Trading Cards"
		locale = "en-US"
		localizations = $null
	}
    "New Release" = @{
		id = 15
		tag = "New Release"
		locale = "en-US"
		localizations = $null
	}
    "Upcoming Sale" = @{
		id = 75
		tag = "Upcoming Sale"
		locale = "en-US"
		localizations = $null
	}
    "Resource" = @{
		id = 81
		tag = "Resource"
		locale = "en-US"
		localizations = $null
	}
}

######################################################################

$strapiImages = @{}
$strapiImageIds = @()
$strapiNewsEvents = @{}
$strapiEventDetails = @{}

class Redirect {
    [string] $source
    [string] $destination
    [boolean] $permanent = $true
}

class ResourceJsonOutput {
    [string] $body
    [int] $eventDetails = $null
    [int] $headerImage = $null
    [string] $locale = "en-US"
    [int] $portraitImage = $null
    [string] $postDate
    [int[]] $sites
    [int[]] $tags
    [string] $teaser
    [string] $title
    [string] $type
}

class ResourceCsvOutput {
    [string] $body
    [string] $headerImageUrl
    [string] $portraitImageUrl
    [string] $postDate
    [string[]] $sites
    [string[]] $tags
    [string] $teaser
    [string] $title
    [string] $type
    [string] $eventLocation
    [string] $eventCity
    [string] $eventState
    [string] $eventCountry
    [string] $eventStartDate
    [string] $eventEndDate
    [string] $eventUrl
}

######################################################################

function Build-Url{
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item] $item,
		[Parameter(Mandatory=$true, Position=1)][int] $id,
		[Parameter(Mandatory=$true, Position=2)][string] $type
	)

    $name = $item.Name.ToLower().Replace(" ", "-")
    return "/news-and-events/{0}/{1}/{2}" -f $type.ToLower(), $id, $name
}

function Get-Tag{
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item] $item
	)

    return $item.Fields["ResourceTagTitle"].Value
}

function Get-Url{
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item] $item
	)

    return [CCG.Feature.Resources.Utils.ResourceUtil]::ConstructResourceUrl($item)
}

function OutputDateField{
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Fields.DateField] $dateField
	)

    return $dateField.DateTime.toString("yyyy-MM-dd")
}

function OutputEvent{
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item] $item
	)

    $eventId = $Global:eventDetailsId
    $stateField = [Sitecore.Data.Fields.ReferenceField]$item.Fields["EventStateProvince"]
    $countryField = [Sitecore.Data.Fields.ReferenceField]$item.Fields["EventCountry"]
    $eventDetails = @{
        id = $eventId
        location = $item.Fields["EventLocation"].Value
        city = $item.Fields["EventCity"].Value
        state = $stateField.TargetItem.Fields["StateName"].Value # sitecore field is a droptree, fields are StateName, StateAbbreviation
        startDate = OutputDateField $item.fields["EventStartDate"]
        endDate = OutputDateField $item.fields["EventEndDate"]
        url = OutputLink $item.fields["EventUrl"]
        country = $countryField.TargetItem.Fields["CountryName"].Value # sitecore field is a droplink, get reference item, fields are CountryName, CountryTwoLetterCode, CountryThreeLetterCode
    }
    $Global:strapiEventDetails += @{
        "$eventId" = $eventDetails
    }
    $Global:eventDetailsId++
    return @{
        id = $eventId
        data = $eventDetails
    }
}

function OutputImage{
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Fields.ImageField] $imageField
	)

    if($imageField -and $imageField.MediaItem) {
        $id = $Global:imageId
        $Global:strapiImages += @{
            "$id" = @{
                alternativeText = $imageField.Alt
                id = $id
                name = $imageField.MediaItem.Name
                url = [Sitecore.Resources.Media.MediaManager]::GetMediaUrl($imageField.MediaItem).replace("/sitecore/shell", "")
            }
        } 
        $Global:strapiImageIds += $id
        $Global:imageId++
        return $id
    }

    return $null
}

function OutputImageUrl{
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Fields.ImageField] $imageField
	)

    if($imageField -and $imageField.MediaItem) {
        return [Sitecore.Resources.Media.MediaManager]::GetMediaUrl($imageField.MediaItem).replace("/sitecore/shell", "")
    }

    return "image output failed"
}

function OutputLink{
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Fields.LinkField] $linkField
	)

    return $linkField.Url
}

function OutputSites{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Fields.MultilistField] $sitesField
    )

    $chvSitecoreSiteId = "{886AFA33-15B1-450A-9043-7574748C84A3}"
    $cvgSitecoreSiteId = "{A8BD2781-D231-4C7F-A73F-8D0E75D5371F}"
    $hubSitecoreSiteId = "{0B9EE448-2346-4234-B404-ABDD2DF9F3AE}"

    $siteIds = @()
    $siteNames = ""
    if($null -eq $sitesField) { return $null }
    $siteItems = $sitesField.GetItems()
    foreach($site in $siteItems) {
         $siteId = $site.ID
         if($siteId -eq $chvSitecoreSiteId) {
            $siteIds += $chvSiteId
            $siteNames += "CHV|"
         }
         if($siteId -eq $cvgSitecoreSiteId) {
            $siteIds += $cvgSiteId
            $siteNames += "CVG|"
         }
         if($siteId -eq $hubSitecoreSiteId) {
            $siteIds += $hubSiteId
            $siteNames += "HUB|"
         }
    }
    if($siteNames.length -gt 0) {
        $siteNames = $siteNames.Substring(0, $siteNames.length - 1)
    }

    return @{
        ids = $siteIds
        names = $siteNames
    }
}

function OutputTags{
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item] $item
	)

    # merge categories & tags
    $itemTags = @()
    $categoryField = [Sitecore.Data.Fields.ReferenceField]$item.Fields["ResourceCategory"]
    $tagsField = [Sitecore.Data.Fields.MultilistField]$item.Fields["ResourceTags"]
    $categoryTagItem = $categoryField.TargetItem
    if($categoryTagItem) {
        $categoryTag = Get-Tag $categoryTagItem
        $itemTags += $categoryTag
    }
    $tagsFieldItems = $tagsField.GetItems()
    foreach($tagsFieldItem in $tagsFieldItems) {
        $tagsFieldItemTag = Get-Tag $tagsFieldItem
        if($itemTags.IndexOf($tagsFieldItemTag) -eq -1) {
            $itemTags += $tagsFieldItemTag
        }
    }

    # iterate through item tags to build missing tags in strapi & attach tags to news/events
    $itemTagIds = @()
    foreach($itemTag in $itemTags) {
        # get tag id or build tag
        $tagId = $Global:newsEventTagId
        $strapiTag = $Global:strapiTags[$itemTag]
        if($strapiTag) {
            $tagId = $strapiTag.id
        } else {
            $Global:strapiTags += @{
                "$itemTag" = @{
                    id = $tagId
                    tag = $itemTag
                    locale = "en-US"
                    localizations = $null
                }
            }
            $Global:newsEventTagId++
        }
        if($itemTagIds.IndexOf($tagId) -eq -1) {
            $itemTagIds += $tagId
        }
    }

    return @{
        ids = $itemTagIds
        names = $itemTags
    }
}

function OutputType{
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Fields.ReferenceField] $typeField
	)

    if($typeField.TargetItem) {
        return $typeField.TargetItem["{856CCAE2-FBCF-4866-A3D7-84737F1D34D3}"] # resource type title field ID
    }

    return "Type output failed"
}

function TemplateCheck{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item] $item
	)
	if ($item) {
		$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item)
		if ($template.InheritsFrom($resourcesTemplate)) {
			return $item
		}
	}
}

######################################################################

$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$results = New-Object Collections.Generic.List[ResourceCsvOutput]
$redirects = New-Object Collections.Generic.List[Redirect]

$items = Get-ChildItem -path $resourcesPath -Recurse | Where-Object { TemplateCheck $_ }

foreach($item in $items) {
    $siteOutput = OutputSites $item.Fields["ResourceSites"]
    $tagOutput = OutputTags $item

    # build json output
    $jsonResult = New-Object ResourceJsonOutput
    $jsonResult.body = $item.Fields["ResourceBody"]
    $jsonResult.postDate = OutputDateField $item.Fields["ResourcePostDate"]
    $jsonResult.sites = $siteOutput.ids
    $jsonResult.tags = $tagOutput.ids
    $jsonResult.teaser = $item.Fields["ResourceTeaser"]
    $jsonResult.title = $item.Fields["ResourceTitle"]
    $jsonResult.type = OutputType $item.Fields["ResourceType"]
    
    # build csv output
    $csvResult = New-Object ResourceCsvOutput
    $csvResult.body = $jsonResult.body
    $csvResult.postDate = $jsonResult.postDate
    $csvResult.sites = $siteOutput.names
    $csvResult.tags = $tagOutput.names
    $csvResult.teaser = $jsonResult.teaser
    $csvResult.title = $jsonResult.title
    $csvResult.type = $jsonResult.type

    if ($jsonResult.type -eq "Event") {
        $eventOutput = OutputEvent $item
        $jsonResult.eventDetails = $eventOutput.data.id
        $csvResult.eventLocation = $eventOutput.data.location
        $csvResult.eventCity = $eventOutput.data.city
        $csvResult.eventState = $eventOutput.data.state
        $csvResult.eventCountry = $eventOutput.data.country
        $csvResult.eventStartDate = $eventOutput.data.startDate
        $csvResult.eventEndDate = $eventOutput.data.endDate
        $csvResult.eventUrl = $eventOutput.data.url
    }


    # handle images for exports
    $jsonResult.headerImage = OutputImage $item.Fields["ResourceImage"]
    $jsonResult.portraitImage = OutputImage $item.Fields["PortraitImage"]
    $csvResult.headerImageUrl = OutputImageUrl $item.Fields["ResourceImage"]
    $csvResult.portraitImageUrl = OutputImageUrl $item.Fields["PortraitImage"]

    $results.Add($csvResult)

    $strapiNewsEvents += @{
        $jsonResult.title = $jsonResult
    }

    # build redirect
    $redirects.Add(@{
        source = Get-Url $item
        destination = Build-Url $item $newsEventId $jsonResult.type
    })

    $newsEventId++
}

# csv/excel export
$props = @{
    Title = "News and Events Export"
    PageSize = 25
}
$results | Show-ListView @props -Property @{Label="Type"; Expression={ $_.type } },
    @{Label="Title"; Expression={ $_.title } },
    @{Label="Teaser"; Expression={ $_.teaser } },
    @{Label="Body"; Expression={ $_.body } },
    @{Label="HeaderImage"; Expression={ $_.headerImageUrl } },
    @{Label="PortraitImage"; Expression={ $_.portraitImageUrl } },
    @{Label="PostDate"; Expression={ $_.postDate } },
    @{Label="Sites"; Expression={ $_.sites } },
    @{Label="Tags"; Expression={ $_.tags } },
    @{Label="EventLocation"; Expression={ $_.eventLocation } },
    @{Label="EventCity"; Expression={ $_.eventCity } },
    @{Label="EventState"; Expression={ $_.eventState } },
    @{Label="EventCountry"; Expression={ $_.eventCountry } },
    @{Label="EventStartDate"; Expression={ $_.eventStartDate } },
    @{Label="EventEndDate"; Expression={ $_.eventEndDate} },
    @{Label="EventUrl"; Expression={ $_.eventUrl} }

# strapi export
$jsonResults = @{
    version = 2
    data = @{
        "api::news-event.news-event" = $strapiNewsEvents
        "api::news-event-tag.news-event-tag" = $strapiTags
        "blocks.event-details" = $strapiEventDetails
        "plugin::upload.file" = $strapiImages
        "plugin::upload.folder" = @{
            "NewsEventsImporter" = @{
                "name" = "Imported $StartTime"
                "files" = $strapiImageIds
            }
        }
    }
}
$jsonOutput = ""
$jsonOutput = $jsonResults | ConvertTo-Json -depth 10 -Compress
Out-Download -InputObject $jsonOutput -Name "news-events-sitecore-export.json"

# output redirects
$redirectJson = $redirects | ConvertTo-Json
Out-Download -InputObject $redirectJson -Name "news-events-strapi-redirects.json"

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################