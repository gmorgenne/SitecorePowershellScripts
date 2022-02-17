function Is-Discontinued{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$product
	)
	
	$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($product)
    if ($template.InheritsFrom("{A819D3F6-DD02-47DD-9897-5BA714E39152}")) { #base product
		$discontinuedDate = [Sitecore.Data.Fields.DateField]$product.Fields["Discontinued Date"]
		if ($discontinuedDate.DateTime -gt [DateTime]::MinValue) {
			return $product
		}
	}
}

$products = Get-ChildItem -Path 'master://sitecore/content/Milwaukee Tool/Products Repository/North America' -Recurse | Where-Object { Is-Discontinued $_ }

$props = @{
        Title = "Discontinued Products Report"
        PageSize = 25
    }
$products | Show-ListView @props -Property @{Label="Name"; Expression={$_.Title} }, 
    @{Label="SKU"; Expression={$_.SKU} },
    @{Label="ItemId"; Expression={$_.ID} },
    @{Label="Path"; Expression={$_.Paths.Path} },
    @{Label="Discontinued Date"; Expression={$_.Fields["Discontinued Date"]} }