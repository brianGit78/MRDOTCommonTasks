
function sccmToolsMenu
{
    do{
		Clear-Host
	    write-host ""
	    write-host "=====================================================================" -foregroundcolor $menuBannerColor
	    write-host "    ConfigMgr (SCCM) Tools Menu                                            " -foregroundcolor $menuBannerColor
	    write-host "=====================================================================" -foregroundcolor $menuBannerColor
		write-host ""
		Write-host "    1. Import Variables from Manifest"
	    Write-host "    2. Restart Workflow Service"
	    Write-host "    3. Refresh All SCCM packages"
	    Write-host "    4. Update RunAs account on SCCM Task Sequences"
	    Write-host "    5. Open PXE Control Log in trace32"
		Write-host "    6. Open MRDOT Server Center"
        #Write-host "    7. Generate MRCC CHM File"		
        write-host "    0. Return to Main Menu"		
	    write-host ""
	    getControllerPrereqs
		
	    $local:menuChoice = read-host "Please enter an option and press Enter"  
	    [string]$thisFunction = $MyInvocation.MyCommand

		$ok = $menuChoice -match '^[01234567]$'
	
	}until($ok)
	
	
    Switch($menuChoice)
    {
    	1{importVariablesFromManifest $thisFunction}

		2{restartWorkflowServiceMenu $thisFunction}

		3{updateSCCMPackagesMenu $thisFunction}

		4{updateRunAsAccountsMenu $thisFunction}
		
		5{openPxeControlLogTrace32 $thisFunction}
		
		6{openMrdotServerCenter $thisFunction}
		
		0{mainMenu}
    }

}


#this is a read only menu item that lists SCCM dependent values
function getControllerPrereqs
{
	displayManifestPath
	
	#check for sccmie
	if (!(test-path $sccmiePath)){$statusColor = "Red"}else{$statusColor = "Green"}
	write-host "Path to SCCMIE.EXE:" -nonewline
    write-host "		$sccmiePath" -foregroundcolor $statusColor
    	
	#Check if SCCM is installed and which version
	$sccmInstalled = Get-Service -name SMS_EXECUTIVE -ErrorAction SilentlyContinue
	Write-Host "Configuration Manager" -NoNewline
	
	if ($sccmInstalled)
	{	
		Write-Host "		Installed" -ForegroundColor Green -NoNewline
		[string]$svcStatus = $sccmInstalled.Status
		if ($svcStatus -eq "Stopped")
		{
			Write-Host " (Service is $svcStatus)" -foregroundColor Red
		}
		else
		{
			Write-Host " (Service is $svcStatus)" 
		}
		
	}
	else 
	{
		Write-Host "		Not Installed" -ForegroundColor Red
	}
	
	#check if workflow engine is installed
	$workflowSvcInstalled = Get-Service -name WorkflowRuntimeService -ErrorAction SilentlyContinue
	Write-Host "Workflow Runtime Service" -NoNewline
	if ($workflowSvcInstalled)
	{
		Write-Host "	Installed" -ForegroundColor Green -NoNewline
		[string]$svcStatus = $workflowSvcInstalled.Status
				if ($svcStatus -eq "Stopped")
		{
			Write-Host " (Service is $svcStatus)" -foregroundColor Red
		}
		else
		{
			Write-Host " (Service is $svcStatus)" 
		}
	}
	else 
	{
		Write-Host "	Not Installed" -ForegroundColor Red
	}
	
	#check if Windows Deployment Services is installed
	$wdsSvcInstalled = Get-Service -name WDSServer -ErrorAction SilentlyContinue
	Write-Host "Windows Deployment Service" -NoNewline
	if ($wdsSvcInstalled )
	{	
		Write-Host "	Installed" -ForegroundColor Green -NoNewline
		[string]$svcStatus = $wdsSvcInstalled.Status
		
		if ($svcStatus -eq "Stopped")
		{
			Write-Host " (Service is $svcStatus)" -foregroundColor Red
		}
		else
		{
			Write-Host " (Service is $svcStatus)" 
		}
	}
	else 
	{
		Write-Host "	Not Installed" -ForegroundColor Red
	}
}



