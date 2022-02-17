# create dynamic number of items
# https://hishaamn.wordpress.com/2018/06/30/sitecore-powershell-dynamic-ui/

$path = "/sitecore/content/Home"
$templatePath = "/sitecore/templates/Project/walrus/Page Types/Standard Page"


######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

$categoryCountProps = @{
    Parameters = @(
		@{ Name = "categoryCount"; Title = "Number of categories"; Tab = "Categories" }
    )
    Title = "Categories"
	Description = "Add the number of categories required"
    OkButtonName = "Proceed"
    CancelButtonName = "Abort"
	Width = 600
	Height = 400
}

$result = Read-Variable @categoryCountProps

if ($result -ne "ok") {
    Exit
}

$categoriesCount = [int]$categoryCount
$counter = 1

$pattern = ""

for($i = 0; $i -lt $categoriesCount; $i++){
    
    $catName = "Category$i"
    
    if($i -eq $categoriesCount – 1){
        $pattern += '@{ Name = "'+$catName+'"; Title = "Category Name '+$counter+'"; Tab = "Categories" }'
    }else{
        $pattern += '@{ Name = "'+$catName+'"; Title = "Category Name '+$counter+'"; Tab = "Categories" },'
    }
	$counter++
}

$convert = Invoke-Expression $pattern

$result = Read-Variable –Parameters $convert –Description "Add category names" –Title "Categories" –Width 650 –Height 700 –OkButtonName "Proceed" –CancelButtonName "Abort" –ShowHints

$categoryNames = [System.Collections.ArrayList]@()

for($i = 0; $i -lt $categoriesCount; $i++){
    
    $categoryName = Invoke-Expression $"Category$i"
	
	Write-Host "Creating item: " $categoryName
    
    $categoryItem = New-Item –Path $path –Name $categoryName –ItemType $templatePath
	
	[void]$categoryNames.Add($categoryItem.Name)
}

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################