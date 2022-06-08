$database = Get-Database -Name "master"
$archiveName = "recyclebin"
$archive = Get-Archive -Database $database -Name $archiveName
$items = Get-ArchiveItem -Archive $archive # | Show-ListView

Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white
foreach ($item in $items) {
    if ($item.archivedate -lt '2021-01-01') {
        write-host $item.Name " deleted on " $item.archivedate " delete it"
        Remove-ArchiveItem -Archive $archive -ItemId $item.ItemId
    } else {
        write-host $item.Name " deleted on " $item.archivedate " keep it"
    }
}
Write-Host "------------------------" -f white
Write-Host "End Script" -f green
Write-Host "------------------------" -f white