
function vmm2012R2ToolsMenu{
		
    do{
        Clear-host
       	$bannerMessage = "Virtual Machine Manager 2012 R2 Tools"
        displayToolBanner $bannerMessage

        Write-host "    1. Build Default Hardware Profiles"
		Write-host "    2. Create Virtual Machines from Manifest"
		Write-host "    2. Convert Legacy Network Adapters to Synthetic Network Adapters"
		Write-host "    3. Convert Synthetic Network Adapters to Legacy Network Adapters2"
		write-host "    4. Create SCVMM 2012 R2 Hardware Profiles based on MachineType"
		write-host "    0. Return to Main Menu"
		write-host ""
		
		$local:menuChoice = read-host "Please enter an option and press Enter"  
		[string]$thisFunction = $MyInvocation.MyCommand
			
		$ok = $menuChoice -match '^[01234]$'
		
		}until($ok)	
		
		Switch($menuChoice)
	    {
            1{BuildDefaultHardwareProfilesMenu $thisFunction}

	        2{createVirtualMachinesFromManifestMenu2012R2 $thisFunction}

            #2{scvmm2012r2-LegacyToSyntheticMenu $thisFunction}

	        3{legacyToSyntheticMenu $thisFunction}

            #4{createVirtualMachinesFromManifestMenu2012R2 $thisFunction}
			
			0{mainMenu}
	    }	
}

function BuildDefaultHardwareProfilesMenu($parentMenu)
{
    Write-host "Press any key to Build the VMM Hardware Profiles"
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    BuildHardwareProfiles
    #function BuildHardwareProfiles([bool]$enablerapidprovisioning,[string]$strUser,[string]$strPassword)

    pressAnyKeyToReturn -parentMenu $parentMenu
}



function createVirtualMachinesFromManifestMenu2012R2($parentMenu)
{
	$bannerMessage = "Create Virtual Machines from Manifest (SCVMM 2012 R2)"
    displayToolBanner $bannerMessage

    #select the manifest
    $manifestPath = Select-Tool -Label "Manifest" -path $manifestPath -parentMenu $parentMenu -filter "XML Files (*.XML)|*.XML"

    $machines = Get-Machines $manifestPath


    $return = YesNoExit -message "Do you want to update the networks of existing virtual machines?" -default "yes"

    switch ($return)
    {
        0 {Create-VirtualMachinesfromManifest $machines -updateNetworks}
        1 {Create-VirtualMachinesfromManifest $machines}
        2 {. $parentMenu}
    }
              
	Write-host "Press any key to continue"
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    . $parentMenu 
}



function legacyToSyntheticMenu
{
	$bannerMessage = "Generate VLAN Config Script"
    displayToolBanner $bannerMessage

	#options:
	#change all in manifest
	#force shutdown?
	
	$message = "Do you want to change all the machines in the manifest to synthetic?"
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Update the Network settings"
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Ignore Virtual Machines that exist"
    $exit = New-Object System.Management.Automation.Host.ChoiceDescription "E&xit", "Exit this function."
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no, $exit)
    $result = $host.ui.PromptForChoice($title, $message, $options, 0)

    switch ($result)
    {
        0 {
			$manifestPath = Select-Tool -Label "Manifest" -path $manifestPath -parentMenu $parentMenu -filter "XML Files (*.XML)|*.XML"
			$machines = Get-ManifestAsHashList $manifestPath
			Change-LegacyNicToSynthetic $machines
		  }
		  
        1 {Create-VirtualMachinesfromManifest $machines}
        2 {. $parentMenu}
    }
	
	write-host "Press Enter to continue..."
	Read-host
	. $parentMenu
}


