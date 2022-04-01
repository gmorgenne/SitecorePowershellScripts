# find children of provided path that inherit template
# update particular field
######################################################################

# update these: 
$searchPath = "/sitecore/content"
#$template = "{854B9BB8-0081-4B89-A9A5-36CBA093C38D}" # USP hero
$template = "{E2DDFDFE-B2ED-4ACC-9910-8FD1EA8799C7}" # InnovationsPromo
#$template = "{65ED3868-2EB3-4C8C-84C6-795E1B8F7570}" #kiosk background container
$field = "{711288F0-3D69-41A5-8499-20358578AFA3}" # vimeo video id
$value = ""
$languageList = @(
  "en",
  "en-CA",
  "es-US",
  "fr-CA"
)

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

foreach ($language in $languageList) {
  $foundItems = Get-ChildItem $searchPath -Recurse -Language $language
  foreach ($foundItem in $foundItems) {
    $foundItemTemplate = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($foundItem)
    if ($foundItemTemplate.InheritsFrom($template)) { 
      New-UsingBlock (New-Object Sitecore.Globalization.LanguageSwitcher $language) {
        if ($foundItem.Fields[$field].Value -ne $value) {
          Write-Host "Updating this item: " $foundItem.Name " field: " $field " value: " $value " Language: " $foundItem.Language " in this path: " $foundItem.Paths.Path
          #$foundItem.Editing.BeginEdit()
          #$foundItem.Fields[$field].Value = $value
          #$foundItem.Editing.EndEdit()
          #Publish-Item -Item $foundItem
        } else {
          Write-Host "No Update for this item: " $foundItem.Name " Language: " $foundItem.Language " in this path: " $foundItem.Paths.Path
        }
      }
    }
  }
}

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "------------------------" -f white
Write-Host "End Script - Total time: " $totalTime -f green
Write-Host "------------------------" -f white
######################################################################