
function manifestToolsMenu
{
 	do{
		clear-host
	    write-host ""
	    write-host "=====================================================================" -foregroundcolor $menuBannerColor
	    write-host "    Manifest Tools Menu                                       " -foregroundcolor $menuBannerColor
	    write-host "=====================================================================" -foregroundcolor $menuBannerColor
	    write-host ""
		write-host "    1. Scan Manifest for Common Errors"
		Write-host "    2. Generate RDG file from Manifest"
		#Write-host "    . Generate DHCP Scopes from Manifest"
		write-host "    3. Generate all Layer 2 VLANs (NX-OS 5.0.3)"
	    Write-host "    4. Generate all Layer 3 VLANs (NX-OS 5.0.3)"
        Write-host "    5. Generate all Layer 3 VLANs with VRRP (NX-OS 5.0.3)"
		#Write-host "    . Generate Port Configurations by switch (NX-OS 5.0.3)"
		#Write-host "    . Generate NLB static arp entries (NX-OS 5.0.3)"
		if(test-path "D:\Deploy\ManifestCompiler"){Write-host "    6. Manifest Compiler Menu"}#remark on release
		Write-host "    0. Return to the Main Menu"
	    write-host ""
	
    	$local:menuChoice = read-host "Please enter an option and press Enter"  
	    [string]$thisFunction = $MyInvocation.MyCommand

		$ok = $menuChoice -match '^[012345]$'
	
	}until($ok)

    Switch($menuChoice)
    {
        1{scanManifestForErrors $thisFunction}
    
        2{generateRDGMenu $thisFunction}
		
		3{createLayer2VlanConfigScript $thisFunction}

		4{createLayer3VlanConfigScript $thisFunction}
    
        5{createPortConfigScript $thisFunction}
		
		5{manifestCompilerSubMenu $thisFunction}
		
		0{mainMenu}
    }
}


function scanManifestForErrors($parentMenu)
{
	$bannerMessage = "Scan Manifest for Common Errors"
    displayToolBanner $bannerMessage

    #select the manifest
    $manifestPath = Select-Tool -Label "Manifest" -path $manifestPath -parentMenu $parentMenu -filter "XML Files (*.XML)|*.XML"
    
    #get the first six characters of the first machine
    $siteCode = $machines[0].WinHostName.SubString(0,6)
    
	#select the output folder
	$folder = Select-Folder -currentFolder $dotRoot
	$outputFile = "$folder\$siteCode Manifest Scan.txt"
	Write-Host "Output will be saved to File: $outputFile"
    write-Host ""
	
	scanManifestForCommonErrors -manifestpath $manifestPath -refarchTable $refarchTablePath -logfile $outputFile
	
	Write-host "Press any key to continue"
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    . $parentMenu
	
} #function scanManifestForErrors


#Generate VLAN Config Menu
function generateVlanConfigScript($parentMenu)
{
	$bannerMessage = "Generate IOS VLAN Config Script"
    displayToolBanner $bannerMessage
    
    #select the manifest
    $manifestPath = Select-Tool -Label "Manifest" -path $manifestPath -parentMenu $parentMenu -filter "XML Files (*.XML)|*.XML"

	#get the machines collection
    $machines = Get-ManifestAsHashList $manifestPath

    #get all the vlans in the manifest
	$vlans = Get-AllVlansFromManifest $machines

    #get all the unique vlans as a collection
	$uniqueVlans = Get-UniqueVlans $vlans

    #generate the screen output
	Generate-IOSVlanScript $uniqueVlans
	
	Write-host "Press any key to continue"
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    . $parentMenu
	
} #function generateVlanConfigScript

function createLayer2VlanConfigScript{
param (
    [Parameter(Mandatory=$TRUE,Position=1)]$ParentMenu
)

	$bannerMessage = "Generate NEXUS Layer 2 VLAN Config Script"
    displayToolBanner $bannerMessage
    
    #select the manifest
    $manifestPath = Select-Tool -Label "Manifest" -path $manifestPath -parentMenu $parentMenu -filter "XML Files (*.XML)|*.XML"

	#get the machines collection
    $machines = Get-ManifestAsHashList $manifestPath
	
    #get all the vlans in the manifest
	$vlans = Get-AllVlansFromManifest $machines

    #get all the unique vlans as a collection
	$uniqueVlans = Get-UniqueVlans $vlans
		
    #get the first six characters of the first machine
    $siteCode = $machines[0].WinHostName.SubString(0,6)


	#select the output folder
	$folder = Select-Folder -currentFolder $dotRoot
	$outputFile = "$folder\$siteCode Layer2VLANs.txt"
	Write-Host "Output will be saved to File: $outputFile"
	

    #generate the output
	Generate-NEXUSVlanScript -uniqueVlans $uniqueVlans -ipHelper $machineIPHelper -logfile $outputFile -layer 2
	
	Write-host "Press any key to continue"
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    . $parentMenu
	
} #function createLayer2VlanConfigScript



