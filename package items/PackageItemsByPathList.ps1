$pathsToInclude = @(
    'master:/sitecore/layout/layouts/Project/Company',
    'master:/sitecore/layout/renderings/Feature/Company',
    'core:/sitecore/templates/Foundation'
)

######################################################################

function Get-NameByPath{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][string]$path
	)
	
	$output = ""
    $pathSplit = $path.split("/")
    $first, $second, $third, $rest = $pathSplit
    
    if ($rest -is [string]) {
        $output = "$third $rest"
    } else {
        $output = [system.String]::Join(" ",  $rest)    
    }

	return $output
}

######################################################################

$package = New-Package "ItemPackage-$(Get-Date -Format "yyyy-MM-dd-HH-mm")"
$package.Sources.Clear()

# Items using New-ItemSource and New-ExplicitItemSource
foreach ($path in $pathsToInclude) {
    $sourceName = Get-NameByPath $path
    $source = Get-Item -Path $path | 
        New-ItemSource -Name $sourceName -InstallMode Overwrite
    $package.Sources.Add($source)
}

# Files using New-FileSource and New-ExplicitFileSource
# $source = Get-Item -Path "$AppPath\App_Config\Include\Feature\Forms\Company.Feature.Forms.config" | 
#     New-ExplicitFileSource -Name "Feature Forms Files"
# $package.Sources.Add($source)

Export-Package -Project $package -Path "$($package.Name).xml"
Export-Package -Project $package -Path "$($package.Name).zip" -Zip
Download-File "$SitecorePackageFolder\$($package.Name).zip"