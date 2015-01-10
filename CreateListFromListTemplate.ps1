[CmdletBinding()]
Param(
  [Parameter(Mandatory=$False,Position=1)]
    [string]$environment="Default"
)

# Load Common Functions.
$commonScript = Join-Path $PSScriptRoot "Common.ps1"
. $commonScript

StartLogging($MyInvocation.MyCommand.Definition)

# Get xml file for this script.
$xmlDoc = GetXmlFile(GetXmlFilename $MyInvocation.MyCommand.Definition)

# Variables.
$siteUrl = GetSiteUrl($environment)
$site = Get-SPSite $siteUrl
$web = Get-SPWeb $siteUrl
$importListTemplateFilename = $xmlDoc.ListProperties.ListTemplateFilename
$importListTemplateFilePath = Join-Path $PSScriptRoot $importListTemplateFilename
$listTemplateName = $xmlDoc.ListProperties.ListTemplateName
$listName = $xmlDoc.ListProperties.ListName
$listDescription = $xmlDoc.ListProperties.ListDescription
  
# Get the list template gallery file collection.
$listTemplateFiles = $web.getfolder("List Template Gallery").files
  
# Get the custom list template file.
$Templatefile = get-item $importListTemplateFilePath
  
# Add the custom list template file to the gallery.
$listTemplateFiles.Add("_catalogs/lt/$importListTemplateFilename", $Templatefile.OpenRead(), $true)
  
Log "Template '$importListTemplateFilename' Uploaded to List Template Gallery Successfully"
  
# Get the custom list templates.
$CustomlistTemplates = $site.GetCustomListTemplates($web)  

# Create the list if it doesn't already exist.
if (!$web.Lists[$listName])
{
    # Create the custom list using template.
    $web.Lists.Add($listName, $listDescription, $CustomlistTemplates[$listTemplateName])
  
    Log "Created list '$listName' using the template '$importListTemplateFilename'"
}

StopLogging