function createLayer3VlanConfigScript{
param (
    [Parameter(Mandatory=$TRUE,Position=1)]$ParentMenu
)

	$bannerMessage = "Generate NEXUS Layer 3 VLAN Config Script"
    displayToolBanner $bannerMessage
    
    #select the manifest
    $manifestPath = Select-Tool -Label "Manifest" -path $manifestPath -parentMenu $parentMenu -filter "XML Files (*.XML)|*.XML"

	#get the machines collection
    $machines = Get-ManifestAsHashList $manifestPath
		
	#determine the most likely IP helper controller
	foreach ($machine in $machines)
	{
		$machineType = $machine.MachineType
		
		if($machineType -eq "OM EMS Server")
		{
			$machineIPHelper = $machine.netnic1IPAddress
		}
	
	}

    #get all the vlans in the manifest
	$vlans = Get-AllVlansFromManifest $machines

    #get all the unique vlans as a collection
	$uniqueVlans = Get-UniqueVlans $vlans
	
    #get the first six characters of the first machine
    $siteCode = $machines[0].WinHostName.SubString(0,6)


	#select the output folder
	$folder = Select-Folder -currentFolder $dotRoot
	$outputFile = "$folder\$siteCode Layer3VLANs.txt"
	Write-Host "Output will be saved to File: $outputFile"

	
    #generate the output
	Generate-NEXUSVlanScript -uniqueVlans $uniqueVlans -ipHelper $machineIPHelper -logfile $outputFile -layer 3
	
	Write-host "Press any key to continue"
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    . $parentMenu
	
} #function createLayer3VlanConfigScript



function Generate-NEXUSVlanScript{
param (
    [Parameter(Mandatory=$TRUE)]$uniqueVlans,
	[Parameter(Mandatory=$TRUE)]$logfile,
	[Parameter(Mandatory=$TRUE)][int]$layer,
	[Parameter(Mandatory=$FALSE)]$ipHelper
)

	if ($logfile){Remove-Item $logfile -Force}
	if (!($logfile)){New-Item $logfile}

    clear-host
	Write-Host "============================================================================"
	write-host "Generating VLAN syntax." -foregroundcolor Yellow
	Write-Host "============================================================================"
    Write-Host "   Simply cut and paste this into your console session"
	Write-Host "   Or use the logfile: $logfile"
	
	
	foreach ($vlan in $uniqueVlans)
	{
		[string]$vlanID = $vlan.vlanID
		[string]$vlanGateway = $vlan.vlanGateway
		[string]$vlanSubnetMask = $vlan.vlanSubnetMask
		[string]$vlanName = $vlan.vlanName
        [string]$vlanNetwork = $vlan.vlanNetwork
		[string]$vlanscope = $vlan.vlanScope		
		[string]$vlanSubnetCidr = $vlan.vlanSubnetCidr
		
		#ignore vlans named trunk
		if($vlanName.ToUpper() -eq "TRUNK"){Return}
		
		writeToLogFile $logfile  "!"
		
		if ($layer -eq 3)
		{	
			writeToLogFile $logfile  "Interface VLAN$vlanID"
	        writeToLogFile $logfile  "no shutdown"
			if ($vlanGateway -match $regexIPAddress) {writeToLogFile $logfile  "ip Address $vlanGateway/$vlanSubnetCidr"}
	        if ($ipHelper -match $regexIPAddress) {writeToLogFile $logfile  "ip dhcp relay address $ipHelper"}
			writeToLogFile $logfile  "Exit"
		}
		elseif ($layer -eq 2)
		{
			writeToLogFile $logfile  "VLAN $vlanID"
	        writeToLogFile $logfile  "name $vlanName"
	        #writeToLogFile $logfile  "no shutdown"
			writeToLogFile $logfile  "Exit"
		}
		else{ writeToLogFile $logfile "!!No Layer defined"; Read-Host; Return} 
		
		#writeToLogFile $logfile  "!"
	}
    Write-Host ""
	Write-Host "   Output saved to: $logfile"
	
	Write-host "Press any key to continue"
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    . $parentMenu
	
} #function Generate-NEXUSVlanScript

