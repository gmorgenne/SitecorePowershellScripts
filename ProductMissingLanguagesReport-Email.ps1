function Filter-Items{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item
	)
	
	$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item)
    if ($template.InheritsFrom("{A819D3F6-DD02-47DD-9897-5BA714E39152}")) { #base product
		return $item
	}
}

$allItems = Get-ChildItem -Path 'master://sitecore/content/Milwaukee Tool/Products Repository/North America' -Recurse | Where-Object { Filter-Items $_ }

$device = Get-LayoutDevice -Default
$Results = @();
$DataPath = "C:\inetpub\wwwroot\temp\ProductsMissingLanguages.csv"

$allItems | ForEach-Object {
    $Properties = @{
        ItemName = $_.Name
        ItemId = $_.ID
        LanguageList = ''
        MissingLanguageList = ''
        ItemPath = $_.Paths.FullPath
    }
    foreach ($version in $_.Versions.GetVersions($true))
    {
        if ($version.Language -eq "en-US" -OR $version.Language -eq "es-US" -OR $version.Language -eq "en-CA" -OR $version.Language -eq "fr-CA"  )
        {
            if($Properties.LanguageList -NotMatch $version.Language){
                $Properties.LanguageList += "$($version.Language) " 
            }
        }
    } 
    if($Properties.LanguageList -NotMatch "fr-CA"){
        $Properties.MissingLanguageList += "fr-CA "
    }
    if($Properties.LanguageList -NotMatch "es-US"){
        $Properties.MissingLanguageList += "es-US "
    }
    if($Properties.LanguageList -NotMatch "en-CA"){
        $Properties.MissingLanguageList += "en-CA "
    }
                
    if($Properties.LanguageList -NotMatch "fr-CA" -OR $Properties.LanguageList -NotMatch "es-US" -OR $Properties.LanguageList -NotMatch "en-CA"){
        $Results += New-Object psobject -Property $Properties
    }
}
#$Results | Show-ListView
$Results | Select-Object ItemName,ItemId,LanguageList,MissingLanguageList,ItemPath | Export-Csv -notypeinformation -Path $DataPath
$secpasswd = ConvertTo-SecureString "" -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential ("", $secpasswd)
Send-MailMessage -From 'noreply@milwaukeetool.com' -To @("","") -Subject 'Products Missing Language Report' -Body 'Attached is the most recent report of products that are missing language versions' -Attachments $dataPath -SmtpServer '' -Credential $creds -UseSsl