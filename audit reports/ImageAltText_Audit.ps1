<#
    .SYNOPSIS
        finds images missing alt text
    .DESCRIPTION
        tallies number of images with/without alt text
		outputs images that don't have alt text
    .NOTES
        Version:        1.0
        Author:         Geoff Morgenne
#>

$jpegUnversionedTemplate = "{DAF085E8-602E-43A6-8299-038FF171349F}"
$jpegVersionedTemplate = "{EB3FB96C-D56B-4AC9-97F8-F07B24BB9BF7}"
$imageUnversionedTemplate = "{F1828A2C-7E5D-4BBD-98CA-320474871548}"
$imageVersionedTemplate = "{C97BA923-8009-4858-BDD5-D8BE5FCCECF7}"

#$mediaLibraryPath = "/sitecore/media library"
$mediaLibraryPath = "/sitecore/media library/Banner Ads"

$results = New-Object Collections.Generic.List[Sitecore.Data.Items.Item]

######################################################################

function Is-Image{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item
	)
	
	$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item)
    if ($template.InheritsFrom($jpegUnversionedTemplate)) {
		return $item
	}
	if ($template.InheritsFrom($jpegVersionedTemplate)) {
		return $item
	}
	if ($template.InheritsFrom($imageUnversionedTemplate)) {
		return $item
	}
	if ($template.InheritsFrom($imageVersionedTemplate)) {
		return $item
	}
}

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$mediaItems = Get-ChildItem -Path $mediaLibraryPath -Recurse | Where-Object { Is-Image $_ }
$withAltCounter = 0
$noAltCounter = 0

foreach ($mediaItem in $mediaItems) {
	$alt = $mediaItem.Fields["Alt"].Value
	if ($alt.length -eq 0) {
		$noAltCounter++
		$results.Add($mediaItem)
	} else {
		$withAltCounter++
	}
}

Write-Host "Alt Text Count: " $withAltCounter 
Write-Host "No Alt Text Count: " $noAltCounter 

$props = @{
        Title = "Images without Alt Text"
        PageSize = 100
    }
$results | Show-ListView @props -Property @{Label="Name"; Expression={$_.Name} }, 
    @{Label="ItemId"; Expression={$_.ID} },
    @{Label="Path"; Expression={$_.Paths.Path} }

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################