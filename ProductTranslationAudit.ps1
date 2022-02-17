# audit product translations by search path
$searchPath = "master:/sitecore/content/Milwaukee Tool/Products Repository/North America"
$baseExportPath = "C:\inetpub\wwwroot\temp\"
#$baseExportPath = "D:\temp\"
$exportName = "ProductsMissingLanguages.csv"
$ECexportName = "ProductsMissingEC.csv"
$ESexportName = "esProductsInEnglish.csv"
$FRexportName = "frProductsInEnglish.csv"
$exportPath = $baseExportPath + $exportName
$ECexportPath = $baseExportPath + $ECexportName
$ESexportPath = $baseExportPath + $ESexportName
$FRexportPath = $baseExportPath + $FRexportName
$listView = $false
$email = $true
$recipients = 'geoff.morgenne@milwaukeetool.com'
#$recipients = @('geoff.morgenne@milwaukeetool.com', 'Peter.Vallas@ttigroupna.com', 'eduardo.resendiz@milwaukeetool.com', 'Yvonne.Chan@ttigroupna.com', 'paul.simmerman@milwaukeetool.com')
$uploadToBlob = $true
$blobContainerName = 'product-translation-audit'
#uncomment this and update the blobUploader to change blob storage location
#$blobConnectionString = 'DefaultEndpointsProtocol=http;AccountName=devstoreaccount1; AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;'

# initialize counters
$enCATranslatedAccessories = $enCATranslatedComboKits = $enCATranslatedEquipment = $enCATranslatedGloves = $enCATranslatedSafety = $enCATranslatedHandTools = $enCATranslatedInstruments = $enCATranslatedPowerTools = $enCATranslatedPackout = $enCATranslatedVariant = 0
$frCATranslatedAccessories = $frCATranslatedComboKits = $frCATranslatedEquipment = $frCATranslatedGloves = $frCATranslatedSafety = $frCATranslatedHandTools = $frCATranslatedInstruments = $frCATranslatedPowerTools = $frCATranslatedPackout = $frCATranslatedVariant = 0
$esUSTranslatedAccessories = $esUSTranslatedComboKits = $esUSTranslatedEquipment = $esUSTranslatedGloves = $esUSTranslatedSafety = $esUSTranslatedHandTools = $esUSTranslatedInstruments = $esUSTranslatedPowerTools = $esUSTranslatedPackout = $esUSTranslatedVariant = 0
$totalAccessories = $totalComboKits = $totalEquipment = $totalGloves = $totalSafety = $totalHandTools = $totalInstruments = $totalPowerTools = $totalPackout = $totalVariant = 0
$frCAParsedTranslatedAccessories = $frCAParsedTranslatedComboKits = $frCAParsedTranslatedEquipment = $frCAParsedTranslatedGloves = $frCAParsedTranslatedSafety = $frCAParsedTranslatedHandTools = $frCAParsedTranslatedInstruments = $frCAParsedTranslatedPowerTools = $frCAParsedTranslatedPackout = $frCAParsedTranslatedVariant = 0
$esUSParsedTranslatedAccessories = $esUSParsedTranslatedComboKits = $esUSParsedTranslatedEquipment = $esUSParsedTranslatedGloves = $esUSParsedTranslatedSafety = $esUSParsedTranslatedHandTools = $esUSParsedTranslatedInstruments = $esUSParsedTranslatedPowerTools = $esUSParsedTranslatedPackout = $esUSParsedTranslatedVariant = 0
$ECenCATranslatedAccessories = $ECenCATranslatedComboKits = $ECenCATranslatedEquipment = $ECenCATranslatedGloves = $ECenCATranslatedSafety = $ECenCATranslatedHandTools = $ECenCATranslatedInstruments = $ECenCATranslatedPowerTools = $ECenCATranslatedPackout = $ECenCATranslatedVariant = 0
$ECfrCATranslatedAccessories = $ECfrCATranslatedComboKits = $ECfrCATranslatedEquipment = $ECfrCATranslatedGloves = $ECfrCATranslatedSafety = $ECfrCATranslatedHandTools = $ECfrCATranslatedInstruments = $ECfrCATranslatedPowerTools = $ECfrCATranslatedPackout = $ECfrCATranslatedVariant = 0
$ECesUSTranslatedAccessories = $ECesUSTranslatedComboKits = $ECesUSTranslatedEquipment = $ECesUSTranslatedGloves = $ECesUSTranslatedSafety = $ECesUSTranslatedHandTools = $ECesUSTranslatedInstruments = $ECesUSTranslatedPowerTools = $ECesUSTranslatedPackout = $ECesUSTranslatedVariant = 0
$ECtotalAccessories = $ECtotalComboKits = $ECtotalEquipment = $ECtotalGloves = $ECtotalSafety = $ECtotalHandTools = $ECtotalInstruments = $ECtotalPowerTools = $ECtotalPackout = $ECtotalVariant = 0
$totalAccessoriesItems = $totalComboKitsItems = $totalEquipmentItems = $totalGlovesItems = $totalSafetyItems = $totalHandToolsItems = $totalInstrumentsItems = $totalPowerToolsItems = $totalPackoutItems = $totalVariantItems = 0
$ECtotalAccessoriesItems = $ECtotalComboKitsItems = $ECtotalEquipmentItems = $ECtotalGlovesItems = $ECtotalSafetyItems = $ECtotalHandToolsItems = $ECtotalInstrumentsItems = $ECtotalPowerToolsItems = $ECtotalPackoutItems = $ECtotalVariantItems = 0
$Results = @()
$ECResults = @()
$EsInEnResults = @()
$FrInEnResults = @()

######################################################################
function Filter-Items {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item
	)
	
	$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item)
    if ($template.InheritsFrom("{4AD98F09-1131-4817-96BD-FFF47D67BDE6}")) { #_categorization
		return $item
	}
	if ($template.InheritsFrom("{20452D9A-31C3-4B8C-9D5E-8F54224D9A23}")) { #Variant
		return $item
	}
}

function BuildLanguageList {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item
	)
	
	$languageList = ""
	foreach ($version in $item.Versions.GetVersions($true)) {
        if ($version.Language -eq "en-US" -OR $version.Language -eq "es-US" -OR $version.Language -eq "en-CA" -OR $version.Language -eq "fr-CA"  ) {
            if($languageList -NotMatch $version.Language){
                $languageList += "$($version.Language) " 
            }
        }
    }
	return $languageList
}

function OutputForFrench {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item,
		[Parameter(Mandatory=$true, Position=1)][string]$category
	)
	
	$i = Get-Item -path $item.Paths.Path -language "fr-CA"
	$overview = ''
	$sku = ''
	$title = ''
	if ($i) {
		$o = $i.Fields["Overview"].Value
		if ($o) {
			$overview = $o
		}
		$s = $i.Fields["SKU"].Value
		if ($s) {
			$sku = $s
		}
		$t = $i.Fields["Title"].Value
		if ($t) {
			$title = $t
		}
	}
	return @{
		Category = $category
		Overview = $overview
		SKU = $sku
		Title = $title
		ItemPath = $item.Paths.FullPath
	}
}

