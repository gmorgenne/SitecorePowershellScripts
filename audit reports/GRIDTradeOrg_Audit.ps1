###########
$tradeOrgPath = "master:/sitecore/content/Global/Options/Trade Organizations"
$exportPath = "C:\inetpub\wwwroot\temp\TrainingCenterExport.csv"
$recipients = "geoff.morgenne@milwaukeetool.com"
$emailSubject = "GRID Trade Organizations Export"
$emailBody = "GRID Trade Organizations Export"  + "`r`n"
$Results = @();
$listView = $false
$email = $true

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$tradeOrgs = Get-ChildItem -Path $tradeOrgPath -Recurse | Where-Object { ($_.TemplateId -eq '{E888B777-ACEC-4E84-9819-0169425EEC3C}') }
foreach($tradeOrg in $tradeOrgs) {
    #Write-Host "Trade Org: " $tradeOrg.Name
	$emailBody += $tradeOrg.'Organization Name'  + "`r`n"
	$emailBody += '    Trades:' + "`r`n"
	
	$tradesField = [Sitecore.Data.Fields.MultilistField]$tradeOrg.Fields['Trades']
	$trades = $tradesField.GetItems()
	foreach($trade in $trades) {
	    #Write-Host "trade: " $trade.Name
		$emailBody += '        -' + $trade.Name + "`r`n"
	}

	$trainingCenters = $tradeOrg | Get-ChildItem -Recurse | Where-Object { ($_.TemplateId -eq '{4410FA16-E183-4864-BB94-D121302D5A41}') }
	foreach($trainingCenter in $trainingCenters){
		if($trainingCenter.Location){
			$location = Get-Item -Path $trainingCenter.Location -Language "en" -ErrorAction SilentlyContinue
			$Properties = @{
				TradeOrganization = $tradeOrg.'Organization Name'
				TrainingCenterName = $trainingCenter.Name
				CRMAccountNumber = $trainingCenter.'CRM Account Number'
				CRMTrainingCenter = $trainingCenter.'CRM Training Center'
				MilwaukeeRep = $trainingCenter.'Milwaukee Rep'
				Location = $location.'Short Name'
				Address = $trainingCenter.'Address'
				SignupCode = $trainingCenter.'Signup Code'
				ItemId = $trainingCenter.ID
				ItemPath = $trainingCenter.Paths.Path
			}
	
			$Results += New-Object psobject -Property $Properties
		} else {
			$Properties = @{
				TradeOrganization = $tradeOrg.'Organization Name'
				TrainingCenterName = $trainingCenter.Name
				CRMAccountNumber = $trainingCenter.'CRM Account Number'
				CRMTrainingCenter = $trainingCenter.'CRM Training Center'
				MilwaukeeRep = $trainingCenter.'Milwaukee Rep'
				Location = "No Location"
				Address = $trainingCenter.'Address'
				SignupCode = $trainingCenter.'Signup Code'
				ItemId = $trainingCenter.ID
				ItemPath = $trainingCenter.Paths.Path
			}
		
			$Results += New-Object psobject -Property $Properties
		}
	}
	$emailBody += '    Training Center Count: ' + $trainingCenters.Count + "`r`n" + "`r`n"
}

if ($listView -and $Results.Count -gt 0) {
	Write-Host $emailBody
	$props = @{
        Title = $emailSubject
        PageSize = 25
    }
	$Results | 
		Show-ListView @props -Property @{Label="TradeOrganization"; Expression={$_.TradeOrganization} },
		@{Label="TrainingCenterName"; Expression={$_.TrainingCenterName} },
		@{Label="CRMAccountNumber"; Expression={$_.CRMAccountNumber} },
		@{Label="CRMTrainingCenter"; Expression={$_.CRMTrainingCenter} },
		@{Label="MilwaukeeRep"; Expression={$_.MilwaukeeRep} },
		@{Label="Location"; Expression={$_.Location} },
		@{Label="Address"; Expression={$_.Address} },
		@{Label="SignupCode"; Expression={$_.SignupCode} },
		@{Label="ItemId"; Expression={$_.esUsExists} },
		@{Label="Path"; Expression={$_.ItemPath} }
}
if ($email -and $Results.Count -gt 0) {
	$Results | Select-Object TradeOrganization,TrainingCenterName,CRMAccountNumber,CRMTrainingCenter,MilwaukeeRep,Location,Address,SignupCode,ItemId,ItemPath | Export-Csv -notypeinformation -Path $exportPath
	$secpasswd = ConvertTo-SecureString "" -AsPlainText -Force
	$creds = New-Object System.Management.Automation.PSCredential ("", $secpasswd)
	Send-MailMessage -From '' -To $recipients -Subject $emailSubject -Body $emailBody -Attachments $exportPath -SmtpServer '' -Credential $creds -UseSsl
}

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################