function createPortConfigScript{


}


function generateRDGMenu{
param (
    [Parameter(Mandatory=$TRUE,Position=1)]$ParentMenu
)
	clear-host	
	Write-Host "Create RDG from Manifest (RDCMan 2.2)" -ForegroundColor Yellow

	do{
	    write-host ""
		write-host "Select a way the RDG will connect to the machines"
		write-host "    1. netNic1ipAddress"
		Write-host "    2. winFQDN"
		Write-host "    3. Query Active Directory for host names"
	    write-host ""
    	$local:menuChoice = read-host "Please enter an option and press Enter"  

		$ok = $menuChoice -match '^[123]$'
	
	}until($ok)

	[bool]$activeDirectorySearch = $false

    Switch($menuChoice)
    {
        1{$connectionString = "netNic1ipAddress"}
    
        2{$connectionString = "winFqdn"}
		
		3{[bool]$activeDirectorySearch = $true}
    }
	
	if ($activeDirectorySearch -eq $true)
	{
		Write-Host ""
		$Domain = [System.DirectoryServices.ActiveDirectory.domain]::GetCurrentDomain();			
		Write-Host "Searching current Active Directory domain $Domain ..."
		$Searcher = New-Object System.DirectoryServices.DirectorySearcher($Domain.GetDirectoryEntry(),"(&(objectClass=computer))");
		$AdResults = $Searcher.FindAll()
		
		if(!($AdResults))
		{
			Write-host "No results returned from Active Directory!!"
			Write-host "Press any key to continue"
			$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

			generateRDGMenu
		}
		
		$qty = $AdResults.count
		Write-Host "Found $qty machines in Active Directory"
		
		#init the machines object
		$machines = @()
		
		$connectionString = "Name"
		
		Foreach ($result in $AdResults)
		{
			#init machine hashtable object
	    	$machineHash = @{}
			$directoryEntry = $result.GetDirectoryEntry().Name
			
			$machineHash.Add("Name", "$directoryEntry")
			
			#add machine hashtable object to array
	    	$machines += $machineHash
		}
	}
	else
	{
		$manifestPath = Select-Tool -Label "Manifest" -path $manifestPath -parentMenu $parentMenu -filter "XML Files (*.XML)|*.XML"
		#get the machines collection
    	$machines = Get-ManifestAsHashList $manifestPath

        #$return = YesNoExit -message "Would you like to group by machineType?" -default "yes"

        switch($return)
        {
            0{$groupByMachineType = $true}
            1{$groupByMachineType = $false}
            2{Return}
        }
	}
	
    
	
    #get the first six characters of the first machine
    $siteCode = $machines[0].WinHostName.SubString(0,6)

	#select the output folder
	$folder = Select-Folder -currentFolder $dotRoot
	$outputFile = "$folder\$siteCode by $connectionString.RDG"
	Write-Host "Output will be saved to File: $outputFile"
	
	create-rdgFromManifest -machines $machines -outputFile $outputFile -connectionString $connectionString -groupByMachineType $groupByMachineType
	
	Write-host "Press any key to continue"
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    . $parentMenu
}



