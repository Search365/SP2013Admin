set-ExecutionPolicy RemoteSigned
Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

<###################################################################
#  Logs the message and provides datetime/user info.
###################################################################>
function Global:Log ($message, $foregroundColor="green") {
    [string] $date = get-date -uformat "%G-%m-%d %T"
	Write-Host "[$date] " -ForegroundColor $foregroundColor -nonewline
	[string] $thisHost = ($env:COMPUTERNAME+'.'+$env:USERDNSDOMAIN).toLower()
	Write-Host "[$thisHost] " -ForegroundColor $foregroundColor -nonewline
	Write-Host "".padright(4) -Foregroundcolor $foregroundColor -nonewline
	Write-Host -ForegroundColor $foregroundColor "$message`r`n"
}

function Global:LogWarning($message) {
    Log $message "yellow"
}

function Global:LogError($message) {
    Log $message "red"
}

<###################################################################
#  Terminates the current script
###################################################################>
function Global:TerminateScript {
	param($message)	
	LogError($message)
	exit(1)
}

<###################################################################
#  Gets the xml file specified from the current directory. If not 
#  found it prompts the user to enter the filename. Appends the 
#  directoryPath to the current directory if specified.
###################################################################>
function Global:GetXmlFile($filename, $userMessage = 'Enter xml filename', $directoryPath='')
{
    $filename = GetFilePath $filename $directoryPath
    $fileExists = Test-Path $filename

    if (!$fileExists)
    {
        $filename = Read-Host $userMessage
    }

    Log "Parsing file: $fileName"
    $XmlDoc = [xml](Get-Content $fileName)

    return $XmlDoc
}

<###################################################################
#  Gets the path of the filename specified from the current 
#  directory. Appends the directoryPath to the current directory if 
#  specified.
###################################################################>
function Global:GetFilePath($filename, $directoryPath='')
{
    $directoryPath = Join-Path $PSScriptRoot $directoryPath
    $filename = $directoryPath + $filename
    return $filename
}

<###################################################################
#  Gets the common properties xml file.  
###################################################################>
function Global:GetCommonPropertiesXmlFile
{
    return GetXmlFile "CommonProperties.xml" "Enter Common Properties xml filename"
}

<###################################################################
#  Gets the Site Url from the common propeties xml file.  
###################################################################>
function Global:GetSiteUrl($environment)
{
    $commonXml = GetCommonPropertiesXmlFile
    return GetXMLValue $commonXml "CommonProperties" $environment "/Site/@Url"
}

<###################################################################
#  Gets the KnowledgeObjectListUrl from the common propeties xml file.  
###################################################################>
function Global:GetKnowledgeObjectListUrl($environment)
{
    $commonXml = GetCommonPropertiesXmlFile
    return GetXMLValue $commonXml "CommonProperties" $environment "/KnowledgeObjectList/@Url"
}

<###################################################################
#  Uses the current script file path to create an xml filename by
#  removing the path and extension.
###################################################################>
function Global:GetXmlFilename($scriptFilepath)
{
    $xmlFilename = ([IO.FileInfo]$scriptFilepath).BaseName + ".xml"
    return $xmlFilename
}

<###################################################################
#  Recycle the SharePoint application pool for the url specified.
###################################################################>
function Global:RecycleSharePointAppPool($siteUrl)
{
    $web = Get-SPWeb $siteUrl
    $sharePointAppPoolName = $web.Site.WebApplication.ApplicationPool.Name

    Log "Recycling Application Pool: $sharePointAppPoolName"

    $serverManager = new-object Microsoft.Web.Administration.ServerManager 
    $serverManager.ApplicationPools | ? { $_.Name -eq $sharePointAppPoolName} | % { $_.Recycle() }

    Log "Recycled Application Pool: $sharePointAppPoolName"
}

<###################################################################
#  Unzips the zip file to the destination specified. If the 
#  destination directory does not exist it is created.
###################################################################>
function Global:Expand-ZipFile($file, $destination)
{
    $shell = new-object -com shell.application
    $zip = $shell.NameSpace($file)
    
    # Check directory exists - if not create it.
    if(!(Test-Path -Path $destination )){
        New-Item -ItemType directory -Path $destination
        Log "Directory Created: $destination"
    }
    
    foreach($item in $zip.items())
    {
        $shell.Namespace($destination).copyhere($item)
    }
}

<###################################################################
# Get the Search Service Application.
###################################################################>
function Global:GetServiceApplication($searchAppName = $null) {
    $searchServiceApp = $null
    if($searchAppName) {
	    $searchServiceApp = Get-SPEnterpriseSearchServiceApplication -Identity $searchAppName -ErrorAction:SilentlyContinue
	    if($searchServiceApp -eq $null) { TerminateScript "Search Service Application '$searchAppName' could not be found!" }
    } else {
	    $searchServiceApp = Get-SPEnterpriseSearchServiceApplication
	    if($searchServiceApp -eq $null) { TerminateScript "No Search Service Application could not be found!" }
    }

    return $searchServiceApp
}

