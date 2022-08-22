function Import-FromCsv {
    # use sitecore config to find data folder setting
    # create folder for \temp\upload if it doesn't exist
    # then upload csv
    $tempFolder = "$apppath\App_Data\temp\upload"
    $filePath = Receive-File -Path $tempFolder -overwrite

    if ($filePath -eq "cancel") {
        return @{}
    }
    $resultSet = Import-Csv $filePath
    $rowsCount = ($resultSet | Measure-Object).Count
    if ($rowsCount -le 0) {
        Write-Host "No data in file or file not found"
        Remove-Item $filePath
        return @{}
    }

    Remove-Item $filePath
    return $resultSet
}
