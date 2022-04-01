$searchPath = "master:/sitecore/content/Milwaukee Tool/Products Repository/North America"
$exportPath = "C:\inetpub\wwwroot\temp\SuperSku-Export.csv"
#$exportPath = "D:\temp\SuperSku-Export.csv"
$listView = $true
$email = $false
$uploadToBlob = $false
$recipients = 'geoff.morgenne@milwaukeetool.com'
$blobContainerName = "super-sku-export"
$exportName = "SuperSku-Export.csv"

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
	
	if ($item.TemplateName -eq "Variant Option") {
		return $item
	}
}

function Find-SuperSku {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item
	)
	
	$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item)
    if ($template.InheritsFrom("{3F911AA6-6C99-4D21-8645-581FD0A41359}")) { #accessory family
		return $item
	}
	
	if ($template.InheritsFrom("{6C2F5441-1E78-496C-BF2F-3943460519A9}")) { #gear family
		return $item
	}
	
	if ($template.InheritsFrom("{F251C6B4-E199-4606-BF1A-8FC83ED6E3AD}")) { #gloves
		return $item
	}
	
	if ($template.InheritsFrom("{765630F3-FB93-4CF2-AF6C-DE7087DDED27}")) { #hand tool family
		return $item
	}
	
	if ($template.InheritsFrom("{6E58F91C-A2CF-433A-A959-9DC66C548CF4}")) { #heated gear
		return $item
	}
}

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white
$superSkus = Get-Item -Path $searchPath | Get-ChildItem -Recurse | Where-Object { Find-SuperSku $_ } 
$Results = @();

foreach($superSku in $superSkus){
	$skuList = ""
	$children = Get-ChildItem -Path $superSku.Paths.Path -Recurse | Where-Object { Filter-Items $_ }
	foreach($child in $children) {
		if ($child.'SKU') {
			$skuList += $child.'SKU' + "|"
		}
		if ($child.TemplateName -eq "Variant Option" -and $superSku.TemplateName -ne "Gloves") {
			$sizesField = [Sitecore.Data.Fields.MultilistField]$child.Fields["Size"]
			$sizes = $sizesField.GetItems()
			foreach ($size in $sizes) {
				$skuList += $child.'SKU' + $size.Name + "|"
			}
		}
	}
	if ($skuList -and $skuList.Count -gt 0) {
		$skuList = $skuList.Substring(0,$skuList.Length-1)
		$Properties = @{
			Name = $superSku.Name
			ID = $superSku.ID
			SKU = $superSku.'SKU'
			SkuList = $skuList
			Path = $superSku.Paths.Path
		}
		$Results += New-Object psobject -Property $Properties
	}
}

if ($listView -and $Results.Count -gt 0) {
	$props = @{
        Title = "Super Sku Mapping Report"
        PageSize = 25
    }
	$Results | 
		Show-ListView @props -Property @{Label="Name"; Expression={$_.Name} },
		@{Label="ID"; Expression={$_.ID} },
		@{Label="SKU"; Expression={$_.SKU} },
		@{Label="SkuList"; Expression={$_.SkuList} },
		@{Label="Path"; Expression={$_.Path} }
}
if ($email -and $Results.Count -gt 0) {
	$Results | Select-Object ItemName,ID,SKU,SkuList,Path | Export-Csv -notypeinformation -Path $exportPath
	$secpasswd = ConvertTo-SecureString "" -AsPlainText -Force
	$creds = New-Object System.Management.Automation.PSCredential ("", $secpasswd)
	Send-MailMessage -From 'noreply@milwaukeetool.com' -To $recipients -Subject 'Super Sku Mapping Report' -Body "See attached super sku export" -Attachments $exportPath -SmtpServer '' -Credential $creds -UseSsl
}
if ($uploadToBlob -and $Results.Count -gt 0) {
	$exportPathExists = Test-Path -Path $exportPath -PathType Leaf
	if ($exportPathExists -eq $false) {
		$Results | Select-Object ItemName,ID,SKU,SkuList,Path | Export-Csv -notypeinformation -Path $exportPath
	}
	#$blobUploader = New-Object -Typename MilwaukeeTool.Foundation.ThirdPartyAPIs.Helpers.BlobStorage::New($blobContainerName, $blobConnectionString, $true) #use this for local
	$blobUploader = New-Object -Typename MilwaukeeTool.Foundation.ThirdPartyAPIs.Helpers.BlobStorage::New($blobContainerName)
	$stream = New-Object System.IO.StreamReader($exportPath)
	$blobUploader.UploadFile($exportName, $stream.BaseStream, $true)
	$stream.Dispose()
}

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################