function OutputForSpanish {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item,
		[Parameter(Mandatory=$true, Position=1)][string]$category
	)
	
	$i = Get-Item -path $item.Paths.Path -language "es-US"
	$overview = ''
	$sku = ''
	$title = ''
	if ($i) {
		$o = $i.Fields["Overview"].Value
		if ($o) {
			$overview = $o
		}
		$s = $i.Fields["SKU"].Value
		if ($s) {
			$sku = $s
		}
		$t = $i.Fields["Title"].Value
		if ($t) {
			$title = $t
		}
	}
	return @{
		Category = $category
		Overview = $overview
		SKU = $sku
		Title = $title
		ItemPath = $item.Paths.FullPath
	}
}

function ParseForFrench {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item
	)
	
	$i = Get-Item -path $item.Paths.Path -language "fr-CA"
	if ($i) {
		$overview = $i.Fields["Overview"].Value
		if ($overview) {
			@('à','è','ì','ò','ù','é','ç','â','ê','î','ô','û','ë','ï','ü') | foreach-object {
				if ($overview -match $_) {
					return $true
				}
			}
		}
	}
	return $false
}

function ParseForSpanish {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item
	)
	
	$i = Get-Item -path $item.Paths.Path -language "es-US"
	if ($i) {
		$overview = $i.Fields["Overview"].Value
		if ($overview) {
			@('á','é','í','ó','ú', 'ñ', 'ü', '¿') | foreach-object {
				if ($overview -match $_) {
					return $true
				}
			}
		}
	}
	return $false
}

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white
$allItems = Get-ChildItem -Path $searchPath -Recurse | Where-Object { Filter-Items $_ }

