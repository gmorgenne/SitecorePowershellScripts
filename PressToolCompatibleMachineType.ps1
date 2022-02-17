# find all press tool accessories
# set compatible machine based on category field
#m12: 2473-20
#m18: 2773-20 & 2922-20
#m18 short: 2674
#m18 long: 2773-20L

#Concrete Drilling and Chiseling is already a facet and is 32 characters long
$m12Category = "{591FEC26-AB9D-4D6A-A13D-582683360E08}"
$m12Label = "M12™ FORCE LOGIC™ Press Tool (2473)"
$m18Category = "{826E3D5C-DBA3-41E9-B6ED-FC2CA312E181}"
$m18Label = "M18™ FORCE LOGIC™ Press Tool (2773)|M18™ FORCE LOGIC™ Press Tool w/ ONE-KEY™ (2922)"
$m18ShortCategory = "{A88D718F-6FEF-41AA-93B3-80A130BC0FE4}"
$m18ShortLabel = "M18™ Short Throw (2674)"
$m18LongCategory = "{B6D1C252-70D4-44F6-A728-403D38724F47}"
$m18LongLabel = "M18™ Long Throw (2773-20L)"
$products = Get-Item "/sitecore/templates/Project/Milwaukee Tool/Product Types/Accessories/Press Tool Accessory" | Get-ItemReferrer

foreach($product in $products) {
    $categories = $product.Fields["Category"]
	$m12 = $categories -match $m12Category
	$m18 = $categories -match $m18Category
	$m18Short = $categories -match $m18ShortCategory
	$m18Long = $categories -match $m18LongCategory
	$compatibleMachineType = ""
	if ($m12 -eq "True") {
	    Write-Host "m12 updating " $product.DisplayName
		if ($compatibleMachineType.Length -gt 0) {
			$compatibleMachineType += "|" + $m12Label
		} else {
			$compatibleMachineType = $m12Label
		}
	}
	if ($m18 -eq "True") {
	    Write-Host "m18 updating " $product.DisplayName
		if ($compatibleMachineType.Length -gt 0) {
			$compatibleMachineType += "|" + $m18Label
		} else {
			$compatibleMachineType = $m18Label
		}
	}
	if ($m18Short -eq "True") {
	    Write-Host "m18 short updating " $product.DisplayName
		if ($compatibleMachineType.Length -gt 0) {
			$compatibleMachineType += "|" + $m18ShortLabel
		} else {
			$compatibleMachineType = $m18ShortLabel
		}
	}
	if ($m18Long -eq "True") {
	    Write-Host "m18 long updating " $product.DisplayName
		if ($compatibleMachineType.Length -gt 0) {
			$compatibleMachineType += "|" + $m18LongLabel
		} else {
			$compatibleMachineType = $m18LongLabel
		}
	}
	if ($compatibleMachineType.Length -gt 0) {
		Write-Host "setting: " $product.DisplayName " compatibleMachineType: " $compatibleMachineType
		$product.Editing.BeginEdit()
		$product.Fields["Compatible Machine Type"].Value = $compatibleMachineType
		$product.Editing.EndEdit()
	}
}