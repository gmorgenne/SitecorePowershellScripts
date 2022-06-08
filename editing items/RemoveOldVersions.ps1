$sourcePath =  "master:/sitecore/content/Milwaukee Tool/Global/Global Search Components"

$items = Get-ChildItem -Path $sourcePath -Recurse

foreach ($item in $items)
{
    foreach ($version in $item.Versions.GetVersions($true))
    {
        if ($version.Versions.IsLatestVersion() -ne $true) 
        {
            Remove-ItemVersion $version
            Write-Host $version.Paths.Path " - " $version.Language "- delete version " $version.Version 
        }
    }   
}