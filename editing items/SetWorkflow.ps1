<#
	.SYNOPSIS
        Workflow audit & set
	.DESCRIPTION
        Finds ALL items EXCEPT a particular template and checks workflow
		If workflow or workflow state is not correct, it can set it
	.NOTES
		Geoff Morgenne
#>

$searchPath = "master:/sitecore/content"
$templateToExclude = "{A87A00B1-E6DB-45AB-8B54-636FEC3B5523}" #folder
$desiredWorkflow = "{A5BC37E7-ED96-4C1E-8590-A26E64DB55EA}"
$desiredWorkflowState = "{FCA998C5-0CC3-4F91-94D8-0A4E6CAECE88}"
$auditMode = $true
$handleEmpty = $false # set to true if you want to evaluate an item with an empty workflow

######################################################################
$StartTime = $(get-date)
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

New-UsingBlock (New-Object Sitecore.Data.BulkUpdateContext) {
	$allItems = @( Get-Item -Path $searchPath) + @( Get-ChildItem -Path $searchPath -Recurse)
	foreach ($item in $allItems) {
	    $template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item.TemplateID,$item.Database)
		$doesItInherit = $template.InheritsFrom($templateToExclude)
		if (!$doesItInherit) {
			$currentWorkflow = $item.Fields["__Workflow"].value
			$currentState = $item.Fields["__Workflow state"].value
			if ($currentWorkflow -ne "" -and $currentWorkflow -ne $desiredWorkflow) {
				Write-Host "Item workflow is different from desired, Updating Item: " $item.ItemPath -f red
				if (!$auditMode) {
					$item.Editing.BeginEdit()
					$item.Fields["__Workflow"].Value = $desiredWorkflow
					$item.Fields["__Default workflow"].Value = $desiredWorkflow
					$item.Fields["__Workflow state"].Value = $desiredWorkflowState
					$item.Editing.EndEdit()
				}
			}
			if ($handleEmpty -and $currentWorkflow -eq "") {
				Write-Host "Item doesn't have workflow, Updating Item: " $item.ItemPath -f DarkRed
				if (!$auditMode) {
					$item.Editing.BeginEdit()
					$item.Fields["__Workflow"].Value = $desiredWorkflow
					$item.Fields["__Default workflow"].Value = $desiredWorkflow
					$item.Fields["__Workflow state"].Value = $desiredWorkflowState
					$item.Editing.EndEdit()
				}
			}
			if ($currentState -ne "" -and $currentState -ne $desiredWorkflowState) {
			    Write-Host "Item workflow state is different from desired, Updating Item: " $item.ItemPath -f yellow
				if (!$auditMode) {
					$item.Editing.BeginEdit()
					$item.Fields["__Workflow state"].Value = $desiredWorkflowState
					$item.Editing.EndEdit()
				}
			}
			if ($handleEmpty -and $currentState -eq "") {
			    Write-Host "Item workflow state is empty, Updating Item: " $item.ItemPath -f DarkYellow
				if (!$auditMode) {
					$item.Editing.BeginEdit()
					$item.Fields["__Workflow state"].Value = $desiredWorkflowState
					$item.Editing.EndEdit()
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