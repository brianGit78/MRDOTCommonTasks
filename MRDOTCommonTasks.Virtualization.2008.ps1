

function vmm2008ToolsMenu{

    do{
        Clear-host
        $bannerMessage = "Virtual Machine Manager 2008 R2 Tools"
        displayToolBanner $bannerMessage

		Write-host "    1. Register VM Host Servers with VMM"
        Write-host "    2. Name Virtual Networks"
        Write-host "        (Update Virtual Switch names to match VM Host NIC names)"
        Write-host "    3. Build Default Hardware Profiles"
        Write-host "    4. Create Virtual Machines from your Manifest"
        Write-host "    5. Start all Virtual Machines"
		Write-host "    6. Convert Legacy Network Adapters to Synthetic"
        Write-host "    7. Prepare VM Host Storage"
        Write-host "    8. Rebalance All Virtual Machines according to the Manifest"
        Write-host "    9. Convert All VHDs to fixed sized disks"
		write-host "    0. Return to Main Menu"
		write-host ""
		
		$local:menuChoice = read-host "Please enter an option and press Enter"  
		[string]$thisFunction = $MyInvocation.MyCommand
			
		$ok = $menuChoice -match '^[0123467890]$'

		}until($ok)
		
	    Switch($menuChoice)
	    {		
			1{RegisterVMHostServersWithVMMMenu $thisFunction}
	        2{NameVirtualNetworksMenu $thisFunction}
            3{BuildDefaultHardwareProfilesMenu $thisFunction}            
            4{createVirtualMachinesFromManifestMenu $thisFunction}
            5{StartAllVMsMenu $thisFunction}
            6{convertLegacyToSyntheticMenu $thisFunction}
            7{PrepareVMHostStorageMenu $thisFunction}
            8{RebalanceAllVMsMenu $thisFunction}
            9{ConvertAllVHDsToFixedMenu $thisFunction}
			0{mainMenu}
	    }
}

function RegisterVMHostServersWithVMMMenu($parentMenu)
{
	$bannerMessage = "Register VM Host Servers with VMM"
    displayToolBanner $bannerMessage

    #select the manifest
    $manifestPath = Select-Tool -Label "Manifest" -path $manifestPath -parentMenu $parentMenu -filter "XML Files (*.XML)|*.XML"

    RegisterVMHosts $manifestPath
    #RegisterVMHosts([string]$strManifestXML,[string]$strUser,[string]$strPassword,[string]$bFixedDisks)
    
    pressAnyKeyToReturn -parentMenu $parentMenu
}

function NameVirtualNetworks($parentMenu)
{
	$bannerMessage = "Name Virtual Networks"
    displayToolBanner $bannerMessage

    #select the manifest
    $manifestPath = Select-Tool -Label "Manifest" -path $manifestPath -parentMenu $parentMenu -filter "XML Files (*.XML)|*.XML"
    
    $message = "Do you want to enable VLAN tagging?"
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Enable VLAN tagging"
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Do not enable VLAN tagging"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    $result = $host.ui.PromptForChoice($title, $message, $options, 0)
    if ($result -eq 0){$choiceVlanTagging -eq $true}else{$choiceVlanTagging -eq $false}

    NameVirtualNetworks $manifestPath $choiceVlanTagging
    #NameVirtualNetworks([string]$strManifestXML,[bool]$vLANTaggingEnabled)
    
    pressAnyKeyToReturn -parentMenu $parentMenu
}

function BuildDefaultHardwareProfilesMenu($parentMenu)
{
    Write-host "Press any key to Build the VMM Hardware Profiles"
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    BuildHardwareProfiles
    #function BuildHardwareProfiles([bool]$enablerapidprovisioning,[string]$strUser,[string]$strPassword)

    pressAnyKeyToReturn -parentMenu $parentMenu
}


