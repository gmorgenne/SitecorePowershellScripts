# This script will find items by searchPath
# check for old workflow or no workflow
# and template inheritance (or not)
# sets workflow fields
#############################################################

#$searchPath = "master:/sitecore/content/Global/Dictionary"
#$searchPath = "master:/sitecore/content/Milwaukee Tool/Global"
#$searchPath = "master:/sitecore/content/Milwaukee Tool/Home"
$searchPath = "master:/sitecore/content/Milwaukee Tool/Products Repository/North America"

$mtWorkflow = "{757FAAC3-6E26-4DA7-927F-AF89CE201E74}"
$lbWorkflow = "{5B6EBED7-92C0-4F4E-847F-C72F4F4E1132}"
$templtetoCheckId = "{A87A00B1-E6DB-45AB-8B54-636FEC3B5523}" #folder
#$basePageId = [Sitecore.Data.ID]::Parse("{CC9811A3-0FB6-4405-BA5C-63E6B0C97C00}")
#$baseProductID  = [Sitecore.Data.ID]::Parse("{A819D3F6-DD02-47DD-9897-5BA714E39152}")

# Proposed MT Workflow State
$mtDone = "{642A9C55-445D-40B8-9816-2FAD7AC16A28}"

############### main ####################
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

New-UsingBlock (New-Object Sitecore.Data.BulkUpdateContext) {
	$allthethings = @( Get-Item -Path $searchPath) + @( Get-ChildItem -Path $searchPath -Recurse)
	foreach ($onething in $allthethings) {
	    $template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($onething.TemplateID,$onething.Database)
	    
		#$doesItInherit = $template.InheritsFrom($basePageId) -or $template.InheritsFrom($baseProductID)
		$doesItInherit = $template.InheritsFrom($templtetoCheckId)
		if (!$doesItInherit) {
			$currentWorkflow = $onething.Fields["__Workflow"].value
			$currentState = $onething.Fields["__Workflow state"].value
			if ($currentWorkflow -eq $lbWorkflow) {
				Write-Host "Item workflow is lionbridge, Updating Item: " $onething.ItemPath 
				
				#$onething.Editing.BeginEdit()
				#$onething.Fields["__Workflow"].Value = $mtWorkflow
				#$onething.Fields["__Default workflow"].Value = $mtWorkflow
				#$onething.Fields["__Workflow state"].Value = $mtDone
				#$onething.Editing.EndEdit()
			}
			if ($currentWorkflow -eq "") {
				Write-Host "Item doesn't have workflow, Updating Item: " $onething.ItemPath 
				
				#$onething.Editing.BeginEdit()
				#$onething.Fields["__Workflow"].Value = $mtWorkflow
				#$onething.Fields["__Default workflow"].Value = $mtWorkflow
				#$onething.Fields["__Workflow state"].Value = $mtDone
				#$onething.Editing.EndEdit()
			}
			if ($currentState -eq "") {
			    Write-Host "Item workflow state is empty, Updating Item: " $onething.ItemPath
				
				#$onething.Editing.BeginEdit()
				#$onething.Fields["__Workflow state"].Value = $mtDone
				#$onething.Editing.EndEdit()
			}
		}
	}  
}
Write-Host "------------------------" -f white
Write-Host "End Script" -f green
Write-Host "------------------------" -f white