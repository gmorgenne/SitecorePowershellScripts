$folder = '/sitecore/content/Milwaukee Tool/Products Repository/North America/Accessories/Miscellaneous/Black Iron Press Jaws'

$products = Get-ChildItem $folder

foreach ($product in $products) {
    $template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($product)
    if ($template.InheritsFrom("{3F911AA6-6C99-4D21-8645-581FD0A41359}")) { #accessory families
		$children = Get-ChildItem $product.Paths.Path
		foreach ($child in $children) {
		    $childTemplate = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($child)
		    if ($childTemplate.InheritsFrom("{8CEFD68F-7612-4805-A4F4-567FEB087F35}")) { #_accessory
		        Write-Host $child.DisplayName
		        $child.Editing.BeginEdit()
		        $child.Fields["Marketing Categories"].Value = ""
		        $child.Editing.EndEdit()
		    }
		}
	}
}