function create-rdgFromManifest{
param (
    [Parameter(Mandatory=$TRUE)]$machines,
	[Parameter(Mandatory=$TRUE)]$outputFile,
	[Parameter(Mandatory=$TRUE)]$connectionString = "netNic1IPAddress",
	[Parameter(Mandatory=$FALSE)]$useActiveDirectory,
	[Parameter(Mandatory=$FALSE)]$groupByMachineType
)

	if (test-path $outputFile){Remove-Item $outputFile -Force}

$strRDCXml = @'
<?xml version="1.0" encoding="utf-8"?>
<RDCMan schemaVersion="1">
    <version>2.0</version>
    <file>                                
        <properties>
            <name>MRDOT Generated RDG</name>
            <expanded>True</expanded>
			<comment />
            <localResources inherit="None">
                <audioRedirection>0</audioRedirection>
                <keyboardHook>2</keyboardHook>
                <redirectClipboard>True</redirectClipboard>
                <redirectDrives>True</redirectDrives>
                <redirectPorts>False</redirectPorts>
                <redirectPrinters>False</redirectPrinters>
                <redirectSmartCards>False</redirectSmartCards>
            </localResources>                        
        </properties>           
    </file>
</RDCMan>
'@;

	$xmlDoc = New-Object System.Xml.XmlDataDocument;
	$xmlDoc.LoadXml($strRDCXml);

	$fileNode = $xmlDoc.SelectSingleNode("//file");

	#parent group node
	[System.Xml.XmlNode]$parentGroupNode = $xmlDoc.CreateElement("group");	
	$null = $fileNode.AppendChild($parentGroupNode);

	[System.Xml.XmlNode]$propertiesNode = $xmlDoc.CreateElement("properties");	
	$null = $parentGroupNode.AppendChild($propertiesNode);

	    $ChildNode = $xmlDoc.CreateElement("name");
		$ChildNode.psbase.InnerText = "Connecting by $connectionString";
		$null = $propertiesNode.AppendChild($ChildNode);
			

	foreach($machine in $machines)
	{
		$machineType = $machine.MachineType
		if($machineType){if ($machineType.Contains("Azuki") -or $machineType.Contains("Reach")){Continue}}

        
        #add an asterisk to the name if the connection string isnt found
		$connectionStringValue = $machine.$connectionString
		if (!($connectionStringValue)){Write-Host "$connectionString not found in the manifest"; $addAst = "*"}
	
		[System.Xml.XmlNode]$serverNode = $xmlDoc.CreateElement("server");	
		$null = $parentGroupNode.AppendChild($serverNode);	
			
			[System.Xml.XmlNode]$nameNode = $xmlDoc.CreateElement("name");	
	        $nameNode.psbase.InnerText = $connectionStringValue;
			$null = $serverNode.AppendChild($nameNode);
						
			$machineName = $machine.Name
			if($addAst){$machineName = $machineName + $addAst}
		
			Write-Host "Adding $machineName"
			$ChildNode = $xmlDoc.CreateElement("displayName");
			$ChildNode.psbase.InnerText = $MachineName;
			$null = $serverNode.AppendChild($ChildNode);
			
			$ChildNode = $xmlDoc.CreateElement("comment");			
			$null = $serverNode.AppendChild($ChildNode);
			
			$ChildNode = $xmlDoc.CreateElement("logonCredentials");			
			$null = $serverNode.AppendChild($ChildNode);	
			$attribute = $xmlDoc.CreateAttribute("inherit");
			$attribute.Value = "FromParent";
			$null = $ChildNode.Attributes.Append($attribute);		

			$ChildNode = $xmlDoc.CreateElement("connectionSettings");			
			$null = $serverNode.AppendChild($ChildNode);
			$attribute = $xmlDoc.CreateAttribute("inherit");
			$attribute.Value = "FromParent";
			$null = $ChildNode.Attributes.Append($attribute);		
			
			$ChildNode = $xmlDoc.CreateElement("gatewaySettings");			
			$null = $serverNode.AppendChild($ChildNode);
			$attribute = $xmlDoc.CreateAttribute("inherit");
			$attribute.Value = "FromParent";
			$null = $ChildNode.Attributes.Append($attribute);		
			
			$ChildNode = $xmlDoc.CreateElement("remoteDesktop");			
			$null = $serverNode.AppendChild($ChildNode);
			$attribute = $xmlDoc.CreateAttribute("inherit");
			$attribute.Value = "FromParent";
			$null = $ChildNode.Attributes.Append($attribute);		
			
			$ChildNode = $xmlDoc.CreateElement("localResources");			
			$null = $serverNode.AppendChild($ChildNode);
			$attribute = $xmlDoc.CreateAttribute("inherit");
			$attribute.Value = "FromParent";
			$null = $ChildNode.Attributes.Append($attribute);		
			
			$ChildNode = $xmlDoc.CreateElement("securitySettings");			
			$null = $serverNode.AppendChild($ChildNode);
			$attribute = $xmlDoc.CreateAttribute("inherit");
			$attribute.Value = "FromParent";
			$null = $ChildNode.Attributes.Append($attribute);		
			
			$ChildNode = $xmlDoc.CreateElement("displaySettings");			
			$null = $serverNode.AppendChild($ChildNode);
			$attribute = $xmlDoc.CreateAttribute("inherit");
			$attribute.Value = "FromParent";
			$null = $ChildNode.Attributes.Append($attribute);		
		}		

        write-host "File Saved to: $outputFile"

		$xmlDoc.Save($outputFile);

}



