$searchPath = "/sitecore/content/Milwaukee Tool/Home/Products"
$templateIdToMatch = "{7C91F317-A66D-4ACD-812E-856DD743DBEB}" # product listing page template
$language = "en"

function Template-Check{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item
	)
	
	$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item)
	if ($template.InheritsFrom($templateIdToMatch)) {
		return $item
	}
}

$results = @( Get-Item -Path $searchPath -Language $language ) + @( Get-ChildItem -Path $searchPath -Recurse -Language $language ) | Where-Object { Template-Check $_ }
$results | ForEach-Object { Write-Host $_.Paths.Path.Replace("/sitecore/content/Milwaukee Tool/Home/", "") }