$allItems | ForEach-Object {
	$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($_)
	
	# build language list to determine existing languages
	$languageList = BuildLanguageList $_
	$existingEnCa = $existingFrCa = $existingEsUs = $false
	$likelyFrCa = $likelyEsUs = $false
	$ec = $ECexistingEnCa = $ECexistingFrCa = $ECexistingEsUs = $false
	
	if($languageList -Match "en-CA"){
		$existingEnCa = $true
	}
	if($languageList -Match "fr-CA"){
		$existingFrCa = $true
		$likelyFrCa = ParseForFrench $_
	}
	if($languageList -Match "es-US"){
		$existingEsUs = $true
		$likelyEsUs = ParseForSpanish $_
	}
	
	$enhancedContentFolder = Get-ChildItem -Path $_.Paths.Path | Where-Object { $_.TemplateName -eq "Components Folder" }
	if ($enhancedContentFolder -and $enhancedContentFolder.HasChildren) {
		$ec = $true
		$ECexistingEnCa = $true
		$ECexistingFrCa = $true
		$ECexistingEsUs = $true
		$ecItems = Get-ChildItem $enhancedContentFolder.Paths.Path -Recurse | ForEach-Object {
			$ecLangList = BuildLanguageList $_
			if ($ecLangList -NotMatch "en-CA") {
				$ECexistingEnCa = $false
			}
			if ($ecLangList -NotMatch "fr-CA") {
				$ECexistingFrCa = $false
			}
			if ($ecLangList -NotMatch "es-US") {
				$ECexistingEsUs = $false
			}
		}
	}
	
	$Properties = @{
        ItemName = $_.Name
        Id = $_.ID
		SKU = $_.SKU
        LanguageList = $languageList
		enCaExists = $existingEnCa
		frCaExists = $existingFrCa
		esUsExists = $existingEsUs
        ItemPath = $_.Paths.FullPath
		Category = ''
		enhancedContent = $ec
		ECenCaExists = $ECexistingEnCa
		ECfrCaExists = $ECexistingFrCa
		ECesUsExists = $ECexistingEsUs
		likelyFrCa = $likelyFrCa
		likelyEsUs = $likelyEsUs
    }
	
	# update counters based on template inheritance
	if ($template.InheritsFrom("{8CEFD68F-7612-4805-A4F4-567FEB087F35}")) { # _accessory
		$totalAccessories++
		$Properties.Category = "Accessory"
		if ($existingEnCa) {
			$enCATranslatedAccessories++
		}
		if ($existingEsUs) {
			$esUsTranslatedAccessories++
			if ($likelyEsUs) {
				$esUSParsedTranslatedAccessories++
			} else {
				$ESprops = OutputForSpanish $_ $Properties.Category
				$EsInEnResults += New-Object psobject -Property $ESprops
			}
		}
		if ($existingFrCa) {
			$frCATranslatedAccessories++
			if ($likelyFrCa) {
				$frCAParsedTranslatedAccessories++
			} else {
				$FRprops = OutputForFrench $_ $Properties.Category
				$FrInEnResults += New-Object psobject -Property $FRprops
			}
		}
		if ($ec) {
			$ECtotalAccessories++
			if ($ECexistingEnCa) {
				$ECenCATranslatedAccessories++
			}
			if ($ECexistingFrCa) {
				$ECfrCATranslatedAccessories++
			}
			if ($ECexistingEsUs) {
				$ECesUSTranslatedAccessories++
			}
		}
		if ($Properties.LanguageList -NotMatch "fr-CA" -OR $Properties.LanguageList -NotMatch "es-US" -OR $Properties.LanguageList -NotMatch "en-CA"){
			$Results += New-Object psobject -Property $Properties
			$totalAccessoriesItems++
		} elseif ($ec -and ($ECexistingEnCa -eq $false -or $ECexistingFrCa -eq $false -or $ECexistingEsUs -eq $false)) {
			$ECResults += New-Object psobject -Property $Properties
			$ECtotalAccessoriesItems++
		}
	}
	
	if ($template.InheritsFrom("{5C58FC8F-106B-4780-BECA-B6B7F5AA0443}")) { # Combo Kit
		$totalComboKits++
		$Properties.Category = "Combo Kit"
		if ($existingEnCa) {
			$enCATranslatedComboKits++
		}
		if ($existingEsUs) {
			$esUsTranslatedComboKits++
			if ($likelyEsUs) {
				$esUSParsedTranslatedComboKits++
			} else {
				$ESprops = OutputForSpanish $_ $Properties.Category
				$EsInEnResults += New-Object psobject -Property $ESprops
			}
		}
		if ($existingFrCa) {
			$frCATranslatedComboKits++
			if ($likelyFrCa) {
				$frCAParsedTranslatedComboKits++
			} else {
				$FRprops = OutputForFrench $_ $Properties.Category
				$FrInEnResults += New-Object psobject -Property $FRprops
			}
		}
		if ($ec) {
			$ECtotalComboKits++
			if ($ECexistingEnCa) {
				$ECenCATranslatedComboKits++
			}
			if ($ECexistingFrCa) {
				$ECfrCATranslatedComboKits++
			}
			if ($ECexistingEsUs) {
				$ECesUSTranslatedComboKits++
			}
		}
		if ($Properties.LanguageList -NotMatch "fr-CA" -OR $Properties.LanguageList -NotMatch "es-US" -OR $Properties.LanguageList -NotMatch "en-CA"){
			$Results += New-Object psobject -Property $Properties
			$totalComboKitsItems++
		} elseif ($ec -and ($ECexistingEnCa -eq $false -or $ECexistingFrCa -eq $false -or $ECexistingEsUs -eq $false)) {
			$ECResults += New-Object psobject -Property $Properties
			$ECtotalComboKitsItems++
		}
	}
	
	if ($template.InheritsFrom("{5F35D082-8EBE-49CE-8625-70CA2365B467}")) { # _Equipment
		$totalEquipment++
		$Properties.Category = "Equipment"
		if ($existingEnCa) {
			$enCATranslatedEquipment++
		}
		if ($existingEsUs) {
			$esUSTranslatedEquipment++
			if ($likelyEsUs) {
				$esUSParsedTranslatedEquipment++
			} else {
				$ESprops = OutputForSpanish $_ $Properties.Category
				$EsInEnResults += New-Object psobject -Property $ESprops
			}
		}
		if ($existingFrCa) {
			$frCATranslatedEquipment++
			if ($likelyFrCa) {
				$frCAParsedTranslatedEquipment++
			} else {
				$FRprops = OutputForFrench $_ $Properties.Category
				$FrInEnResults += New-Object psobject -Property $FRprops
			}
		}
		if ($ec) {
			$ECtotalEquipment++
			if ($ECexistingEnCa) {
				$ECenCATranslatedEquipment++
			}
			if ($ECexistingFrCa) {
				$ECfrCATranslatedEquipment++
			}
			if ($ECexistingEsUs) {
				$ECesUSTranslatedEquipment++
			}
		}
		if ($Properties.LanguageList -NotMatch "fr-CA" -OR $Properties.LanguageList -NotMatch "es-US" -OR $Properties.LanguageList -NotMatch "en-CA"){
			$Results += New-Object psobject -Property $Properties
			$totalEquipmentItems++
		} elseif ($ec -and ($ECexistingEnCa -eq $false -or $ECexistingFrCa -eq $false -or $ECexistingEsUs -eq $false)) {
			$ECResults += New-Object psobject -Property $Properties
			$ECtotalEquipmentItems++
		}
	}
	
	if ($template.InheritsFrom("{F251C6B4-E199-4606-BF1A-8FC83ED6E3AD}")) { # Gloves
		$totalGloves++
		$Properties.Category = "Gloves"
		if ($existingEnCa) {
			$enCATranslatedGloves++
		}
		if ($existingEsUs) {
			$esUSTranslatedGloves++
			if ($likelyEsUs) {
				$esUSParsedTranslatedGloves++
			} else {
				$ESprops = OutputForSpanish $_ $Properties.Category
				$EsInEnResults += New-Object psobject -Property $ESprops
			}
		}
		if ($existingFrCa) {
			$frCATranslatedGloves++
			if ($likelyFrCa) {
				$frCAParsedTranslatedGloves++
			} else {
				$FRprops = OutputForFrench $_ $Properties.Category
				$FrInEnResults += New-Object psobject -Property $FRprops
			}
		}
		if ($ec) {
			$ECtotalGloves++
			if ($ECexistingEnCa) {
				$ECenCATranslatedGloves++
			}
			if ($ECexistingFrCa) {
				$ECfrCATranslatedGloves++
			}
			if ($ECexistingEsUs) {
				$ECesUSTranslatedGloves++
			}
		}
		if ($Properties.LanguageList -NotMatch "fr-CA" -OR $Properties.LanguageList -NotMatch "es-US" -OR $Properties.LanguageList -NotMatch "en-CA"){
			$Results += New-Object psobject -Property $Properties
			$totalGlovesItems++
		} elseif ($ec -and ($ECexistingEnCa -eq $false -or $ECexistingFrCa -eq $false -or $ECexistingEsUs -eq $false)) {
			$ECResults += New-Object psobject -Property $Properties
			$ECtotalGlovesItems++
		}
	}
	
	if ($template.InheritsFrom("{366698BE-EC46-453C-A27D-6CB14DFCEA3D}")) { # Safety
		$totalSafety++
		$Properties.Category = "Safety"
		if ($existingEnCa) {
			$enCATranslatedSafety++
		}
		if ($existingEsUs) {
			$esUSTranslatedSafety++
			if ($likelyEsUs) {
				$esUSParsedTranslatedSafety++
			} else {
				$ESprops = OutputForSpanish $_ $Properties.Category
				$EsInEnResults += New-Object psobject -Property $ESprops
			}
		}
		if ($existingFrCa) {
			$frCATranslatedSafety++
			if ($likelyFrCa) {
				$frCAParsedTranslatedSafety++
			} else {
				$FRprops = OutputForFrench $_ $Properties.Category
				$FrInEnResults += New-Object psobject -Property $FRprops
			}
		}
		if ($ec) {
			$ECtotalSafety++
			if ($ECexistingEnCa) {
				$ECenCATranslatedSafety++
			}
			if ($ECexistingFrCa) {
				$ECfrCATranslatedSafety++
			}
			if ($ECexistingEsUs) {
				$ECesUSTranslatedSafety++
			}
		}
		if ($Properties.LanguageList -NotMatch "fr-CA" -OR $Properties.LanguageList -NotMatch "es-US" -OR $Properties.LanguageList -NotMatch "en-CA"){
			$Results += New-Object psobject -Property $Properties
			$totalSafetyItems++
		} elseif ($ec -and ($ECexistingEnCa -eq $false -or $ECexistingFrCa -eq $false -or $ECexistingEsUs -eq $false)) {
			$ECResults += New-Object psobject -Property $Properties
			$ECtotalSafetyItems++
		}
	}
	
	if ($template.InheritsFrom("{0A34F144-2269-4373-B6A1-0F80EF42FB3D}") -or $template.InheritsFrom("{765630F3-FB93-4CF2-AF6C-DE7087DDED27}")) { # _HandTool, Hand Tool Family
		$totalHandTools++
		$Properties.Category = "Hand Tool"
		if ($existingEnCa) {
			$enCATranslatedHandTools++
		}
		if ($existingEsUs) {
			$esUSTranslatedHandTools++
			if ($likelyEsUs) {
				$esUSParsedTranslatedHandTools++
			} else {
				$ESprops = OutputForSpanish $_ $Properties.Category
				$EsInEnResults += New-Object psobject -Property $ESprops
			}
		}
		if ($existingFrCa) {
			$frCATranslatedHandTools++
			if ($likelyFrCa) {
				$frCAParsedTranslatedHandTools++
			} else {
				$FRprops = OutputForFrench $_ $Properties.Category
				$FrInEnResults += New-Object psobject -Property $FRprops
			}
		}
		if ($ec) {
			$ECtotalHandTools++
			if ($ECexistingEnCa) {
				$ECenCATranslatedHandTools++
			}
			if ($ECexistingFrCa) {
				$ECfrCATranslatedHandTools++
			}
			if ($ECexistingEsUs) {
				$ECesUSTranslatedHandTools++
			}
		}
		if ($Properties.LanguageList -NotMatch "fr-CA" -OR $Properties.LanguageList -NotMatch "es-US" -OR $Properties.LanguageList -NotMatch "en-CA"){
			$Results += New-Object psobject -Property $Properties
			$totalHandToolsItems++
		} elseif ($ec -and ($ECexistingEnCa -eq $false -or $ECexistingFrCa -eq $false -or $ECexistingEsUs -eq $false)) {
			$ECResults += New-Object psobject -Property $Properties
			$ECtotalHandToolsItems++
		}
	}
	
	if ($template.InheritsFrom("{A0FFA49F-5737-429A-8ADD-7601243280C8}")) { # Instruments
		$totalInstruments++
		$Properties.Category = "Instrument"
		if ($existingEnCa) {
			$enCATranslatedInstruments++
		}
		if ($existingEsUs) {
			$esUSTranslatedInstruments++
			if ($likelyEsUs) {
				$esUSParsedTranslatedInstruments++
			} else {
				$ESprops = OutputForSpanish $_ $Properties.Category
				$EsInEnResults += New-Object psobject -Property $ESprops
			}
		}
		if ($existingFrCa) {
			$frCATranslatedInstruments++
			if ($likelyFrCa) {
				$frCAParsedTranslatedInstruments++
			} else {
				$FRprops = OutputForFrench $_ $Properties.Category
				$FrInEnResults += New-Object psobject -Property $FRprops
			}
		}
		if ($ec) {
			$ECtotalInstruments++
			if ($ECexistingEnCa) {
				$ECenCATranslatedInstruments++
			}
			if ($ECexistingFrCa) {
				$ECfrCATranslatedInstruments++
			}
			if ($ECexistingEsUs) {
				$ECesUSTranslatedInstruments++
			}
		}
		if ($Properties.LanguageList -NotMatch "fr-CA" -OR $Properties.LanguageList -NotMatch "es-US" -OR $Properties.LanguageList -NotMatch "en-CA"){
			$Results += New-Object psobject -Property $Properties
			$totalInstrumentsItems++
		} elseif ($ec -and ($ECexistingEnCa -eq $false -or $ECexistingFrCa -eq $false -or $ECexistingEsUs -eq $false)) {
			$ECResults += New-Object psobject -Property $Properties
			$ECtotalInstrumentsItems++
		}
	}
	
	if ($template.InheritsFrom("{8E28F8C0-CEF8-472B-AAB8-520E8A608A59}")) { # _PowerTool
		$totalPowerTools++
		$Properties.Category = "Power Tool"
		if ($existingEnCa) {
			$enCATranslatedPowerTools++
		}
		if ($existingEsUs) {
			$esUSTranslatedPowerTools++
			if ($likelyEsUs) {
				$esUSParsedTranslatedPowerTools++
			} else {
				$ESprops = OutputForSpanish $_ $Properties.Category
				$EsInEnResults += New-Object psobject -Property $ESprops
			}
		}
		if ($existingFrCa) {
			$frCATranslatedPowerTools++
			if ($likelyFrCa) {
				$frCAParsedTranslatedPowerTools++
			} else {
				$FRprops = OutputForFrench $_ $Properties.Category
				$FrInEnResults += New-Object psobject -Property $FRprops
			}
		}
		if ($ec) {
			$ECtotalPowerTools++
			if ($ECexistingEnCa) {
				$ECenCATranslatedPowerTools++
			}
			if ($ECexistingFrCa) {
				$ECfrCATranslatedPowerTools++
			}
			if ($ECexistingEsUs) {
				$ECesUSTranslatedPowerTools++
			}
		}
		if ($Properties.LanguageList -NotMatch "fr-CA" -OR $Properties.LanguageList -NotMatch "es-US" -OR $Properties.LanguageList -NotMatch "en-CA"){
			$Results += New-Object psobject -Property $Properties
			$totalPowerToolsItems++
		} elseif ($ec -and ($ECexistingEnCa -eq $false -or $ECexistingFrCa -eq $false -or $ECexistingEsUs -eq $false)) {
			$ECResults += New-Object psobject -Property $Properties
			$ECtotalPowerToolsItems++
		}
	}
	
	if ($template.InheritsFrom("{3A9B942D-36CF-4E4C-B12E-1AC3387F450C}")) { # Packout
		$totalPackout++
		$Properties.Category = "Packout"
		if ($existingEnCa) {
			$enCATranslatedPackout++
		}
		if ($existingEsUs) {
			$esUSTranslatedPackout++
			if ($likelyEsUs) {
				$esUSParsedTranslatedPackout++
			} else {
				$ESprops = OutputForSpanish $_ $Properties.Category
				$EsInEnResults += New-Object psobject -Property $ESprops
			}
		}
		if ($existingFrCa) {
			$frCATranslatedPackout++
			if ($likelyFrCa) {
				$frCAParsedTranslatedPackout++
			} else {
				$FRprops = OutputForFrench $_ $Properties.Category
				$FrInEnResults += New-Object psobject -Property $FRprops
			}
		}
		if ($ec) {
			$ECtotalPackout++
			if ($ECexistingEnCa) {
				$ECenCATranslatedPackout++
			}
			if ($ECexistingFrCa) {
				$ECfrCATranslatedPackout++
			}
			if ($ECexistingEsUs) {
				$ECesUSTranslatedPackout++
			}
		}
		if ($Properties.LanguageList -NotMatch "fr-CA" -OR $Properties.LanguageList -NotMatch "es-US" -OR $Properties.LanguageList -NotMatch "en-CA"){
			$Results += New-Object psobject -Property $Properties
			$totalPackoutItems++
		} elseif ($ec -and ($ECexistingEnCa -eq $false -or $ECexistingFrCa -eq $false -or $ECexistingEsUs -eq $false)) {
			$ECResults += New-Object psobject -Property $Properties
			$ECtotalPackoutItems++
		}
	}
	
	if ($template.InheritsFrom("{20452D9A-31C3-4B8C-9D5E-8F54224D9A23}")) { #Variant
		$totalVariant++
		$Properties.Category = "Variant"
		if ($existingEnCa) {
			$enCATranslatedVariant++
		}
		if ($existingEsUs) {
			$esUSTranslatedVariant++
			if ($likelyEsUs) {
				$esUSParsedTranslatedVariant++
			} else {
				$ESprops = OutputForSpanish $_ $Properties.Category
				$EsInEnResults += New-Object psobject -Property $ESprops
			}
		}
		if ($existingFrCa) {
			$frCATranslatedVariant++
			if ($likelyFrCa) {
				$frCAParsedTranslatedVariant++
			} else {
				$FRprops = OutputForFrench $_ $Properties.Category
				$FrInEnResults += New-Object psobject -Property $FRprops
			}
		}
		if ($ec) {
			$ECtotalVariant++
			if ($ECexistingEnCa) {
				$ECenCATranslatedVariant++
			}
			if ($ECexistingFrCa) {
				$ECfrCATranslatedVariant++
			}
			if ($ECexistingEsUs) {
				$ECesUSTranslatedVariant++
			}
		}
		if ($Properties.LanguageList -NotMatch "fr-CA" -OR $Properties.LanguageList -NotMatch "es-US" -OR $Properties.LanguageList -NotMatch "en-CA"){
			$Results += New-Object psobject -Property $Properties
			$totalVariantItems++
		} elseif ($ec -and ($ECexistingEnCa -eq $false -or $ECexistingFrCa -eq $false -or $ECexistingEsUs -eq $false)) {
			$ECResults += New-Object psobject -Property $Properties
			$ECtotalVariantItems++
		}
	}
}

