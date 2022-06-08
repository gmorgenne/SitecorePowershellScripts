##  toggle the PPE customizer options by path
##  	can check the configurable box
##  	can add/remove the threekit rendering to product page & quickview

$searchPath = "/sitecore/content/Milwaukee Tool/Products Repository/North America/Safety/Personal Protection Equipment/Hard Hats/Safety Helmet"
#$searchPath = "/sitecore/content/Milwaukee Tool/Products Repository/North America/Safety/Personal Protection Equipment/Vests/Class 2 High Visibility Safety Vests"
#$searchPath = "/sitecore/content/Milwaukee Tool/Products Repository/North America/Safety/Personal Protection Equipment/Vests/Class 2 High Visibility Performance Safety Vests"
#$searchPath = "/sitecore/content/Milwaukee Tool/Products Repository/North America/Safety/Personal Protection Equipment/Vests/Class 3 High Visibility Safety Vest"
#$searchPath = "/sitecore/content/Milwaukee Tool/Products Repository/North America/Safety/Personal Protection Equipment/Vests/Class 2 Surveyors High Visibility Safety Vest"
#$searchPath = "/sitecore/content/Milwaukee Tool/Products Repository/North America/Safety/Personal Protection Equipment/Vests/Class 2 High Visibility Mesh Safety Vests"
#$searchPath = "/sitecore/content/Milwaukee Tool/Products Repository/North America/Safety/Personal Protection Equipment/Vests/Class-3-High-Visibility-Mesh-Safety-Vest"
$toggleConfigurable = $true
$toggleRenderings = $true
$language = "en"
$skuList = @('48-73-1101', '48-73-1200', '48-73-1201')

# ids and paths to templates & renderings
$templateIdToMatch = "{3EC763DD-0047-4220-A61D-7AB7FB6918F7}" # configurable template
$renderingToAddId = "{F070511B-1B4C-4D59-AE49-864DC37420A7}" #threekit rendering ID
$renderingToAddPath = "/sitecore/layout/Renderings/Feature/Components/ThreeKit/ThreeKit"
$placeholder = "product-split-details"
$WtbId = "{01DDBFCD-9BC9-444C-B9CD-C77E02F767F3}"

# device
$QuickViewDevice = Get-Item '/sitecore/layout/Devices/Quick View'

# setup rendering to add
$renderingInstance = Get-Item -Path $renderingToAddPath | New-Rendering -Placeholder $placeholder -Language $language #-Cacheable -VaryByData [ClearOnIndexUpdate|VaryByData|VaryByDevice|VaryByLogin|VaryByParm|VaryByQueryString|VaryByUser]


######################################################################

function Template-Check{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item
	)
	
	$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item)
	if ($template.InheritsFrom($templateIdToMatch)) {
		return $item
	}
}

function Toggle-Configurable{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item
	)
	New-UsingBlock (New-Object Sitecore.Globalization.LanguageSwitcher $language) {
		$item.Editing.BeginEdit()
		$value = $item.Fields["Configurable"].Value
		if ($value -eq 1) {
			Write-Host $item.Name " is not configurable"
			$item.Fields["Configurable"].Value = 0
		} else {
			Write-Host $item.Name " is now configurable"
			$item.Fields["Configurable"].Value = 1
		}
		$item.Editing.EndEdit()
	}
}


function Toggle-Renderings{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item
	)
	
	New-UsingBlock (New-Object Sitecore.Globalization.LanguageSwitcher $language) {
		$renderings = Get-Rendering -Item $item -Language $language -FinalLayout
		$renderingToDetermineUpdate = $renderings | Where-Object { $_.ItemID -eq $renderingToAddId }
		
		if ($renderingToDetermineUpdate.Length -eq 0) {
			$renderingToPlaceAfter = $renderings | Where-Object { $_.ItemID -eq $WtbId }
			$index = [array]::IndexOf($renderings, $renderingToPlaceAfter) + 1
			Write-Host "adding threekit rendering to PIP of " $item.Name " at index: " $index
			Add-Rendering -Item $item -Instance $renderingInstance -Placeholder $placeholder -Index $index -Language $language -FinalLayout
		} elseif ($renderingToDetermineUpdate.Length -eq 1) {
			Write-Host "removing threekit rendering from PIP of " $item.Name
			Remove-Rendering -Item $item -Instance $renderingToDetermineUpdate -Language $language -FinalLayout
		} else {
			Write-Host "MULTIPLE THREEKITS FOUND!!! removing threekit rendering from PIP of " $item.Name
			Remove-Rendering -Item $item -Instance $renderingToDetermineUpdate -Language $language -FinalLayout
		}
		
		$qvRenderings = Get-Rendering -Item $item -Device $QuickViewDevice -Language $language -FinalLayout
		$qvDetermineUpdate = $qvRenderings | Where-Object { $_.ItemID -eq $renderingToAddId }
		if ($qvDetermineUpdate.Length -eq 0) {
			$renderingToPlaceAfter = $qvRenderings | Where-Object { $_.ItemID -eq $WtbId }
			$qvIndex = [array]::IndexOf($qvRenderings, $renderingToPlaceAfter) + 1
			Write-Host "adding threekit rendering to quickview of " $item.Name " at index: " $qvIndex
			Add-Rendering -Item $item -Instance $renderingInstance -Placeholder $placeholder -Device $QuickViewDevice -Index $qvIndex -Language $language -FinalLayout
		} elseif ($qvDetermineUpdate.Length -eq 1) {
			Write-Host "removing threekit rendering from quickview of " $item.Name
			Remove-Rendering -Item $item -Instance $qvDetermineUpdate -Device $QuickViewDevice -Language $language -FinalLayout
		} else {
			Write-Host "MULTIPLE THREEKITS FOUND!!! removing threekit rendering from quickview of " $item.Name
			Remove-Rendering -Item $item -Instance $qvDetermineUpdate -Device $QuickViewDevice -Language $language -FinalLayout
		}
	}
}

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

if ($toggleConfigurable -or $toggleRenderings) {
	$products = @( Get-Item -Path $searchPath -Language $language ) + @( Get-ChildItem -Path $searchPath -Recurse -Language $language ) | Where-Object { Template-Check $_ }
	$products | ForEach-Object { 
		if ($toggleConfigurable) {
			Toggle-Configurable $_
		}
		
		if ($toggleRenderings) {
			Toggle-Renderings $_
		}
	}
} else {
	Write-Host "probably should tell this script to do something..."
}

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################