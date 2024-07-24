<#
    .SYNOPSIS
        Queries a salesforce API and creates products in sitecore
#>

# Provide this data
$clientId = "id"
$clientSecret = "secret"
$domain = "http://cool.site.io"
$importPath = "/sitecore/content/temp"
$templateId = "{220FFB90-FFE7-49CD-9A3A-FC71A093A794}"

######################################################################

function Get-AccessToken {
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][string] $domain, 
        [Parameter(Mandatory=$true, Position=1)][string] $clientId, 
        [Parameter(Mandatory=$true, Position=2)][string] $clientSecret
	)
    $tokenUri = "{0}/token?grant_type=client_credentials&client_id={1}&client_secret={2}" -f $domain, $clientId, $clientSecret
    $tokenResponse = Invoke-WebRequest -uri $tokenUri -Method Post -UseBasicParsing
    return ($tokenResponse | ConvertFrom-Json).access_token
}

function Get-ProductData {
    [CmdletBinding()]
	param(
        [Parameter(Mandatory=$true, Position=0)][string] $domain,
		[Parameter(Mandatory=$true, Position=1)][string] $accessToken
	)

    $productUri = "{0}/api/products" -f $domain
    $headers = @{
        Authorization = "Bearer {0}" -f $accessToken
    }
    $productResponse = Invoke-WebRequest -uri $productUri -Headers $headers -Method Get -UseBasicParsing
    return $productResponse | ConvertFrom-Json
}

######################################################################

$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$accessToken = Get-AccessToken $domain $clientId $clientSecret

$products = Get-ProductData $domain $accessToken

New-UsingBlock (New-Object Sitecore.Data.BulkUpdateContext) {
    foreach ($product in $products) {
        $itemPath = "$($importPath)/$($product.id)"
        $itemExists = Test-Path -Path $itemPath
        $item = $null
        if($itemExists) {
            $item = Get-Item -Path $itemPath
        } else {
            $item = New-Item -Path $itemPath -ItemType $templateId
        }
        
        $item.Editing.BeginEdit()
        $item.SalesforceID = $product.id
        $item.ProductName = $product.productName
        $item.Description = $product.description
        $item.SKU = $product.productSKU
        $item.Type = $product.productRecordType
        $item.Active = $product.active
        $item.ISBN10 = $product.isbn10
        $item.ISBN13 = $product.isbn13
        $item.Format = $product.format
        $item.Editing.EndEdit()
    }
}

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################