function importVariablesFromManifest($parentMenu)
{	
	$bannerMessage = "Import Variables from Manifest"
    displayToolBanner $bannerMessage
	
	$sccmiePath = Select-Tool -Label "SCCMIE.EXE" -path $sccmiePath -parentMenu $parentMenu -filter "SCCMIE.EXE (SCCMIE.EXE)|SCCMIE.EXE"
	
	$manifestPath = Select-Tool -Label "Manifest" -path $manifestPath -parentMenu $parentMenu -filter "XML Files (*.XML)|*.XML"
	
    #check if we would like to clean the values
	$message = "Do you want to remove all existing values while importing?"
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Remove all values and then import"
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Overwrite existing values, leave ones not in the manifest"
    $exit = New-Object System.Management.Automation.Host.ChoiceDescription "E&xit", "Exit this function."
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no, $exit)
    $result = $host.ui.PromptForChoice($title, $message, $options, 0)
    switch ($result)
    {
        0 {$strCmd = "$sccmiePath -clean -importdevices -manifest $manifestPath"}
        1 {$strCmd = "$sccmiePath -importdevices -manifest $manifestPath"}
        2 {. $parentMenu}
    }
	    
    write-host $strCmd

    cmd.exe /c $strCmd
	
    Write-host "Press any key to continue"
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    . $parentMenu
}






function restartWorkflowServiceMenu($parentMenu)
{
	$bannerMessage = "Restart the Workflow Service"
    displayToolBanner $bannerMessage

    $strWorkflowSvc = "WorkflowRuntimeService"

    $wrkFlowSvc = Get-Service $strWorkflowSvc -ErrorAction SilentlyContinue

    if($wrkFlowSvc)
    {
    	if ($wrkFlowSvc.Status -eq "Running")
        {	
			$strCMD = "net stop $strWorkflowSvc && net start $strWorkflowSvc"
            write-host "cmd.exe/c $strCMD"
            cmd.exe /c $strCMD

            pressAnyKeyToReturn -parentMenu $parentMenu
		}
		else 
		{
			$strCMD = "net start $strWorkflowSvc"
            write-host "cmd.exe/c $strCMD"
            cmd.exe /c $strCMD

            pressAnyKeyToReturn -parentMenu $parentMenu
		}
    }
    else
    {
        write-host "$strWorkflowSvc is not installed on this machine"

        pressAnyKeyToReturn -parentMenu $parentMenu
    }
}

function updateSCCMPackagesMenu
{
	$bannerMessage = "Update SCCM Packages from their source"
    displayToolBanner $bannerMessage

	$sccmiePath = Select-Tool -Label "SCCMIE.EXE" -path $sccmiePath -parentMenu $parentMenu -filter "SCCMIE.EXE (SCCMIE.EXE)|SCCMIE.EXE"
	
	$strCmd = "$sccmiePath -updatepkgs -All"
	    
    write-host $strCmd

    cmd.exe /c $strCmd
	
    Write-host "Press any key to continue"
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    . $parentMenu
}

function updateRunAsAccountsMenu
{
	$bannerMessage = "Update RunAs Accounts"
    displayToolBanner $bannerMessage

	$sccmiePath = Select-Tool -Label "SCCMIE.EXE" -path $sccmiePath -parentMenu $parentMenu -filter "SCCMIE.EXE (SCCMIE.EXE)|SCCMIE.EXE"

	$runAsAccount = read-host "Run As Account"
	$runasPassword = read-host -assecurestring "Password for $runAsAccount"

	$strCmd = "$sccmiePath -upp -runasuser $runasuser -runaspassword $runasPassword"

	write-host $strCmd

    cmd.exe /c $strCmd
	
    write-host "Press Enter to continue..."
    Read-host
    . $parentMenu 
}

function openPxeControlLogTrace32($parentMenu)
{	
	$bannerMessage = "Open PXE Control Log in Trace32"
    displayToolBanner $bannerMessage

    $trace32Path = Select-Tool -Label "Trace32" -path $trace32Path -parentMenu $parentMenu -filter "EXE Files (*.EXE)|*.EXE"


    $pxeControlLogPath = Select-Tool -Label "PXEControlLog" -path $pxeControlLogPath -parentMenu $parentMenu

    . $trace32Path $pxeControlLogPath

    Write-Host "Press Enter to continue"
    Read-Host 
    Return $parentMenu
}

function openMrdotServerCenter($parentMenu)
{
	$bannerMessage = "Open MRDOT Server Center"
    displayToolBanner $bannerMessage

	$mrdotServerCenterPath = Select-Tool -Label "MRDOTServerCenter" -path $mrdotServerCenterPath -parentMenu $parentMenu
    
    . $mrdotServerCenterPath 
    Write-Host "Press Enter to continue"
    Read-Host 
    . $parentMenu
}