<###################################################################
# Get the Web Application Url from the Site Url by stripping the 
# end of the url. 
###################################################################>
function Global:GetWebApplicationUrl($siteUrl)
{
    # Expect format of siteUrl like 'http://webapplication/css/search' for example.
    $index = $siteUrl.IndexOf("/", 7)
    $webApplicationUrl = $siteUrl

    if ($index -ne -1)
    {
        $webApplicationUrl = $siteUrl.Substring(0, $index)
    }

    return $webApplicationUrl
}

<###################################################################
# Creates a new managed path for the web application if it doesn't
# already exist.
###################################################################>
function Global:CreateManagedPath($webApplicationUrl, $managedPathName)
{
    $managedPaths = Get-SPManagedPath -WebApplication $webApplicationUrl

    if ($managedPaths.Name -contains $managedPathName)
    {
        LogWarning "Managed path '$managedPathName' already exists in web application at '$webApplicationUrl'"
    }
    else
    {
        New-SPManagedPath $managedPathName -WebApplication $webApplicationUrl
    }
}

<###################################################################
# Removes the crawled property by first unmapping it from any 
# managed properties and then deleting unmapped properties from the 
# category.
###################################################################>
function RemoveCrawledProperty($crawledPropertyName, $categoryName)
{
    $category = Get-SPEnterpriseSearchMetadataCategory -Identity $categoryName -SearchApplication $searchapp
    $crawledProperty = Get-SPEnterpriseSearchMetadataCrawledProperty -Name $crawledPropertyName -SearchApplication $searchapp -Category $category

    if ($crawledProperty)
    {
        $mappings = Get-SPEnterpriseSearchMetadataMapping -SearchApplication $searchapp -CrawledProperty $crawledProperty

        if ($mappings)
        {
            $mappings | Remove-SPEnterpriseSearchMetadataMapping -Confirm:$false
        }
        else
        {
            LogWarning "No mappings found for '$crawledPropertyName'."
        }

        $crawledProperty.IsMappedToContents = $false
        $crawledProperty.Update()
        $category.DeleteUnmappedProperties()

        Log "Deleted crawled property '$crawledPropertyName' from category '$categoryName'"
    }
    else
    {
        LogWarning "Crawled property '$crawledPropertyName' not found."
    }
}

<###################################################################
# Gets the log file with a date added to the filename to allow easy
# identification of when scripts are run.
###################################################################>
function Global:GetLogFilename($scriptFilepath)
{
    $dateTime = Get-Date -format yyyyMMddHHmmss
    $filename = ([IO.FileInfo]$scriptFilepath).BaseName + "." + $dateTime + ".log"
    return $filename
}

<###################################################################
# PowerShell ISE does not support transcript logging.
###################################################################>
function Global:HostSupportsTranscript()
{
    return $Host.Name -ne "Windows PowerShell ISE Host"
}

<###################################################################
# Starts recording all output to a log file.
###################################################################>
function Global:StartLogging($scriptFilepath)
{
    if (HostSupportsTranscript)
    {
        $logFile = GetLogFilename($scriptFilepath)
        $logPath = Join-Path $PSScriptRoot "\logs\"

        if(!(Test-Path -Path $logPath )){
            New-Item -ItemType directory -Path $logPath
            Log "Directory Created: $logPath"
        }

        $logFile = Join-Path $logPath $logFile
        Start-Transcript -Path $logFile -NoClobber -ErrorAction SilentlyContinue
    }
}

<###################################################################
# Stops recording all output to a log file.
###################################################################>
function Global:StopLogging()
{
    if (HostSupportsTranscript)
    {
        Stop-Transcript
    }
}

<###################################################################
# Checks the file is not null. If it is null it terminates the 
# script.
###################################################################>
function Global:ValidateXMLFile($xml)
{
    if (!$xml)
    {
        TerminateScript "Invalid Xml File - the xml file passed as a parameter is null"
    }
}

<###################################################################
# Gets the environment specific xpath.
###################################################################>
function Global:GetEnvironmentXpath($rootNode, $environment, $xpath)
{
    $xpath = "/$rootNode/Environment/$environment$xpath"
    return $xpath
}

<###################################################################
# Gets the xml value for the specified environment using the xpath
# to find the node selected. If the xpath contains @ it will return 
# an attribute value otherwise it returns the inner text of the node.
###################################################################>
function Global:GetXMLValue($xml, $rootNode, $environment, $xpath)
{
    ValidateXMLFile($xml)

    $xpath = GetEnvironmentXpath $rootNode $environment $xpath
    $xmlNode = $xml.SelectSingleNode($xpath)

    # Determines if its an attribute or node value.
    if ($xpath.Contains("@"))
    {
        $returnValue = $xmlNode.Value
    }
    else
    {
        $returnValue = $xmlNode.InnerText
    }

    return $returnValue 
}

<###################################################################
# Gets the xml nodes for the specified environment using the xpath
# to find the nodes.
###################################################################>
function Global:GetXMLNodes($xml, $rootNode, $environment, $xpath) 
{
    ValidateXMLFile($xml)
    $xpath = GetEnvironmentXpath $rootNode $environment $xpath
    $nodes = $xml.SelectNodes($xpath)
    
    return $nodes
}

