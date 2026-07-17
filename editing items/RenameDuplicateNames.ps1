$path = "master:/sitecore/content"
$rootItem = Get-Item -Path $path
$itemGroups = $rootItem.Axes.GetDescendants() | Initialize-Item | 
    Group-Object { $_.ItemPath} | 
    Where-Object { $_.Count -gt 1 }

foreach ($group in $itemGroups) {
    Write-Host "group: $($group.Name) has $($group.Count) items"
    $index = 1
    foreach ($item in $group.Group) {
        Write-Host "  item: $($item.Name) rename to $($item.Name) $index"
        Write-Host "    id: $($item.ID) path: $($item.Paths.FullPath)"
        $item.Editing.BeginEdit()
        $item.Name = "$($item.Name) $index"
        $item.Editing.EndEdit()
        $index++
    }
}

## use this to rename many items in the same place
#$index = 1
#$item = Get-Item -Path "/sitecore/content/Site/Global/Redirect Manager/Redirects/Site Launch Redirects/Redirect Url"
#while ($null -ne $item) {
#    if ($item) {
#        Write-Host "Rename Item $($item.ID)"
#        $item.Editing.BeginEdit()
#        $item.Name = "$($item.Name) $index"
#        $item.Editing.EndEdit()
#        
#        $item = Get-Item -Path "/sitecore/content/Site/Global/Redirect Manager/Redirects/Site Launch Redirects/Redirect Url"
#        $index++
#    }
#}