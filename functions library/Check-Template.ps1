<#
	.SYNOPSIS
        simple ways to check if an item inherits a template
	.DESCRIPTION
        provide an item and template to match, returns bool
	.NOTES
		Geoff Morgenne
#>

function Check-Template {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)][Sitecore.Data.Items.Item]$item,
		[Parameter(Mandatory=$true, Position=1)][string]$selectedTemplateId
	)
	if ($item) {
		$template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($item)
		if ($template.InheritsFrom($selectedTemplateId)) {
			return $item
		}
	}
}