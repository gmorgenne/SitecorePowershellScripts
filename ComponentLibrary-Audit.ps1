# get all renderings
# find # of instances they are used
# list some pages they are used on

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

$renderingPath = "/sitecore/layout/Renderings/Feature/Components/Generic"
$renderings = Get-ChildItem -Path $renderingPath -Recurse
$results = New-Object Collections.Generic.List[Result]
foreach ($rendering in $renderings) {
	# use link manager to find pages with 
	$refs = $rendering | Get-ItemReferrer
	if ($refs) {
	    #Write-Host "Add rendering to output: " $rendering.Name
	    # build output object & add to results list
		$filteredRef = $refs | Where-Object Find-Examples $_
	    $r = New-Object Result
	    $r.Name = $rendering.Name
	    $r.Path = $rendering.Paths.Path
	    $r.Count = $refs.length
	    $r.Example = $filteredRef[0]
	    $results.Add($r)
	}
}

$props = @{
        Title = "Component Library Report"
        PageSize = 25
    }
$results | Show-ListView @props -Property @{Label="Name"; Expression={$_.Title} }, 
    @{Label="Path"; Expression={$_.Path} },
    @{Label="Count"; Expression={$_.Count} },
    @{Label="Example"; Expression={$_.Example} }