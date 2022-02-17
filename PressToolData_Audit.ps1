# audit for press tool data

$searchPath1 = '/sitecore/content/Milwaukee Tool/Products Repository/North America/Accessories/Miscellaneous/Black Iron Press Jaws'
$searchPath2 = '/sitecore/content/Milwaukee Tool/Products Repository/North America/Accessories/Miscellaneous/Press Tool Jaws and Rings'
$searchPath3 = '/sitecore/content/Milwaukee Tool/Products Repository/North America/Power Tools/Cordless/Press Tools'

$templateToChange = '{DEB4CE12-23EF-416E-8189-DF876CE5AF0C}' #Accessory
$newTemplatePath = '/sitecore/templates/Project/Milwaukee Tool/Product Types/Accessories/Press Tool Accessory'

class Product
{
	[String] $Name
	[String] $SKU
	[String] $ID
	[String] $LaunchDate
	[String] $BatterySystem
	[String] $CompatibleJaws
	[String] $FittingSystem
	[String] $Sizes
}

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$pages = @( Get-ChildItem $searchPath1 -recurse ) + @( Get-ChildItem $searchPath2 -recurse ) + @( Get-ChildItem $searchPath3 -recurse )
$pages = $pages | Where-Object { (Get-Rendering -Item $_ -FinalLayout) -ne $null }
$results = New-Object Collections.Generic.List[Product]

foreach($page in $pages) {
	$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($page)
	if ($template.InheritsFrom("{13C2D59A-9D67-49DF-9AD1-379473355A34}")) { #Cordless Press Tool
	
		$compatibleJawsField = [Sitecore.Data.Fields.MultilistField]$page.Fields["Compatible Jaws"]
		$compatibleJawsItems = $compatibleJawsField.GetItems()
		$compatibleJaws = ''
		
		if ($compatibleJawsItems.Length -gt 0) {
			foreach($compatibleJawsItem in $compatibleJawsItems) {
				#$compatibleJaws += $compatibleJawsItem.Fields["Title"]
				$compatibleJaws += $compatibleJawsItem.Fields["SKU"]
				$compatibleJaws += "|"
			}
			$compatibleJaws = $compatibleJaws.Substring(0,$compatibleJaws.Length-1)
		}
		
		$p = New-Object Product
		$p.Name = $page.Fields["Title"]
		$p.SKU = $page.Fields["SKU"]
		$p.ID = $page.ID
		$p.LaunchDate = $page.Fields["Launch Date"]
		$p.BatterySystem = $page.Fields["Battery System"]
		$p.CompatibleJaws = $compatibleJaws
		$p.FittingSystem = "N/A"
		$p.Sizes = "N/A"
		$results.Add($p)
	}
	if ($template.InheritsFrom("{36C3B139-FF7D-4FAB-A2F3-20AD169B0665}")) { #Press Tool Accessory
		$fittingSystemsField = [Sitecore.Data.Fields.MultilistField]$page.Fields["Fitting Systems"]
		$fittingSystemsItems = $fittingSystemsField.GetItems()
		$fittingSystems = ''
		
		$sizeField = [Sitecore.Data.Fields.MultilistField]$page.Fields["Sizes"]
		$sizeItems = $sizeField.GetItems()
		$sizes = ''
		
		if ($fittingSystemsItems.Length -gt 0) {
			foreach($fittingSystemsItem in $fittingSystemsItems) {
				$fittingSystem = $fittingSystemsItem.Name
				
				if ($fittingSystemsItem.Fields["__Display Name"].Value.Length -gt 0) {
					$fittingSystem = $fittingSystemsItem.Fields["__Display Name"]
				}
			
				$fittingSystems += $fittingSystem
				$fittingSystems += "|"
			}
			$fittingSystems = $fittingSystems.Substring(0,$fittingSystems.Length-1)
		}
		if ($sizeItems.Length -gt 0) {
			foreach($sizeItem in $sizeItems) {
				$sizes += $sizeItem.Fields["Value"]
				$sizes += "|"
			}
			$sizes = $sizes.Substring(0,$sizes.Length-1)
		}
	
		$p = New-Object Product
		$p.Name = $page.Fields["Title"]
		$p.SKU = $page.Fields["SKU"]
		$p.ID = $page.ID
		$p.LaunchDate = $page.Fields["Launch Date"]
		$p.BatterySystem = "N/A"
		$p.CompatibleJaws = "N/A"
		$p.FittingSystem = $fittingSystems
		$p.Sizes = $sizes
		$results.Add($p)
	}
}

$props = @{
        Title = "Press Tool Accessory and Product Report"
        PageSize = 100
    }
$results | Show-ListView @props -Property @{Label="Name"; Expression={$_.Name} }, 
    @{Label="SKU"; Expression={$_.SKU} },
    @{Label="ItemId"; Expression={$_.ID} },
    @{Label="Launch Date"; Expression={$_.LaunchDate} },
    @{Label="Battery System"; Expression={$_.BatterySystem} },
    @{Label="Compatible Jaws"; Expression={$_.CompatibleJaws} },
    @{Label="Fitting Systems"; Expression={$_.FittingSystem} },
    @{Label="Sizes"; Expression={$_.Sizes} }



$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################