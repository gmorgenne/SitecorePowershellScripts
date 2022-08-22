<#
    .SYNOPSIS
        outputs audit of renderings from feature layer
    .DESCRIPTION
        gets all renderings by path, 
		counts links with link manager, 
		finds an example of where it's used in the content node
    .NOTES
        Version:        1.0
        Author:         Geoff Morgenne
#>

# update this if needed:
$renderingPath = "/sitecore/layout/Renderings/Feature"

class Result
{
    [String] $Name
    [String] $Path
    [Int] $Count
    [String] $Example
}

function Find-Examples{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$ref
	)
	if ($ref.Paths.Path.Contains("/sitecore/content")) {
	    return $ref
	}
}

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$renderings = Get-ChildItem -Path $renderingPath -Recurse
$results = New-Object Collections.Generic.List[Result]
foreach ($rendering in $renderings) {
	#Write-Host "Add rendering to output: " $rendering.Name
	
	# use link manager to find pages with 
	$refs = $rendering | Get-ItemReferrer
	$example = "none"
	$count = 0
	if ($refs) {
		$filteredRefs = $refs | Where-Object { Find-Examples $_ }
		if ($filteredRefs) {
			$count = $refs.length
			$example = $filteredRefs[0].Paths.Path
		}
	}
	# build output object & add to results list
	$r = New-Object Result
	$r.Name = $rendering.Name
	$r.Path = $rendering.Paths.Path
	$r.Count = $count
	$r.Example = $example
	$results.Add($r)
}

$props = @{
        Title = "Component Library Report"
        PageSize = 25
    }
$results | Show-ListView @props -Property @{Label="Name"; Expression={$_.Title} }, 
    @{Label="Path"; Expression={$_.Path} },
    @{Label="Count"; Expression={$_.Count} },
    @{Label="Example"; Expression={$_.Example} }

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################