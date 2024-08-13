$fieldType = "General Link"
$fields = Get-ChildItem "/sitecore/templates" -Recurse | Where-Object {$_.Fields["{AB162CC0-DC80-4ABF-8871-998EE5D7BA32}"] -like $fieldType} # ID is Type field
foreach($field in $fields) {
    $section = $field.Parent
    $template = $section.Parent
    $templateId = $template.ID
    Write-Host "Template: $($template.Name) $templateId, has field: $($field.Name)"
}