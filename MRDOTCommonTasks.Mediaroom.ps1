
function mediaroomServerToolsMenu
{
	do{
	    Clear-Host
	    write-host ""
	    write-host "=====================================================================" -foregroundcolor $menuBannerColor
	    write-host "    Mediaroom Server Tools Menu                                                " -foregroundcolor $menuBannerColor
	    write-host "=====================================================================" -foregroundcolor $menuBannerColor
	    write-host ""
	    write-host "	1. Get detailed Mediaroom Configuration"
		write-host "	2. Dump Mediaroom Running Configuration to XML"
		write-host "	3. Open SMSTS.Log in Trace32"
	    #write-host "	x. Resolve AD certificate in machine store (not enabled)"
	    #write-host "	x. Generate MRCC data (not enabled)
		write-host "	0. Return to main menu"
		write-host ""
		getMRPrereqs
		
	    $local:menuChoice = read-host "Please enter an option and press Enter"  
	    [string]$thisFunction = $MyInvocation.MyCommand

		$ok = $menuChoice -match '^[0123]$'
	
	}until($ok)

    Switch($menuChoice)
    { 
		1{getMediaroomRunningConfigBrief $thisFunction}
		
		2{getMediaroomRunningConfig $thisFunction}
		  
		3{openSmsTsLogTrace32 $thisFunction}

        0{mainMenu}
    }
}


$Global:mediaroomConfigEngine = "C:\Program Files\Microsoft IPTV Services\bin\ComPlus\configuration.dll"


function getMediaroomRunningConfig($parentMenu)
{
    $bannerMessage = "Get Mediaroom Running Config (config engine)"
    displayToolBanner $bannerMessage

	$runningConfigFile = "$dotRoot\RunningConfig.xml"
    if (Test-Path $runningConfigFile){Remove-Item $runningConfigFile -force}

    $mediaroomConfigEngine = Select-Tool -Label "ConfigEngine" -path $mediaroomConfigEngine -parentMenu $parentMenu -filter "Mediaroom Config Engine (configuration.dll)|configuration.dll"

	[reflection.assembly]::LoadFrom(“$mediaroomConfigEngine”)
	
	#get the configuration
	[Microsoft.TV2.Server.Common.Configuration.Configuration]::GetConfig() | Out-File $runningConfigFile

	Write-Host "Configuration has been saved to $runningConfigFile"

	Write-Host "Press Enter to continue..."
	Read-Host
	. $parentMenu
}



function openSmsTsLogTrace32($parentMenu)
{	
	$bannerMessage = "Open SMSTsLog in Trace32"
    displayToolBanner $bannerMessage

    $trace32Path = Select-Tool -Label "Trace32.exe" -path $trace32Path -parentMenu $parentMenu -filter "EXE Files (*.EXE)|*.EXE"

    $smsTsLogPath = Select-Tool -Label "SMSTSLog" -path $smsTsLogPath -parentMenu $parentMenu

    . $trace32Path $smsTsLogPath; 
    Write-Host "Press Enter to continue" 
    Read-Host
    . $parentMenu
}



function getMediaroomRunningConfigBrief($parentFunction)
{
	Clear-Host
	
	if (!(test-path $mediaroomConfigEngine))
	{
		Write-Host "Mediaroom is not installed."
		Write-Host "Press Enter to return to previous menu"
		Read-Host
		. $parentFunction
	}
	
	$null = [System.Reflection.Assembly]::LoadFrom("$mediaroomConfigEngine");
    $global:configEngine = New-Object Microsoft.TV2.Server.Common.Configuration.InstalledEngine;
	
	Write-Host "Gathering Mediaroom System Information..."
	#$installedMrSw = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -match "Mediaroom"} 
	#-Query "SELECT * FROM Win32_Product WHERE Name LIKE `"%Mediaroom%`" "
	
	Clear-Host
	$bannerMessage = "Mediaroom System Information"
    displayToolBanner $bannerMessage
	
	getMRPrereqs
	
	$mrZone = $global:configEngine.GetCurrentZoneName();
	Write-Host "Serverlayout Zone:		"$mrZone
	
	
	Write-Host "Groups:"
	$mrGroup = $global:configEngine.GetGroups();
	foreach ($group in $mrGroup)
	{
		Write-Host "				"$group
	}
	
	#Write-Host "Mediaroom Server Roles:"
	foreach($role in $global:configEngine.GetRolesForServer([System.Environment]::MachineName))
	{
		#write-host "	" $role
	}
	
	
	
	Write-Host "Installed Mediaroom Packages:"
	foreach ($mrSoftware in $installedMrSw)
	{
		$displayName = $mrSoftware.Name
		Write-Host "				$displayName"
	}
	

	
	
	Read-Host "Press Enter to Continue"
	
	. $parentMenu

}



function getMRPrereqs
{
	#Check if Mediaroom is installed and which version
    #config engine path is loaded from external xml file
    #$mediaroomConfigEngine = "C:\Program Files\Microsoft IPTV Services\bin\ComPlus\configuration.dll"

	if (test-path $mediaroomConfigEngine)
    {	
        $null = [System.Reflection.Assembly]::LoadFrom("$mediaroomConfigEngine");
        $global:configEngine = New-Object Microsoft.TV2.Server.Common.Configuration.InstalledEngine;
	    $mrName = $global:configEngine.GetCurrentPublicName()
		$branchName = $global:configEngine.GetCurrentBranchName();

        $mediaroomInstalled = $true
		
		Write-Host "Mediaroom Config Engine:" -NoNewline
		Write-Host "	Installed" -ForegroundColor Green
		
		Write-Host "Host Name:			$mrName"
		Write-Host "ServerLayout Branch: 		$branchName"
		Write-Host ""		
    }
	else {Write-Host "Mediaroom" -NoNewline; Write-Host "			Not Installed" -ForegroundColor Red}
}