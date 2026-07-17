$rootFolder = "C:\Projects\[name]\src"

$files = Get-ChildItem -Filter *serialization.config -Path $rootFolder -Recurse

foreach($file in $files)
{
  $newSerializationJson = New-Object -TypeName pscustomobject

  Write-Host "Convert Started: " + $file.FullName

  $Document = (Select-Xml -Path $file.FullName -XPath / ).Node
  
  $configurationNode = $Document.configuration.sitecore.unicorn.configurations.SelectSingleNode('configuration')
  
  $name = $configurationNode.name
  
  $dependencies = $configurationNode.dependencies -split ","
  
  $newSerializationJson | Add-Member -MemberType NoteProperty -Name namespace -Value $name
  $newSerializationJson | Add-Member -MemberType NoteProperty -Name references -Value $dependencies

  
  $newPredicateList = New-Object System.Collections.ArrayList

  foreach($predicate in $Document.SelectNodes("//include"))
  {
    if([bool]$predicate.path)
    {
        $newPredicate = New-Object -TypeName pscustomobject 
        $newPredicate | Add-Member -MemberType NoteProperty -Name name -Value $predicate.name
        $newPredicate | Add-Member -MemberType NoteProperty -Name path -Value $predicate.path
        $newPredicate | Add-Member -MemberType NoteProperty -Name database -Value $predicate.database

        $excludeNode = $predicate.SelectSingleNode('exclude')

        if($excludeNode.children -eq "true")
        {
          $newPredicate | Add-Member -MemberType NoteProperty -Name scope -Value "SingleItem"
        }

        $newPredicateList.Add($newPredicate)
        }
  }

  $items = New-Object -TypeName pscustomobject
  $items | Add-Member -MemberType NoteProperty -Name includes -Value $newPredicateList


  $newSerializationJson | Add-Member -MemberType NoteProperty -Name items -Value $items

  $targetPath = Split-Path -Parent $file.FullName
  $targetName =  $targetPath + "\" + ($file.Name -replace "Serialization.config","$($name).module.json")
  $newSerializationJson | ConvertTo-Json -Depth 5 | Out-File $targetName 
}