#http://consultingblogs.emc.com/mattlally/archive/2011/12/20/create-sharepoint-2010-search-crawl-and-managed-properties-using-powershell.aspx

# Load Common Functions.
$commonScript = Join-Path $PSScriptRoot "Common.ps1"
. $commonScript

StartLogging($MyInvocation.MyCommand.Definition)

# Get xml file for this script.
$xmlDoc = GetXmlFile(GetXmlFilename $MyInvocation.MyCommand.Definition)

#Search Service Application
$sa = $xmlDoc.SearchProperties.ServiceName
$searchapp = GetServiceApplication $sa

#process crawled properties
$CrawledPropNodeList = $xmlDoc.SearchProperties.CrawledProperties
foreach ($CrawledPropNode in $CrawledPropNodeList.CrawledProperty)
{
    $cat = Get-SPEnterpriseSearchMetadataCategory –SearchApplication $searchapp –Identity $CrawledPropNode.Category

    #create crawled property if it doesn't exist
    if (!(Get-SPEnterpriseSearchMetadataCrawledProperty -SearchApplication $searchapp -Category $cat -Name $CrawledPropNode.Name -ea "silentlycontinue"))
    {
		$varType = 0
        switch ($CrawledPropNode.Type)
        {
            "Text" { $varType=31 }
            "Integer" { $varType=20 }  
            "Decimal" { $varType=5 }  
            "DateTime" { $varType=64 }
            "YesNo" { $varType=11 }
            default { $varType=31 }
        }

        # Property set defaults to 'SIT Search Connectors'.
        $propSet = "8493275C-CAC2-47E6-89E1-DA5E67511FF4"

        if ($cat.Name -eq "SharePoint")
        {
            $propSet = "00130329-0000-0130-c000-000000131346"
        }

        $crawlprop = New-SPEnterpriseSearchMetadataCrawledProperty -SearchApplication $searchapp -Category $cat.Name -VariantType $varType -Name $CrawledPropNode.Name -IsNameEnum $false -PropSet $propSet
        
        if ($crawlprop)
        {
            $creationStatus = "created"
        }
        else
        {
            $creationStatus = "creation failed"
        }

        Log "Crawled property '$($CrawledPropNode.Name)' $creationStatus"
    }
}

#process managed properties
$PropertyNodeList = $xmlDoc.SearchProperties.ManagedProperties
foreach ($PropertyNode in $PropertyNodeList.ManagedProperty)
{
    $SharePointPropMapList = $PropertyNode.Map
	$recreate = [System.Convert]::ToBoolean($PropertyNode.Recreate)
    if ($recreate)
    {
		#Delete if property should be recreated and it exists
		if($mp = Get-SPEnterpriseSearchMetadataManagedProperty -SearchApplication $searchapp -Identity $PropertyNode.Name -ea "silentlycontinue")
		{
            Log "Managed Property Removed: $($PropertyNode.Name)" 
			$mp.DeleteAllMappings()
			$mp.Delete()
			$searchapp.Update()
		}
		
		#create managed property
		New-SPEnterpriseSearchMetadataManagedProperty -SearchApplication $searchapp -Name $PropertyNode.Name -Type $PropertyNode.Type
    }

	if($mp = Get-SPEnterpriseSearchMetadataManagedProperty -SearchApplication $searchapp -Identity $PropertyNode.Name)
	{
		if($recreate)
		{
			#set configuration for new property
			$mp.RespectPriority = [System.Convert]::ToBoolean($PropertyNode.RespectPriority)
			$mp.Searchable = [System.Convert]::ToBoolean($PropertyNode.Searchable)
			$mp.Queryable = [System.Convert]::ToBoolean($PropertyNode.Queryable)
			$mp.Retrievable = [System.Convert]::ToBoolean($PropertyNode.Retrievable)
			$mp.HasMultipleValues = [System.Convert]::ToBoolean($PropertyNode.HasMultiple)
			$mp.Refinable = [System.Convert]::ToBoolean($PropertyNode.Refinable)
			$mp.Sortable = [System.Convert]::ToBoolean($PropertyNode.Sortable)
            
            # Add an alias if specified.
            if ($PropertyNode.Alias)
            {
                $mp.AddAlias($PropertyNode.Alias)
            }

			$mp.Update()
		}

		#add property mappings
		foreach ($SharePointPropMap in $SharePointPropMapList)
		{
			$cat = Get-SPEnterpriseSearchMetadataCategory –SearchApplication $searchapp –Identity $SharePointPropMap.Category
            $crawledProperty = $SharePointPropMap.InnerText
			$prop = Get-SPEnterpriseSearchMetadataCrawledProperty -SearchApplication $searchapp -Category $cat -Name $crawledProperty

            if ($prop.Length -gt 1)
            {
                $prop = $prop | where { $_.Propset -eq $SharePointPropMap.Propset }
            }
            
            if ($prop)
            {
			    New-SPEnterpriseSearchMetadataMapping -SearchApplication $searchapp -CrawledProperty $prop -ManagedProperty $mp
            }
            else
            {
                Log "Crawled property does not exist: $crawledProperty" 
            }
		}

        $status = "created"
        if ($recreate) { $status = "updated" }
        Log "Managed property '$($PropertyNode.Name)' $status"
	}
}

StopLogging