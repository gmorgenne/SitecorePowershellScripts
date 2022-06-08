# Script for finding products that are missing another language

class Product
{
	[String] $DisplayName
	[String] $SKU
	[String] $ItemId
	[String] $Path
	[String] $LanguageList
	[String] $MissingLanguageList
}

$products = Get-ChildItem -Path 'master://sitecore/content/Milwaukee Tool/Products Repository/North America' -Recurse 
$device = Get-LayoutDevice -Default
$Results = New-Object Collections.Generic.List[Product]

foreach($product in $products) {
    $template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($product)
    if ($template.InheritsFrom("{A819D3F6-DD02-47DD-9897-5BA714E39152}")) { #base product
		$p = New-Object Product
		$p.DisplayName = $product.DisplayName
		$p.SKU = $product.Fields["SKU"]
		$p.ItemId = $product.ID
		$p.Path = $product.Paths.FullPath
		$p.LanguageList = ''
		$p.MissingLanguageList = ''
		
		foreach ($version in $product.Versions.GetVersions($true))
		{
			if ($version.Language -eq "en" -OR $version.Language -eq "es-US" -OR $version.Language -eq "en-CA" -OR $version.Language -eq "fr-CA"  )
			{
				if($p.LanguageList -NotMatch $version.Language){
					$p.LanguageList += "$($version.Language) "
				}
			}
		} 
		if($p.LanguageList -NotMatch "fr-CA"){
			$p.MissingLanguageList += "fr-CA "
		}
		if($p.LanguageList -NotMatch "es-US"){
			$p.MissingLanguageList += "es-US "
		}
		if($p.LanguageList -NotMatch "en-CA"){
			$p.MissingLanguageList += "en-CA "
		}
					
		if($p.LanguageList -NotMatch "fr-CA" -OR $p.LanguageList -NotMatch "es-US" -OR $p.LanguageList -NotMatch "en-CA"){
			$Results.Add($p)
		}
    }
}
if ($Results.Count -gt 0) {
	$props = @{
        Title = "Products Language Version Audit"
        PageSize = 25
    }
	$Results | 
		Show-ListView @props -Property @{Label="Name"; Expression={$_.DisplayName} },
		@{Label="ID"; Expression={$_.ItemId} },
		@{Label="SKU"; Expression={$_.SKU} },
		@{Label="LanguageList"; Expression={$_.LanguageList} },
		@{Label="MissingLanguageList"; Expression={$_.MissingLanguageList} },
		@{Label="Path"; Expression={$_.Path} }
}