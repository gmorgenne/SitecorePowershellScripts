# remove versions of items

$searchPath =  "/sitecore/content/Milwaukee Tool/Global/Global Search Components/Search Interfaces Folder"
$items = Get-ChildItem -Path $searchPath -Recurse
foreach ($item in $items)
{
    foreach ($version in $item.Versions.GetVersions($true))
    {
        if ($version.Language -ne "en")
        {
            Remove-ItemVersion $version
            Write-Host $version.ID " - " $version.Language "- deleted"
            $version;
        }
    }   
}

$props = @{
   InfoTitle = "Remove Versions"
    PageSize = 100
}
$items | Show-ListView @props -Property ItemPath, ID, @{Label="Language"; Expression={$_."Language"}} 