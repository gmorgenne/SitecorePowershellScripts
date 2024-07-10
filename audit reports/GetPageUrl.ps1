<#
    .Synopsis 
        shows window with url for current item

    .Description
        1. create powershell script module items
            - create a script module folder at `/sitecore/system/Modules/PowerShell/Script Library` with a name for your project/company
            - create a PowerShell Script Library called Content Editor
            - create a PowerShell Script Library called Context Menu
            - create a PowerShell Script called Get Page URL
        2. copy the contents of this file to the script body field
        3. add rule to show `where the item has a layout`
            - may need to define more rules here, for SXA you may also want to exclude partial designs & page designs
        4. should be able to right click on any item with a layout and get a url for it
    
    .NOTES
        Version:        1.0
        Author:         Geoff Morgenne
#>

function Get-ItemUrl {
    param(
        [item]$Item,
        [Sitecore.Sites.SiteContext]$SiteContext
    )
    
    $result = New-UsingBlock(New-Object Sitecore.Sites.SiteContextSwitcher $siteContext) {
        New-UsingBlock(New-Object Sitecore.Data.DatabaseSwitcher $item.Database) {
            [Sitecore.Links.LinkManager]::GetItemUrl($item)
        }
    }
    
    $result[0][0]
}

$siteContext = [Sitecore.Sites.SiteContext]::GetSite("website")
$item = Get-Item .
Get-ItemUrl -SiteContext $siteContext -Item $item | Show-Alert 
