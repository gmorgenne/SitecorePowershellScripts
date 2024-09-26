$siteRoot = "C:\inetpub\wwwroot"
$feedFilePath = "$siteRoot\temp\feed.xml"
$uploadPath = "$siteRoot\upload"
$listingPath = "/sitecore/content/Tenant/Site/Home/Page"
$repositoryPath = "/sitecore/content/Tenant/Site/Data/Repository"
$mediaPath = "/sitecore/media library/Project/Tenant/Site/Feed"
$templateId = "{A25E55B3-FD0A-4235-AF4F-0814E28B119C}"

######################################################################

$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

Invoke-WebRequest -Uri 'https://some.feed.it' -UseBasicParsing -OutFile $feedFilePath
$fileExists = Test-Path -Path  $feedFilePath -PathType leaf
if ($fileExists -ne $true) {
    Write-Host "feed file does not exist"
    exit
}

[xml]$content = Get-Content $feedFilePath
$channel = $content.rss.channel
New-UsingBlock (New-Object Sitecore.Data.BulkUpdateContext) { 
    foreach ($item in $channel.Item) {
        $publishDate = Get-Date $item.pubDate -Format "yyyyMMdd"
        $image = $item.image

        # get or create item
        $newItem = $null
        $itemPath = "$repositoryPath/$($item.customid)"
        $pagePath = "$listingPath/$($item.customid)"
        $imageFileName = $image.Split('/')[-1] 
        # imageFileName includes extension, so remove extension for item name
        $imageName = $imageFileName.Substring(0, $imageSplit.lastIndexOf('.'))
        $imagePath = ""
        if (Test-Path -Path $itemPath) {
            Write-Host "Updating existing item: $($item.customid)" -f yellow
            $newItem = Get-Item -Path $itemPath
        } elseif (Test-Path -Path $pagePath) {
            Write-Host "Updating existing item page: $($item.customid)" -f yellow
            $newItem = Get-Item -Path $pagePath
        } else {
            Write-Host "Creating new new item: $($item.customid)" -f green
            $newItem = New-Item -Path $itemPath -ItemType $templateId

            # downloads to upload directory, which will automagically create a media item
            Invoke-WebRequest -Uri $image -OutFile "$uploadPath/$imageFileName"
    
            # move image to better media directory
            $imagePath = "$mediaPath/$imageName"
            $imageExists = Test-Path -Path $imagePath
            if ($imageExists -ne $true) {
                Write-Host "Moving image after downloading $imageName" -f white
                Move-Item -Path "/sitecore/media library/$imageName" -Destination $imagePath
            }
        }
    
        $newItem.Editing.BeginEdit()
        $newItem.Title = $item.title
        $newItem.Teaser = $teaser
        if ($imagePath.Length -gt 0) {
            $newItem.Image = Get-Item -Path $imagePath
        }
        $newItem.PublishDate = $publishDate
        $newItem.Editing.EndEdit()

        if (($imageName.Length -gt 0) -and (Test-Path -Path "/sitecore/media library/$imageName")) {
            Write-Host "Removing imported image: $imageName" -f red
            Remove-Item -Path "/sitecore/media library/$imageName"
        }
    }
}

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################