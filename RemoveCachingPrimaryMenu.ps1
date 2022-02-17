###############################################
# Cache Global Variables
# Path for the pages that need to be changed
$cacheContentRootPath = "master:/sitecore/content/Milwaukee Tool"
# Need the name of the rendering that is needed so it can be updated
#$cacheRenderingNameToGrab = @("Footer", "Grid Footer", "Primary Menu", "ProductSplit", "ProductTabs")
$cacheRenderingNameToGrab = @("Primary Menu")
$setDatasource = $True

#####################################################################
# Functions
# Given the page and rendering name it will return the # of renderings on the page
function GetRenderingsPerPageAndName($page, $renderingName){
    
    # Array to capture the renderings on the page
    $arrRenderings = @()
    
    $renderings = Get-Rendering -Item $page
    $renderings | `
    %{
        $rendering = $_
        $itemId = $rendering.ItemID
        if ([Sitecore.Data.ID]::IsID($itemId)) {
            $item = Get-Item . -ID $itemId -ea SilentlyContinue
            
            # Only add it to the array if the name of the rendering is the same as the item
            if($renderingName -eq $item.Name) {
                $arrRenderings += $rendering
            }
        }
    }
    return $arrRenderings
}

#########################################################################################################
# Main
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin removing the cache" -f green
Write-Host "------------------------" -f white
# Grab all the templateIds so that all the pages will be updated
$arrPageTypeTemplateIds = Get-ChildItem -Path $cachePageTypeTemplatePath | %{ $_.ID.ToString() }
# Grab all the items that need to be changed
$cacheItems = Get-ChildItem -Recurse -Path $cacheContentRootPath
$cacheItems | % {
    $item = $_
    $itemPath = $item.Paths.Path
    
    $cacheRenderings = GetRenderingsPerPageAndName -page $item -renderingName $cacheRenderingNameToGrab
    
    Write-Host "$($cacheRenderings.Count) renderings found on page $($itemPath)"
    
    $cacheRenderings | `
    %{
        $renderingInstance = $_
        $placeHolderName = $renderingInstance.Placeholder
        
        if($renderingInstance) {
            # Set Datasource if flag is set to $True
            # Set Cachable and Vary By Data
           
            $renderingInstance.Cachable = 0
            $renderingInstance.VaryByData = 0
            #$renderingInstance.VaryByDevice = 1
            if ($setDatasource){
                $itemId = $renderingInstance.ItemID
                if ([Sitecore.Data.ID]::IsID($itemId)) {
                    $renderingItem = Get-Item . -ID $itemId -ea SilentlyContinue
                    
                    # Only add it to the array if the name of the rendering is the same as the item
                    if($renderingItem.Name -eq "Footer") {
                        $renderingInstance.Datasource = "/sitecore/content/Milwaukee Tool/Global/Components/Footer/Global Footer" 
                    }elseif ($renderingItem.Name -eq "Grid Footer"){
                        $renderingInstance.Datasource = "/sitecore/content/Milwaukee Tool/Global/Components/Footer/Grid Footer" 
                    }elseif ($renderingItem.Name -eq "Primary Menu"){
                        $renderingInstance.Datasource = "/sitecore/content/Milwaukee Tool/Global/Components/Menu/Primary Menu"
                    } else {
                        $renderingInstance.VaryByDevice = 1
                    }
                }
            }
            Set-Rendering -Item $item -Instance $renderingInstance
            Write-Host "Rendering - Updating the cache for the rendering: Datasource added - $($setDatasource), Datasource - $($renderingInstance.Datasource), Placeholder - $($placeHolderName), Item - $($itemPath)" -foregroundcolor cyan
        }
        else {
            Write-Host "Rendering doesn't exist for" $itemPath -foregroundcolor yellow
        }
    }
}
$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End adding the cache - $($totalTime)" -f green
Write-Host "------------------------" -f white