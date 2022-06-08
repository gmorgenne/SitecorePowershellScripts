########################################
# swap stackla components with         #
# sprinklr components                  #
#                                      #
# written 01-11-21                     #
########################################

########## global variables ############
# stackla
$stacklaRendering = '{5ED1CE62-1F1B-450F-8667-CEDF393EB30A}'
$stacklaRenderingPath = '/sitecore/layout/Renderings/Feature/Social/Stackla/Stackla Widget'
# sprinklr
$sprinklrRendering = '{E925AA0B-0F7A-4049-9241-233EAF101C30}'
$sprinklrRenderingPath = '/sitecore/layout/Renderings/Feature/Social/Sprinklr/SprinklrWidget'
$sprinklrPlaceholderKey = 'page-content'
# set this datasource if one already exists 
# $sprinklrDatasource = '{34EF64A1-C0FB-4029-A383-A9238E0C2F89}'
$sprinklrDatasource = ''
$sprinklrComponentTemplatePath = 'Feature/Social/Sprinklr/Sprinklr Widget'
$sprinklrWidgetId = 'ZW1iZWQ6NWY2YjhjNjk4ZDc5Nzc0YTlhOTIyNWFm'
# global component folder
$globalSprinklrDatasourcePath = '/sitecore/content/Milwaukee Tool/Global/Components/Sprinklr Galleries'
$folderTemplatePath = 'Common/Folder'

# setting up rendering to add
$sprinklrRenderingInstance = Get-Item -Path $sprinklrRenderingPath | New-Rendering -Placeholder $sprinklrPlaceholderKey

############### main ####################
Write-Host "------------------------" -f white
Write-Host "Begin Script" -f green
Write-Host "------------------------" -f white

#check if sprinklr datasource was provided or if global datasource location exists
if($sprinklrDatasource.Length -eq 0) {
	if ($sprinklrDatasourceFolder = Get-Item -Path $globalSprinklrDatasourcePath -ErrorAction SilentlyContinue) {
		Write-Host "Global Sprinklr Datasource Path does exist."
	}
	else {
		Write-Host "Global Sprinklr Datasource Path does not exist, creating folder."
		New-Item -Path '/sitecore/content/Milwaukee Tool/Global/Components' -Name 'Sprinklr Galleries' -ItemType $folderTemplatePath
	}
	
	## create default spinklr component
	$defaultSprinklrGallery = New-Item -Path $globalSprinklrDatasourcePath -Name 'Default Sprinklr Gallery' -ItemType $sprinklrComponentTemplatePath
	$defaultSprinklrGallery.Editing.BeginEdit()
	### TODO: Determine why this wasn't setting the widget id
	$defaultSprinklrGallery.Fields["Widget ID"] = $sprinklrWidgetId
	$defaultSprinklrGallery.Editing.EndEdit()
	$sprinklrDatasource = $defaultSprinklrGallery.ItemID
}

$pages = Get-Item $stacklaRenderingPath | Get-ItemReferrer
foreach ($page in $pages) {
	$renderings = Get-Rendering -Item $page  -FinalLayout
	$renderingToRemove = $renderings | Where-Object { $_.ItemID -eq $stacklaRendering }
	if ($renderingToRemove.Length -gt 0) {
		Write-Host "removing stackla from " $page.Name $page.Paths.Path
		$sprinklrPlaceholderKey = $renderingToRemove.Placeholder
		Remove-Rendering -Item $page -Instance $renderingToRemove -FinalLayout
		$sprinklrExists = $renderings | Where-Object { $_.ItemID -eq $sprinklrRendering }
		if ($sprinklrExists.Length -eq 0) {
			Write-Host "adding sprinklr to " $page.Name
			Add-Rendering -Item $page -Instance $sprinklrRenderingInstance -Datasource $sprinklrDatasource -Placeholder $sprinklrPlaceholderKey  -FinalLayout
		}
	}
}

Write-Host "------------------------" -f white
Write-Host "End Script" -f green
Write-Host "------------------------" -f white