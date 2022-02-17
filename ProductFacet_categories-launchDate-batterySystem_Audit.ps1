# get products that inherit _categorization
# verify they have launch date
# audit marketing categories IF the parent is not a super sku/family
# if battery system exists, ensure it's populated

$productPagesPath = '/sitecore/content/Milwaukee Tool/Products Repository/North America'

Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$products = Get-ChildItem $productPagesPath -Recurse
$results = New-Object Collections.Generic.List[Sitecore.Data.Items.Item]

foreach($product in $products) {
    $template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($product)
    if ($template.InheritsFrom("{4AD98F09-1131-4817-96BD-FFF47D67BDE6}")) { #_categorization
		$productCategories = $product.Fields["Marketing Categories"]
		$productLaunchDate = $product.Fields["Launch Date"]
		
		if ([string]::IsNullOrEmpty($product.Fields["Marketing Categories"])) {
			$parent = $product.Parent
			$parentTemplate = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($parent)
			$parentTemplateName = $parentTemplate.Name
			if ($parentTemplateName -NotMatch  "Family") { #-and $parentTemplateName -ne "Folder"
				Write-Host "No marketing categories for: " $product.Name
				Write-Host "    parent name: " $parent.Name " parent template: " $parentTemplateName
				$results.Add($product)
			}
		}
		
		if ([string]::IsNullOrEmpty($product.Fields["Launch Date"])) {
			Write-Host "No Launch Date for: " $product.Name
			$results.Add($product)
		}
		
		if ($template.InheritsFrom("{EF7111BB-8F88-4C72-AFFB-25B42AADE0A9}")) { #_Battery System Specification
			$batterySystem = $product.Fields["Battery System"]
			if ([string]::IsNullOrEmpty($product.Fields["Battery System"])) {
				$productTitle = $product.Fields["Title"]
				Write-Host "Oh no! Battery System is empty! Try to extract from title: " $productTitle
				$newBatterySystem = ""
				if ($productTitle -Match "M12") {
					$newBatterySystem = "M12"
				}
				if ($productTitle -Match "M18") {
					$newBatterySystem = "M18"
				}
				if ($productTitle -Match "MX") {
					$newBatterySystem = "MX FUEL"
				}
				if ($productTitle -Match "M4") {
					$newBatterySystem = "M4"
				}
				if ($productTitle -Match "M28") {
					$newBatterySystem = "M28"
				}
				if ($newBatterySystem.Length -gt 0) {
					$product.Editing.BeginEdit()
					$product.Fields["Battery System"].Value = $newBatterySystem
					$product.Editing.EndEdit()
					Write-Host "Battery System Updated to: " $newBatterySystem
				} else {
					$results.Add($product)
				}
			}
		}
	}
}

$props = @{
        Title = "Product Facet Report"
        PageSize = 50
    }
$results | Show-ListView @props -Property @{Label="Name"; Expression={$_.Fields["Title"]} }, 
    @{Label="SKU"; Expression={$_.Fields["SKU"]} },
    @{Label="ItemId"; Expression={$_.ID} },
    @{Label="Path"; Expression={$_.Paths.FullPath} },
    @{Label="Launch Date"; Expression={$_.Fields["Launch Date"]} },
    @{Label="Marketing Categories"; Expression={$_.Fields["Marketing Categories"]} },
    @{Label="Battery System"; Expression={$_.Fields["Battery System"]} }

Write-Host "------------------------" -f white
Write-Host "End Script" -f green
Write-Host "------------------------" -f white