# audit for press tool fitting system data

$searchPath = '/sitecore/content/Global/Options/Press Tool Fitting Systems'

class Product
{
	[String] $Name
	[String] $ID
	[String] $Materials
	[String] $Sizes
}

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$items = @( Get-ChildItem $searchPath -recurse )
$results = New-Object Collections.Generic.List[Product]

foreach($item in $items) {
	$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item)
	if ($template.InheritsFrom("{F6AD4CB2-AD9C-41FD-8EA9-C178E3C0CFC3}")) { # Press Tool Fitting System
		$materialField = [Sitecore.Data.Fields.MultilistField]$item.Fields["Materials"]
		$materialItems = $materialField.GetItems()
		$sizeField = [Sitecore.Data.Fields.MultilistField]$item.Fields["Sizes"]
		$sizeItems = $sizeField.GetItems()
		$itemName = $item.Name
		$materials = ''
		$sizes = ''
		
		if ($materialItems.Length -gt 0) {
			foreach($materialItem in $materialItems) {
				$materials += $materialItem.Fields["Full Name"] 
				$materials += "|"
			}
			 $materials = $materials.Substring(0,$materials.Length-1)
		}
		if ($sizeItems.Length -gt 0) {
			foreach($sizeItem in $sizeItems) {
				$sizes += $sizeItem.Fields["Value"]
				$sizes += "|"
			}
			$sizes = $sizes.Substring(0,$sizes.Length-1)
		}
		if ($item.Fields["__Display Name"].Value.Length -gt 0) {
			$itemName = $item.Fields["__Display Name"]
		}
		
		$p = New-Object Product
		$p.Name = $itemName
		$p.ID = $item.ID
		$p.Materials = $materials
		$p.Sizes = $sizes
		$results.Add($p)
	}
}

$props = @{
        Title = "Press Tool Fitting System Report"
        PageSize = 25
    }
$results | Show-ListView @props -Property @{Label="Name"; Expression={$_.Name} }, 
    @{Label="Id"; Expression={$_.ID} },
    @{Label="Materials"; Expression={$_.Materials} },
    @{Label="Sizes"; Expression={$_.Sizes} }

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################