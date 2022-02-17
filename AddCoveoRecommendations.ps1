####  get all products
####  if they don't have coveo recommendations, add them


# path to get items to update
#$searchPath = "/sitecore/templates/Foundation/Products"
#$searchPath = "/sitecore/templates/Project/Milwaukee Tool/Product Types"
$searchPath = "/sitecore/content/Milwaukee Tool/Products Repository/North America"

### renderings variables
$recommendationsRenderingID = "{107FFF11-CA26-4E0D-B96A-25D5174E0521}"
$recommendationsRenderingPath = "/sitecore/layout/Renderings/Feature/Search/Recommendations"
$recommendationsDatasourceID = "{A79DB51A-0586-4069-B968-D4B5D4BB7957}"
$recommendationsDatasourcePath = "/sitecore/content/Milwaukee Tool/Global/Global Search Components/Recommendations"
$recommendationsPlaceholder = "/page-content/product-content/product-tab-keyfeatures"

$c4SaRenderingID = "{92C178C0-380C-4F10-AC63-0E7AC0B0E629}"
$c4SaRenderingPath = "/sitecore/layout/Renderings/Feature/Search/Coveo For Sitecore Analytics"
$c4SaDatasourceID = "{74596111-FEFC-42C6-9DD3-B72875B3DFB5}"
$c4SaDatasourcePath = "/sitecore/content/Milwaukee Tool/Global/Global Search Components/Coveo For Sitecore Analytics - Default"
$c4SaPlaceholder = "/page-content/product-content/product-tab-keyfeatures/recommendations-components"

$queryFilterRenderingID = "{FEF56A4A-155C-495F-BD38-4B12C857656C}"
$queryFilterRenderingPath = "/sitecore/layout/Renderings/Feature/Search/Query Filter"
$queryFilterDatasourceID = "{25E98EAE-66D8-426D-A4E6-E8FABC86C969}"
$queryFilterDatasourcePath = "/sitecore/content/Milwaukee Tool/Global/Global Search Components/Query Filter"
$queryFilterPlaceholder = "/page-content/product-content/product-tab-keyfeatures/recommendations-components"

$recommendationsListRenderingID = "{9854861D-18F0-453A-87DF-ACD5FF3AC7AA}"
$recommendationsListRenderingPath = "/sitecore/layout/Renderings/Feature/Search/Recommendations Result List"
$recommendationsListDatasourceID = "{1147BF0F-E155-4704-84C3-8A1DE86D995E}"
$recommendationsListDatasourcePath = "/sitecore/content/Milwaukee Tool/Global/Global Search Components/Global Result Templates Folder/Result Template - Products"
$recommendationsListPlaceholder = "/page-content/product-content/product-tab-keyfeatures/result-list"

$recommendationsResultRenderingID = "{338B61D6-AD95-447E-A485-52EE7E06584C}"
$recommendationsResultRenderingPath = "/sitecore/layout/Renderings/Feature/Search/Result Template - Products Recommendations"
$recommendationsResultDatasourceID = "{83133C68-C9D4-4E57-BD2E-838B096A6C20}"
$recommendationsResultDatasourcePath = "/sitecore/content/Milwaukee Tool/Global/Global Search Components/Global Result List Folder/Default Results List"
#$recommendationsResultPlaceholder = "/page-content/product-content/product-tab-keyfeatures/result-list/result-templates-{ef6c3b93-ddbd-4041-a8e3-2aeb404d5236}-0"
#$recommendationsResultPlaceholder = "/page-content/product-content/product-tab-keyfeatures/result-list/result-templates-{D547A88A-B34B-4FFF-B521-0914667E6C09}-0"   ### ON QA
#$recommendationsResultPlaceholder = "/page-content/product-content/product-tab-keyfeatures/result-list/result-templates-{414CF377-3A08-4907-9D75-69FD60F01609}-0"

# set up new renderings to add
$recommendationsRendering = Get-Item -Path $recommendationsRenderingPath | New-Rendering -Placeholder $recommendationsPlaceholder
$c4SaRendering = Get-Item -Path $c4SaRenderingPath | New-Rendering -Placeholder $c4SaPlaceholder
$queryFilterRendering = Get-Item -Path $queryFilterRenderingPath | New-Rendering -Placeholder $queryFilterPlaceholder
$recommendationsListRendering = Get-Item -Path $recommendationsListRenderingPath | New-Rendering -Placeholder $recommendationsListPlaceholder
$recommendationsResultRendering = Get-Item -Path $recommendationsResultRenderingPath | New-Rendering #-Placeholder $recommendationsResultPlaceholder

$recommendationsListRenderingUniqueId = $recommendationsListRendering.UniqueId

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$pages = @( Get-ChildItem $searchPath -recurse) 
$pages = $pages | Where-Object { (Get-Rendering -Item $_ -FinalLayout) -ne $null }

