$products = Get-Item "/sitecore/templates/Project/Milwaukee Tool/Product Types/Accessories/Press Tool Accessory" | Get-ItemReferrer

foreach($product in $products) {
    $categories = $product.Fields["Marketing Categories"]
	$replace = $categories -match "{61A3A462-8E1A-414C-9353-8EAE2E76129A}"
	if ($replace -eq "True") {
	    Write-Host "update categories " $product.DisplayName
		$newCategories = $categories -replace "{61A3A462-8E1A-414C-9353-8EAE2E76129A}", "{503A2390-78EB-44DC-BDE1-48EF203882AD}"
		Write-Host "old categories: " $categories
		Write-Host "updated categories: " $newCategories
	    $product.Editing.BeginEdit()
		$product.Fields["Marketing Categories"].Value = $categories -replace "{61A3A462-8E1A-414C-9353-8EAE2E76129A}", "{503A2390-78EB-44DC-BDE1-48EF203882AD}"
		$product.Editing.EndEdit()
	}
}