<###################################################################
# Sets the file permission on the file/folder specified for the user
# and with the accessLevel specified.
###################################################################>
function Global:SetFileAcl($folderLocation, $username, $accessLevel)
{
    $acl = Get-Acl $folderLocation
    # public FileSystemAccessRule(IdentityReference identity, FileSystemRights fileSystemRights, InheritanceFlags inheritanceFlags, PropagationFlags propagationFlags, AccessControlType type)
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($username, $accessLevel, "ContainerInherit, ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($accessRule)
    Set-Acl $folderLocation $acl

    Log "Set file permission on '$folderLocation' to '$accessLevel' for '$username'"
}

<###################################################################
# Removes the host name/ip address specified from the hosts file.
###################################################################>
function Global:RemoveHostFileEntry([string]$filename, [string]$hostname) {
	$content = Get-Content $filename
	$newLines = @()
	
	foreach ($line in $content) 
    {
		$bits = [regex]::Split($line, "\t+")
		if (($bits.count -ne 2) -or ($bits[1] -ne $hostname)) 
        {
            # Add the current line being read.
			$newLines += $line
		}
	}
	
	# Write file
	Clear-Content $filename
	foreach ($line in $newLines) {
		$line | Out-File -encoding ASCII -append $filename
	}
}

<###################################################################
# Adds a host name with the ip address specified to the hosts file.
###################################################################>
function Global:AddHostFileEntry([string]$filename, [string]$ipAddress, [string]$hostname) 
{
    RemoveHostFileEntry $filename $hostname
	$ipAddress + "`t" + $hostname | Out-File -encoding ASCII -append $filename
}

<###################################################################
# Sets the AppSetting key in web.config to the specified 
# propertyValue.
###################################################################>
function Global:SetWebConfigAppSetting([string]$iisAppName, [string]$keyName, [string]$propertyValue) 
{
    $pspath = "MACHINE/WEBROOT/APPHOST/$iisAppName"
    $filter = "appSettings/add[@key='$keyName']"
    $propertyName = "value"
 
    Set-WebConfigurationProperty -PSPath $pspath -filter $filter -name $propertyName -value $propertyValue

    Log "Web.Config appSetting $keyName updated to: $propertyValue"
}

<###################################################################
# Updates common properties of the webpart if found in the 
# webpartDetail.
###################################################################>
function Global:UpdateWebPartProperties($webPart, $webpartDetail, $environment, $webpartmanager)
{
    $webPartUpdated = $false

    # Update the webpart.
    if ($webPart)
    {                
        # Set the TrimDuplicates property.
        if ($webpartDetail.TrimDuplicates)
        {
            $dataProvider = ConvertFrom-Json $webpart.DataProviderJSON
            $dataProvider.TrimDuplicates = [System.Convert]::ToBoolean($webpartDetail.TrimDuplicates)
            $webpart.DataProviderJSON = ConvertTo-Json $dataProvider -Compress
            $webPartUpdated = $true
            Log "Set WebPart property TrimDuplicates to $($webpartDetail.TrimDuplicates)"
        }        

        # Set the ShowViewDuplicates property (this is a checkbox in the webpart UI).
        if ($webpartDetail.ShowViewDuplicates)
        {
            $webpart.ShowViewDuplicates = [System.Convert]::ToBoolean($webpartDetail.ShowViewDuplicates)
            $webPartUpdated = $true
            Log "Set WebPart property ShowViewDuplicates to $($webpartDetail.ShowViewDuplicates)"
        }

        # Set the ShowSortOptions property (this is a checkbox in the webpart UI).
        if ($webpartDetail.ShowSortOptions)
        {
            $webpart.ShowSortOptions = [System.Convert]::ToBoolean($webpartDetail.ShowSortOptions)
            $webPartUpdated = $true
            Log "Set WebPart property ShowSortOptions to $($webpartDetail.ShowSortOptions)"
        }

        # Update the query template.
        if ($webpartDetail.QueryTemplate)
        {
            $dataProvider = ConvertFrom-Json $webpart.DataProviderJSON
            $dataProvider.QueryTemplate = $webpartDetail.QueryTemplate
            $webpart.DataProviderJSON = ConvertTo-Json $dataProvider -Compress
            $webPartUpdated = $true
        }

        # Add refiners to the Refiner webpart.
        if ($webpartDetail.Refiners.Refiner)
        {
            $selectedRefinementControlsJSON = ConvertFrom-Json $webpart.SelectedRefinementControlsJSON

            foreach ($refiner in $webpartDetail.Refiners.Refiner)
            {                
                $newRefinementControl = ConvertFrom-Json $refiner.InnerText
                $selectedRefinementControlsJSON.refinerConfigurations += $newRefinementControl
            }

            $webpart.SelectedRefinementControlsJSON = ConvertTo-Json $selectedRefinementControlsJSON -Compress
            $webPartUpdated = $true
        }

        if ($webPartUpdated)
        {
            # Save the changes.
            $webpartmanager.SaveChanges($webpart)
            Log "Updated webpart: $($webpartDetail.Title)"
        }
    }

    return $webPartUpdated
}