function createVirtualMachinesFromManifestMenu($parentMenu)
{
	$bannerMessage = "Create Virtual Machines from Manifest (SCVMM 2008 R2)"
    displayToolBanner $bannerMessage

    #select the manifest
    $manifestPath = Select-Tool -Label "Manifest" -path $manifestPath -parentMenu $parentMenu -filter "XML Files (*.XML)|*.XML"

    $message = "Do you want to enable VLAN tagging?"
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Enable VLAN tagging"
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Do not enable VLAN tagging"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    $result = $host.ui.PromptForChoice($title, $message, $options, 0)
    if ($result -eq 0){$choiceVlanTagging -eq $true}else{$choiceVlanTagging -eq $false}
    
    CreateVirtualMachinesfromManifest $manifestPath $choiceVlanTagging $true
    #function CreateVirtualMachinesfromManifest([string]$strManifestXML,[bool]$vLANTaggingEnabled,[bool]$bCreateAsync, [bool] $enablerapidprovisioning)
              
    pressAnyKeyToReturn -parentMenu $parentMenu
}

function StartAllVMsMenu($parentMenu)
{
	Write-host "Press any key to begin starting all VMs"
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    startVMs 10 1
    #function startVMs([int]$iVMsPerHost,[int]$iSleep)
    
    pressAnyKeyToReturn -parentMenu $parentMenu
}


function convertLegacyToSyntheticMenu($parentMenu)
{
	$bannerMessage = "Convert Legacy Network Adapters to Synthetic"
    displayToolBanner $bannerMessage
    
    write-host "    It is important that your machines DO NOT have static IP addresses configured before this is run." -ForgroundColor Yellow
    write-host "    This will shut down all of your virtual machines that have legacy network adapters." -ForgroundColor Yellow

	
	$message = "Would you like to continue?"
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Convert All machines in the manifest"
    $exit = New-Object System.Management.Automation.Host.ChoiceDescription "E&xit", "Return to the previous menu"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $exit)
    $result = $host.ui.PromptForChoice($title, $message, $options, 0)
    if ($result -eq 1){. $parentMenu}
    
    #select the manifest
    $manifestPath = Select-Tool -Label "Manifest" -path $manifestPath -parentMenu $parentMenu -filter "XML Files (*.XML)|*.XML"

    Convert_LegacyToSynthetic $manifestPath
    #function Convert_LegacyToSynthetic([string]$strManifest,[string]$strMachineTypes)

	pressAnyKeyToReturn -parentMenu $parentMenu
}


function PrepareVMHostStorageMenu($parentMenu)
{
	$bannerMessage = "Prepare VM Host Storage Menu"
    displayToolBanner $bannerMessage
    
    #select the manifest
    $manifestPath = Select-Tool -Label "Manifest" -path $manifestPath -parentMenu $parentMenu -filter "XML Files (*.XML)|*.XML"
    
    PrepareHostStorage $manifestPath
    #Function PrepareHostStorage([string]$strManifestXML)
    
    
    pressAnyKeyToReturn -parentMenu $parentMenu
}

function RebalanceAllVMsMenu($parentMenu)
{
	$bannerMessage = "Rebalance All Virtual Machines"
    displayToolBanner $bannerMessage
     
    #select the manifest
    $manifestPath = Select-Tool -Label "Manifest" -path $manifestPath -parentMenu $parentMenu -filter "XML Files (*.XML)|*.XML"
    
    RebalanceVirtualMachines $manifestPath
    #function RebalanceVirtualMachines([string]$manifest)
    
    pressAnyKeyToReturn -parentMenu $parentMenu
}

function ConvertAllVHDsToFixedMenu($parentMenu)
{
	$bannerMessage = "Convert all VHDs to Fixed Size"
    displayToolBanner $bannerMessage
    
    write-host "Warning: This will not calculate the disk space required in advance. Use with the highest CAUTION and verify your calculations." -forgroundcolor Red
      
   	$message = "Would you like to continue?"
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Convert ALL machines in the manifest"
    $exit = New-Object System.Management.Automation.Host.ChoiceDescription "E&xit", "Return to the previous menu"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $exit)
    $result = $host.ui.PromptForChoice($title, $message, $options, 1)
    if ($result -eq 1){. $parentMenu}
    
    ConvertVhdToFixedDisk
    #function ConvertVhdToFixedDisk()
    
    pressAnyKeyToReturn -parentMenu $parentMenu
}