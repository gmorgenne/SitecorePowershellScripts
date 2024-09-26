$rootId = "{47982199-5497-49DE-8F2D-B10607B5049D}"
$rootItem = Get-Item -Path "master:" -ID $rootId
$rootItem.Axes.GetDescendants() | Initialize-Item | 
    Group-Object { $_.ItemPath} | 
    Where-Object { $_.Count -gt 1 } |
    Sort-Object -Property Count -Descending | 
    Select-Object -Property Count, Name