foreach ($page in $pages) {
	$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($page)
    if ($template.InheritsFrom("{A819D3F6-DD02-47DD-9897-5BA714E39152}")) { #base product

		# add in check that marketing categories is populated?
		$marketingCategories = $page.Fields["Marketing Categories"].Value
		if ($marketingCategories.Length -eq 0) {
			Write-Host "marketing categories are empty for $($page.Name), so don't add recommendations"
			continue
		}

		# reset placeholders if they changed on the last run
		$recommendationsPlaceholder = "/page-content/product-content/product-tab-keyfeatures"
		$c4SaPlaceholder = "/page-content/product-content/product-tab-keyfeatures/recommendations-components"
		$queryFilterPlaceholder = "/page-content/product-content/product-tab-keyfeatures/recommendations-components"
		$recommendationsListPlaceholder = "/page-content/product-content/product-tab-keyfeatures/result-list"
		$recommendationsResultPlaceholder = "/page-content/product-content/product-tab-keyfeatures/result-list/result-templates"

		## check if accessory family or combo kit because they don't have regular product tabs
		if ($template.InheritsFrom("{3F911AA6-6C99-4D21-8645-581FD0A41359}")) { #accessory family
			$recommendationsPlaceholder = "/page-content/product-content/accessory-tab-features-specs"
			$c4SaPlaceholder = "/page-content/product-content/accessory-tab-features-specs/recommendations-components"
			$c4SaPlaceholder = "/page-content/product-content/accessory-tab-features-specs/recommendations-components"
			$recommendationsListPlaceholder = "/page-content/product-content/accessory-tab-features-specs/result-list"
			$recommendationsResultPlaceholder = "/page-content/product-content/accessory-tab-features-specs/result-list/result-templates"
		}
		if ($template.InheritsFrom("{5C58FC8F-106B-4780-BECA-B6B7F5AA0443}")) { #combo kit
			$recommendationsPlaceholder = "/page-content/product-content/combo-kit-tab-included"
			$c4SaPlaceholder = "/page-content/product-content/combo-kit-tab-included/recommendations-components"
			$c4SaPlaceholder = "/page-content/product-content/combo-kit-tab-included/recommendations-components"
			$recommendationsListPlaceholder = "/page-content/product-content/combo-kit-tab-included/result-list"
			$recommendationsResultPlaceholder = "/page-content/product-content/combo-kit-tab-included/result-list/result-templates"
		}

		$renderings = Get-Rendering -Item $page
		# check recommendations
		$renderingToDetermineUpdate1 = $renderings | Where-Object { $_.ItemID -eq $recommendationsRenderingID }
		if ($renderingToDetermineUpdate1.Length -eq 0) {
			Write-Host $page.Paths.FullPath " missing recommendations component"
		#	Add-Rendering -Item $page -Instance $recommendationsRendering -Datasource $recommendationsDatasourceID -Placeholder $recommendationsPlaceholder
		}
		if ($renderingToDetermineUpdate1.Length -gt 1) {
			Write-Host $page.Name " has multiple recommendations components"
		#	Remove-Rendering -Item $page -Instance $renderingToDetermineUpdate1[-1]
		}
		
		# check Coveo for Sitecore Analytics
		$renderingToDetermineUpdate2 = $renderings | Where-Object { $_.ItemID -eq $c4SaRenderingID }
		if ($renderingToDetermineUpdate2.Length -eq 0) {
			Write-Host $page.Name " missing coveo for sitecore analytics component"
		#	Add-Rendering -Item $page -Instance $c4SaRendering -Datasource $c4SaDatasourceID -Placeholder $c4SaPlaceholder
		}
		if ($renderingToDetermineUpdate2.Length -gt 1) {
			Write-Host $page.Name " has multiple coveo for sitecore analytics components"
		#	Remove-Rendering -Item $page -Instance $renderingToDetermineUpdate2[-1]
		}
		
		# check query filter
		$renderingToDetermineUpdate3 = $renderings | Where-Object { $_.ItemID -eq $queryFilterRenderingID }
		if ($renderingToDetermineUpdate3.Length -eq 0) {
			Write-Host $page.Name " missing query filter component"
		#	Add-Rendering -Item $page -Instance $queryFilterRendering -Datasource $queryFilterDatasourceID -Placeholder $queryFilterPlaceholder
		}
		if ($renderingToDetermineUpdate3.Length -gt 1) {
			Write-Host $page.Name " has multiple query filter components"
		#	Remove-Rendering -Item $page -Instance $renderingToDetermineUpdate3[-1]
		}
		
		# check recommendations result list
		$renderingToDetermineUpdate4 = $renderings | Where-Object { $_.ItemID -eq $recommendationsListRenderingID }
		if ($renderingToDetermineUpdate4.Length -eq 0) {
			Write-Host $page.Name " missing result list component"
		#	Add-Rendering -Item $page -Instance $recommendationsListRendering -Datasource $recommendationsListDatasourceID -Placeholder $recommendationsListPlaceholder
		}
		if ($renderingToDetermineUpdate4.Length -gt 1) {
			Write-Host $page.Name " has multiple result list components"
		#	Remove-Rendering -Item $page -Instance $renderingToDetermineUpdate4[-1]
		}
		
		# check recommendations result template
		$renderingToDetermineUpdate5 = $renderings | Where-Object { $_.ItemID -eq $recommendationsResultRenderingID }
		if ($renderingToDetermineUpdate5.Length -eq 0) {
			Write-Host $page.Name " missing result template component, calculating placeholder..."
			
			#find result list rendering's unique id for placeholder
			$renderings = Get-Rendering -Item $page
			$rlr = $renderings | Where-Object { $_.ItemID -eq $recommendationsListRenderingID }
			if ($rlr.Length -gt 0) {
				$rlUniqueId = $rlr[0].UniqueId
				$recommendationsResultPlaceholder += "-$($rlUniqueId)-0"
				Write-Host "recommendations result template placeholder: " $recommendationsResultPlaceholder
				#	Add-Rendering -Item $page -Instance $recommendationsResultRendering -Datasource $recommendationsResultDatasourceID -Placeholder $recommendationsResultPlaceholder
			} else {
				Write-Host "result list not on page, placeholder can't be calculated"
			}
		}
		if ($renderingToDetermineUpdate5.Length -gt 1) {
			Write-Host $page.Name " has multiple result template components"
		#	Remove-Rendering -Item $page -Instance $renderingToDetermineUpdate5[-1]
		}
	}
}
	
$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################