if ($listView -and $Results.Count -gt 0) {
	$props = @{
        Title = "Products Language Version Audit"
        PageSize = 25
    }
	$Results | 
		Show-ListView @props -Property @{Label="Name"; Expression={$_.ItemName} },
		@{Label="ID"; Expression={$_.ID} },
		@{Label="Category"; Expression={$_.Category} },
		@{Label="SKU"; Expression={$_.SKU} },
		@{Label="LanguageList"; Expression={$_.LanguageList} },
		@{Label="enCaExists"; Expression={$_.enCaExists} },
		@{Label="frCaExists"; Expression={$_.frCaExists} },
		@{Label="esUsExists"; Expression={$_.esUsExists} },
		@{Label="EnhancedContent"; Expression={$_.enhancedContent} },
		@{Label="ECenCaExists"; Expression={$_.ECenCaExists} },
		@{Label="ECfrCaExists"; Expression={$_.ECfrCaExists} },
		@{Label="ECesUsExists"; Expression={$_.ECesUsExists} },
		@{Label="likelyFrCa"; Expression={$_.likelyFrCa} },
		@{Label="likelyEsUs"; Expression={$_.likelyEsUs} },
		@{Label="Path"; Expression={$_.ItemPath} }
}
if ($email -and $Results.Count -gt 0) {
	$enCATranslatedAccessoriesPercentage = $enCATranslatedAccessories / $totalAccessories
	$frCATranslatedAccessoriesPercentage = $frCATranslatedAccessories / $totalAccessories
	$esUSTranslatedAccessoriesPercentage = $esUSTranslatedAccessories / $totalAccessories
	$enCATranslatedComboKitsPercentage = $enCATranslatedComboKits / $totalComboKits
	$frCATranslatedComboKitsPercentage = $frCATranslatedComboKits / $totalComboKits
	$esUSTranslatedComboKitsPercentage = $esUSTranslatedComboKits / $totalComboKits
	$enCATranslatedEquipmentPercentage = $enCATranslatedEquipment / $totalEquipment
	$frCATranslatedEquipmentPercentage = $frCATranslatedEquipment / $totalEquipment
	$esUSTranslatedEquipmentPercentage = $esUSTranslatedEquipment / $totalEquipment
	$enCATranslatedGlovesPercentage = $enCATranslatedGloves / $totalGloves
	$frCATranslatedGlovesPercentage = $frCATranslatedGloves / $totalGloves
	$esUSTranslatedGlovesPercentage = $esUSTranslatedGloves / $totalGloves
	$enCATranslatedSafetyPercentage = $enCATranslatedSafety / $totalSafety
	$frCATranslatedSafetyPercentage = $frCATranslatedSafety / $totalSafety
	$esUSTranslatedSafetyPercentage = $esUSTranslatedSafety / $totalSafety
	$enCATranslatedHandToolsPercentage = $enCATranslatedHandTools / $totalHandTools
	$frCATranslatedHandToolsPercentage = $frCATranslatedHandTools / $totalHandTools
	$esUSTranslatedHandToolsPercentage = $esUSTranslatedHandTools / $totalHandTools
	$enCATranslatedInstrumentsPercentage = $enCATranslatedInstruments / $totalInstruments
	$frCATranslatedInstrumentsPercentage = $frCATranslatedInstruments / $totalInstruments
	$esUSTranslatedInstrumentsPercentage = $esUSTranslatedInstruments / $totalInstruments
	$enCATranslatedPowerToolsPercentage = $enCATranslatedPowerTools / $totalPowerTools
	$frCATranslatedPowerToolsPercentage = $frCATranslatedPowerTools / $totalPowerTools
	$esUSTranslatedPowerToolsPercentage = $esUSTranslatedPowerTools / $totalPowerTools
	$enCATranslatedPackoutPercentage = $enCATranslatedPackout / $totalPackout
	$frCATranslatedPackoutPercentage = $frCATranslatedPackout / $totalPackout
	$esUSTranslatedPackoutPercentage = $esUSTranslatedPackout / $totalPackout
	$enCATranslatedVariantPercentage = $enCATranslatedVariant / $totalVariant
	$frCATranslatedVariantPercentage = $frCATranslatedVariant / $totalVariant
	$esUSTranslatedVariantPercentage = $esUSTranslatedVariant / $totalVariant
	$totalProducts = $totalAccessories + $totalComboKits + $totalEquipment + $totalGloves + $totalHandTools + $totalInstruments + $totalPackout + $totalPowerTools + $totalSafety + $totalVariant
	$enCATranslatedTotal = $enCATranslatedAccessories + $enCATranslatedComboKits + $enCATranslatedEquipment + $enCATranslatedGloves + $enCATranslatedHandTools + $enCATranslatedPackout + $enCATranslatedPowerTools + $enCATranslatedSafety + $enCATranslatedVariant
	$frCATranslatedTotal = $frCATranslatedAccessories + $frCATranslatedComboKits + $frCATranslatedEquipment + $frCATranslatedGloves + $frCATranslatedHandTools + $frCATranslatedPackout + $frCATranslatedPowerTools + $frCATranslatedSafety + $frCATranslatedVariant
	$esUSTranslatedTotal = $esUSTranslatedAccessories + $esUSTranslatedComboKits + $esUSTranslatedEquipment + $esUSTranslatedGloves + $esUSTranslatedHandTools + $esUSTranslatedPackout + $esUSTranslatedPowerTools + $esUSTranslatedSafety + $esUSTranslatedVariant
	$enCATranslatedPercentage = $enCATranslatedTotal / $totalProducts
	$frCATranslatedPercentage = $frCATranslatedTotal / $totalProducts
	$esUSTranslatedPercentage = $esUSTranslatedTotal / $totalProducts
	
	$emailBody = "Attached is the most recent report of products that are missing language versions" + "`r`n"
	$emailBody += "`r`n" + "Accessories Total: " + $totalAccessories + "`r`n"
	$emailBody += "    enCA: " + $enCATranslatedAccessories  + " / " + $totalAccessories + "  =  " + $enCATranslatedAccessoriesPercentage.tostring("P") + "`r`n"
	$emailBody += "    frCA: " + $frCATranslatedAccessories  + " / " + $totalAccessories + "  =  " + $frCATranslatedAccessoriesPercentage.tostring("P") + "`r`n"
	$emailBody += "    esUS: " + $esUSTranslatedAccessories  + " / " + $totalAccessories + "  =  " + $esUSTranslatedAccessoriesPercentage.tostring("P") + "`r`n"
	$emailBody += "    Missing Sitecore Items: " + $totalAccessoriesItems + "`r`n"
	$emailBody += "    passed spanish parse: " + $esUSParsedTranslatedAccessories + "`r`n"
	$emailBody += "    passed french parse: " + $frCAParsedTranslatedAccessories + "`r`n"
	$emailBody += "    Total with Enhanced Content: " + $ECtotalAccessories + "`r`n"
	$emailBody += "        enCA: " + $ECenCATranslatedAccessories  + "`r`n"
	$emailBody += "        frCA: " + $ECfrCATranslatedAccessories  + "`r`n"
	$emailBody += "        esUS: " + $ECesUSTranslatedAccessories  + "`r`n"
	$emailBody += "        Items Missing EC: " + $ECtotalAccessoriesItems + "`r`n"
	$emailBody += "-----------------------------------------------" + "`r`n`r`n"
	$emailBody += "Combo Kits Total: " + $totalComboKits + "`r`n"
	$emailBody += "    enCA: " + $enCATranslatedComboKits  + " / " + $totalComboKits + "  =  " + $enCATranslatedComboKitsPercentage.tostring("P") + "`r`n"
	$emailBody += "    frCA: " + $frCATranslatedComboKits  + " / " + $totalComboKits + "  =  " + $frCATranslatedComboKitsPercentage.tostring("P") + "`r`n"
	$emailBody += "    esUS: " + $esUSTranslatedComboKits  + " / " + $totalComboKits + "  =  " + $esUSTranslatedComboKitsPercentage.tostring("P") + "`r`n"
	$emailBody += "    Missing Sitecore Items: " + $totalComboKitsItems + "`r`n"
	$emailBody += "    passed spanish parse: " + $esUSParsedTranslatedComboKits + "`r`n"
	$emailBody += "    passed french parse: " + $frCAParsedTranslatedComboKits + "`r`n"
	$emailBody += "    Total with Enhanced Content: " + $ECtotalComboKits + "`r`n"
	$emailBody += "        enCA: " + $ECenCATranslatedComboKits  + "`r`n"
	$emailBody += "        frCA: " + $ECfrCATranslatedComboKits  + "`r`n"
	$emailBody += "        esUS: " + $ECesUSTranslatedComboKits  + "`r`n"
	$emailBody += "        Items Missing EC: " + $ECtotalComboKitsItems + "`r`n"
	$emailBody += "-----------------------------------------------" + "`r`n`r`n"
	$emailBody += "Equipment Total: " + $totalEquipment + "`r`n"
	$emailBody += "    enCA: " + $enCATranslatedEquipment  + " / " + $totalEquipment + "  =  " + $enCATranslatedEquipmentPercentage.tostring("P") + "`r`n"
	$emailBody += "    frCA: " + $frCATranslatedEquipment  + " / " + $totalEquipment + "  =  " + $frCATranslatedEquipmentPercentage.tostring("P") + "`r`n"
	$emailBody += "    esUS: " + $esUSTranslatedEquipment  + " / " + $totalEquipment + "  =  " + $esUSTranslatedEquipmentPercentage.tostring("P") + "`r`n"
	$emailBody += "    Missing Sitecore Items: " + $totalEquipmentItems + "`r`n"
	$emailBody += "    passed spanish parse: " + $esUSParsedTranslatedEquipment + "`r`n"
	$emailBody += "    passed french parse: " + $frCAParsedTranslatedEquipment + "`r`n"
	$emailBody += "    Total with Enhanced Content: " + $ECtotalEquipment + "`r`n"
	$emailBody += "        enCA: " + $ECenCATranslatedEquipment  + "`r`n"
	$emailBody += "        frCA: " + $ECfrCATranslatedEquipment  + "`r`n"
	$emailBody += "        esUS: " + $ECesUSTranslatedEquipment  + "`r`n"
	$emailBody += "        Items Missing EC: " + $ECtotalEquipmentItems + "`r`n"
	$emailBody += "-----------------------------------------------" + "`r`n`r`n"
	$emailBody += "Gloves Total: " + $totalGloves + "`r`n"
	$emailBody += "    enCA: " + $enCATranslatedGloves  + " / " + $totalGloves + "  =  " + $enCATranslatedGlovesPercentage.tostring("P") + "`r`n"
	$emailBody += "    frCA: " + $frCATranslatedGloves  + " / " + $totalGloves + "  =  " + $frCATranslatedGlovesPercentage.tostring("P") + "`r`n"
	$emailBody += "    esUS: " + $esUSTranslatedGloves  + " / " + $totalGloves + "  =  " + $esUSTranslatedGlovesPercentage.tostring("P") + "`r`n"
	$emailBody += "    Missing Sitecore Items: " + $totalGlovesItems + "`r`n"
	$emailBody += "    passed spanish parse: " + $esUSParsedTranslatedGloves + "`r`n"
	$emailBody += "    passed french parse: " + $frCAParsedTranslatedGloves + "`r`n"
	$emailBody += "    Total with Enhanced Content: " + $ECtotalGloves + "`r`n"
	$emailBody += "        enCA: " + $ECenCATranslatedGloves  + "`r`n"
	$emailBody += "        frCA: " + $ECfrCATranslatedGloves  + "`r`n"
	$emailBody += "        esUS: " + $ECesUSTranslatedGloves  + "`r`n"
	$emailBody += "        Items Missing EC: " + $ECtotalGlovesItems + "`r`n"
	$emailBody += "-----------------------------------------------" + "`r`n`r`n"
	$emailBody += "Safety Total: " + $totalSafety + "`r`n"
	$emailBody += "    enCA: " + $enCATranslatedSafety  + " / " + $totalSafety + "  =  " + $enCATranslatedSafetyPercentage.tostring("P") + "`r`n"
	$emailBody += "    frCA: " + $frCATranslatedSafety  + " / " + $totalSafety + "  =  " + $frCATranslatedSafetyPercentage.tostring("P") + "`r`n"
	$emailBody += "    esUS: " + $esUSTranslatedSafety  + " / " + $totalSafety + "  =  " + $esUSTranslatedSafetyPercentage.tostring("P") + "`r`n"
	$emailBody += "    Missing Sitecore Items: " + $totalSafetyItems + "`r`n"
	$emailBody += "    passed spanish parse: " + $esUSParsedTranslatedSafety + "`r`n"
	$emailBody += "    passed french parse: " + $frCAParsedTranslatedSafety + "`r`n"
	$emailBody += "    Total with Enhanced Content: " + $ECtotalSafety + "`r`n"
	$emailBody += "        enCA: " + $ECenCATranslatedSafety  + "`r`n"
	$emailBody += "        frCA: " + $ECfrCATranslatedSafety  + "`r`n"
	$emailBody += "        esUS: " + $ECesUSTranslatedSafety  + "`r`n"
	$emailBody += "        Items Missing EC: " + $ECtotalSafetyItems + "`r`n"
	$emailBody += "-----------------------------------------------" + "`r`n`r`n"
	$emailBody += "Hand Tools Total: " + $totalHandTools + "`r`n"
	$emailBody += "    enCA: " + $enCATranslatedHandTools  + " / " + $totalHandTools + "  =  " + $enCATranslatedHandToolsPercentage.tostring("P") + "`r`n"
	$emailBody += "    frCA: " + $frCATranslatedHandTools  + " / " + $totalHandTools + "  =  " + $frCATranslatedHandToolsPercentage.tostring("P") + "`r`n"
	$emailBody += "    esUS: " + $esUSTranslatedHandTools  + " / " + $totalHandTools + "  =  " + $esUSTranslatedHandToolsPercentage.tostring("P") + "`r`n"
	$emailBody += "    Missing Sitecore Items: " + $totalHandToolsItems + "`r`n"
	$emailBody += "    passed spanish parse: " + $esUSParsedTranslatedHandTools + "`r`n"
	$emailBody += "    passed french parse: " + $frCAParsedTranslatedHandTools + "`r`n"
	$emailBody += "    Total with Enhanced Content: " + $ECtotalHandTools + "`r`n"
	$emailBody += "        enCA: " + $ECenCATranslatedHandTools  + "`r`n"
	$emailBody += "        frCA: " + $ECfrCATranslatedHandTools  + "`r`n"
	$emailBody += "        esUS: " + $ECesUSTranslatedHandTools  + "`r`n"
	$emailBody += "        Items Missing EC: " + $ECtotalHandToolsItems + "`r`n"
	$emailBody += "-----------------------------------------------" + "`r`n`r`n"
	$emailBody += "Instruments Total: " + $totalInstruments + "`r`n"
	$emailBody += "    enCA: " + $enCATranslatedInstruments  + " / " + $totalInstruments + "  =  " + $enCATranslatedInstrumentsPercentage.tostring("P") + "`r`n"
	$emailBody += "    frCA: " + $frCATranslatedInstruments  + " / " + $totalInstruments + "  =  " + $frCATranslatedInstrumentsPercentage.tostring("P") + "`r`n"
	$emailBody += "    esUS: " + $esUSTranslatedInstruments  + " / " + $totalInstruments + "  =  " + $esUSTranslatedInstrumentsPercentage.tostring("P") + "`r`n"
	$emailBody += "    Missing Sitecore Items: " + $totalInstrumentsItems + "`r`n"
	$emailBody += "    passed spanish parse: " + $esUSParsedTranslatedInstruments + "`r`n"
	$emailBody += "    passed french parse: " + $frCAParsedTranslatedInstruments + "`r`n"
	$emailBody += "    Total with Enhanced Content: " + $ECtotalInstruments + "`r`n"
	$emailBody += "        enCA: " + $ECenCATranslatedInstruments  + "`r`n"
	$emailBody += "        frCA: " + $ECfrCATranslatedInstruments  + "`r`n"
	$emailBody += "        esUS: " + $ECesUSTranslatedInstruments  + "`r`n"
	$emailBody += "        Items Missing EC: " + $ECtotalInstrumentsItems + "`r`n"
	$emailBody += "-----------------------------------------------" + "`r`n`r`n"
	$emailBody += "Power Tools Total: " + $totalPowerTools + "`r`n"
	$emailBody += "    enCA: " + $enCATranslatedPowerTools  + " / " + $totalPowerTools + "  =  " + $enCATranslatedPowerToolsPercentage.tostring("P") + "`r`n"
	$emailBody += "    frCA: " + $frCATranslatedPowerTools  + " / " + $totalPowerTools + "  =  " + $frCATranslatedPowerToolsPercentage.tostring("P") + "`r`n"
	$emailBody += "    esUS: " + $esUSTranslatedPowerTools  + " / " + $totalPowerTools + "  =  " + $esUSTranslatedPowerToolsPercentage.tostring("P") + "`r`n"
	$emailBody += "    Missing Sitecore Items: " + $totalPowerToolsItems + "`r`n"
	$emailBody += "    passed spanish parse: " + $esUSParsedTranslatedPowerTools + "`r`n"
	$emailBody += "    passed french parse: " + $frCAParsedTranslatedPowerTools + "`r`n"
	$emailBody += "    Total with Enhanced Content: " + $ECtotalPowerTools + "`r`n"
	$emailBody += "        enCA: " + $ECenCATranslatedPowerTools  + "`r`n"
	$emailBody += "        frCA: " + $ECfrCATranslatedPowerTools  + "`r`n"
	$emailBody += "        esUS: " + $ECesUSTranslatedPowerTools  + "`r`n"
	$emailBody += "        Items Missing EC: " + $ECtotalPowerToolsItems + "`r`n"
	$emailBody += "-----------------------------------------------" + "`r`n`r`n"
	$emailBody += "Packout Total: " + $totalPackout + "`r`n"
	$emailBody += "    enCA: " + $enCATranslatedPackout  + " / " + $totalPackout + "  =  " + $enCATranslatedPackoutPercentage.tostring("P") + "`r`n"
	$emailBody += "    frCA: " + $frCATranslatedPackout  + " / " + $totalPackout + "  =  " + $frCATranslatedPackoutPercentage.tostring("P") + "`r`n"
	$emailBody += "    esUS: " + $esUSTranslatedPackout  + " / " + $totalPackout + "  =  " + $esUSTranslatedPackoutPercentage.tostring("P") + "`r`n"
	$emailBody += "    Missing Sitecore Items: " + $totalPackoutItems + "`r`n"
	$emailBody += "    passed spanish parse: " + $esUSParsedTranslatedPackout + "`r`n"
	$emailBody += "    passed french parse: " + $frCAParsedTranslatedPackout + "`r`n"
	$emailBody += "    Total with Enhanced Content: " + $ECtotalPackout + "`r`n"
	$emailBody += "        enCA: " + $ECenCATranslatedPackout  + "`r`n"
	$emailBody += "        frCA: " + $ECfrCATranslatedPackout  + "`r`n"
	$emailBody += "        esUS: " + $ECesUSTranslatedPackout  + "`r`n"
	$emailBody += "        Items Missing EC: " + $ECtotalPackoutItems + "`r`n"
	$emailBody += "-----------------------------------------------" + "`r`n`r`n"
	$emailBody += "Variant Total: " + $totalVariant + "`r`n"
	$emailBody += "    enCA: " + $enCATranslatedVariant  + " / " + $totalVariant + "  =  " + $enCATranslatedVariantPercentage.tostring("P") + "`r`n"
	$emailBody += "    frCA: " + $frCATranslatedVariant  + " / " + $totalVariant + "  =  " + $frCATranslatedVariantPercentage.tostring("P") + "`r`n"
	$emailBody += "    esUS: " + $esUSTranslatedVariant  + " / " + $totalVariant + "  =  " + $esUSTranslatedVariantPercentage.tostring("P") + "`r`n"
	$emailBody += "    Missing Sitecore Items: " + $totalVariantItems + "`r`n"
	$emailBody += "    passed spanish parse: " + $esUSParsedTranslatedVariant + "`r`n"
	$emailBody += "    passed french parse: " + $frCAParsedTranslatedVariant + "`r`n"
	$emailBody += "    Total with Enhanced Content: " + $ECtotalVariant + "`r`n"
	$emailBody += "        enCA: " + $ECenCATranslatedVariant  + "`r`n"
	$emailBody += "        frCA: " + $ECfrCATranslatedVariant  + "`r`n"
	$emailBody += "        esUS: " + $ECesUSTranslatedVariant  + "`r`n"
	$emailBody += "        Items Missing EC: " + $ECtotalVariantItems + "`r`n"
	$emailBody += "-----------------------------------------------" + "`r`n`r`n"
	$emailBody += "Totals: " + "`r`n"
	$emailBody += "    enCA: " + $enCATranslatedTotal  + " / " + $totalProducts + "  =  " + $enCATranslatedPercentage.tostring("P") + "`r`n"
	$emailBody += "    frCA: " + $frCATranslatedTotal  + " / " + $totalProducts + "  =  " + $frCATranslatedPercentage.tostring("P") + "`r`n"
	$emailBody += "    esUS: " + $esUSTranslatedTotal  + " / " + $totalProducts + "  =  " + $esUSTranslatedPercentage.tostring("P") + "`r`n"
	$emailBody += "    Missing Sitecore Items: " + $Results.Count + "`r`n"
	$emailBody += "    Items Missing EC: " + $ECResults.Count

	$Results | Select-Object ItemName,ID,Category,SKU,enCaExists,frCaExists,esUsExists,enhancedContent,ECenCaExists,ECfrCaExists,ECesUsExists,likelyFrCa,likelyEsUs,ItemPath | Export-Csv -notypeinformation -Path $exportPath
	$ECResults | Select-Object ItemName,ID,Category,SKU,ECenCaExists,ECfrCaExists,ECesUsExists,ItemPath | Export-Csv -notypeinformation -Path $ECexportPath
	$EsInEnResults | Select-Object Category,SKU,Title,Overview,ItemPath | Export-Csv -notypeinformation -Path $ESexportPath
	$FrInEnResults | Select-Object Category,SKU,Title,Overview,ItemPath | Export-Csv -notypeinformation -Path $FRexportPath
	$secpasswd = ConvertTo-SecureString "BEWzzOyY36hwDe5GN/Pyesi4hA0egf95lYZzt2RFJc9R" -AsPlainText -Force
	$creds = New-Object System.Management.Automation.PSCredential ("AKIA4NPY3K6QHUSDUGMW", $secpasswd)
	Send-MailMessage -From 'noreply@milwaukeetool.com' -To $recipients -Subject 'Products Missing Language Report' -Body $emailBody -Attachments @($exportPath, $ECexportPath, $ESexportPath, $FRexportPath) -SmtpServer 'email-smtp.us-east-1.amazonaws.com' -Credential $creds -UseSsl
}
if ($uploadToBlob -and $Results.Count -gt 0) {
	$exportPathExists = Test-Path -Path $exportPath -PathType Leaf
	$ECexportPathExists = Test-Path -Path $ECexportPath -PathType Leaf
	$ESexportPathExists = Test-Path -Path $ESexportPath -PathType Leaf
	$FRexportPathExists = Test-Path -Path $FRexportPath -PathType Leaf
	if ($exportPathExists -eq $false) {
		$Results | Select-Object ItemName,ID,Category,SKU,enCaExists,frCaExists,esUsExists,enhancedContent,ECenCaExists,ECfrCaExists,ECesUsExists,likelyFrCa,likelyEsUs,ItemPath | Export-Csv -notypeinformation -Path $exportPath
	}
	if ($ECexportPathExists -eq $false) {
		$ECResults | Select-Object ItemName,ID,Category,SKU,ECenCaExists,ECfrCaExists,ECesUsExists,ItemPath | Export-Csv -notypeinformation -Path $ECexportPath
	}
	if ($ESexportPathExists -eq $false) {
		$EsInEnResults | Select-Object Category,SKU,Title,Overview,ItemPath | Export-Csv -notypeinformation -Path $ESexportPath
	}
	if ($FRexportPathExists -eq $false) {
		$FrInEnResults | Select-Object Category,SKU,Title,Overview,ItemPath | Export-Csv -notypeinformation -Path $FRexportPath
	}
	#$blobUploader = New-Object -Typename MilwaukeeTool.Foundation.ThirdPartyAPIs.Helpers.BlobStorage::New($blobContainerName, $blobConnectionString, $true) #use this for local
	$blobUploader = New-Object -Typename MilwaukeeTool.Foundation.ThirdPartyAPIs.Helpers.BlobStorage::New($blobContainerName)
	$stream = New-Object System.IO.StreamReader($exportPath)
	$blobUploader.UploadFile($exportName, $stream.BaseStream, $true)
	$stream.Dispose()
	$ECstream = New-Object System.IO.StreamReader($ECexportPath)
	$blobUploader.UploadFile($ECexportName, $ECstream.BaseStream, $true)
	$ECstream.Dispose()
	$ESstream = New-Object System.IO.StreamReader($ESexportPath)
	$blobUploader.UploadFile($ESexportName, $ESstream.BaseStream, $true)
	$ESstream.Dispose()
	$FRstream = New-Object System.IO.StreamReader($FRexportPath)
	$blobUploader.UploadFile($FRexportName, $FRstream.BaseStream, $true)
	$FRstream.Dispose()
}

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################