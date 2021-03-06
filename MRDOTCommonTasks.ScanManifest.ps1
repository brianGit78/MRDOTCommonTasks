function scanManifestForErrors($parentMenu)
{
	$bannerMessage = "Scan Manifest for Common Errors"
    displayToolBanner $bannerMessage

    #select the manifest
    $manifestPath = Select-Tool -Label "Manifest" -path $manifestPath -parentMenu $parentMenu -filter "XML Files (*.XML)|*.XML"

	#scan output file
	$scanlog = "$dotRoot\Logs\ManifestScan.txt"
	
	scanManifestForCommonErrors -manifestpath $manifestPath -refarchTable $refarchTablePath -logfile $scanlog
	
	Write-host "Press any key to continue"
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    . $parentMenu
	
} #function scanManifestForErrors




function scanManifestForCommonErrors{
param (
    [Parameter(Mandatory=$TRUE,Position=1)]$manifestPath,
	[Parameter(Mandatory=$FALSE,Position=2)]$refarchTablePath,
	[Parameter(Mandatory=$TRUE,Position=3)]$logfile
)	

	if ($logfile){Remove-Item $logfile -Force}
	if (!($logfile)){New-Item $logfile}
	
	Clear-Host 
    writeToLogFile $logfile "=====================================================================" -foregroundcolor $menuBannerColor
    writeToLogFile $logfile "    Scanning Manifest for common Errors                              " -foregroundcolor $menuBannerColor
    writeToLogFile $logfile "=====================================================================" -foregroundcolor $menuBannerColor
    writeToLogFile $logfile "Hello $ENV:USERDOMAIN\$ENV:USERNAME !" 
    writeToLogFile $logfile ""
	writeToLogFile $logfile ""
	writeToLogFile $logfile "Using Manifest: $manifestPath"
	writeToLogFile $logfile "Using Reference Architecture File: $refarchtablepath"
	writeToLogFile $logfile ""
	writeToLogFile $logfile " This tool will scan your manifest for typical errors that could impede your deployment"
	writeToLogFile $logfile " Output of this tool can be found in: $logfile"
	
	if (!(Test-Path $manifestPath)){writeToLogFile $logfile "Unable to find manifest path: $manifestPath, aborting."; Read-Host; .$parentFunction}
	
	$machines = Get-ManifestAsHashList $manifestPath
	if (!($machines)){writeToLogFile $logfile "Something went wrong creating the machines object, aborting."; Read-Host; .$parentFunction}
	
	$return = YesNoExit -message "Would you like to continue?" -default "yes"
	if ($return -ne 0){Return}
	
	#check that netnic1 parameters are set correctly
	writeToLogFile $logfile ""
	writeToLogFile $logfile "===================================================================="
	writeToLogFile $logfile " Checking netNic1 is configured correctly"
	writeToLogFile $logfile " 	-Well formed ipAddress, mac, subnetMask and if applicable, gateway"
	writeToLogFile $logfile " 	-Verifying DNS registration on netNic1 is TRUE"
	writeToLogFile $logfile ""


	foreach ($machine in $machines)
	{
	    [string]$machinewinHostname = $machine.winHostname
	    [string]$machinenetNic1IpAddress = $machine.netNic1IpAddress
	    [string]$machinenetNic1MacAddress = $machine.netNic1MacAddress
	    [string]$machinenetNic1SubnetMask = $machine.netNic1SubnetMask
		[string]$machinenetNic1DefaultGateway = $machine.netNic1DefaultGateway
	    [string]$machinenetNic1DnsRegistrationEnabled = $machine.netNic1DnsRegistrationEnabled.ToUpper()

	    #check the IP Address
	    if ($machinenetNic1IpAddress -match $regexIPAddress)
	    {
	        writeToLogFile $logfile "$machinewinHostname netNic1IpAddress: $machinenetNic1IpAddress is well formed" -ForegroundColor Green
	    }
	    else
	    {
	        writeToLogFile $logfile "$machinewinHostname netNic1IpAddress: $machinenetNic1IpAddress is NOT well formed" -ForegroundColor Red
	    }

	    #check the mac address
	    if ($machinenetNic1MacAddress -match $regexMacAddress)
	    {
	        writeToLogFile $logfile "$machinewinHostname netNic1MacAddress: $machinenetNic1MacAddress is well formed" -ForegroundColor Green
	    }
	    else
	    {
	        writeToLogFile $logfile "$machinewinHostname netNic1MacAddress: $machinenetNic1MacAddress is NOT well formed" -ForegroundColor Red
	    }

	    #check the subnet mask
	    if ($machinenetNic1SubnetMask -match $regexSubnetMask)
	    {
	        writeToLogFile $logfile "$machinewinHostname netNic1SubnetMask: $machinenetNic1SubnetMask is well formed" -ForegroundColor Green
	    }
	    else
	    {
	        writeToLogFile $logfile "$machinewinHostname netNic1SubnetMask: $machinenetNic1SubnetMask is NOT well formed" -ForegroundColor Red
	    }

	    #check for DNS registration
	    if ($machinenetNic1DnsRegistrationEnabled -eq "TRUE")
	    {
	        writeToLogFile $logfile "$machinewinHostname netNic1DnsRegistrationEnabled is set to register in DNS (TRUE)" -ForegroundColor Green
	    }
	    else
	    {
	        writeToLogFile $logfile "$machinewinHostname netNic1DnsRegistrationEnabled is NOT set to register in DNS (FALSE)" -ForegroundColor Red
	    }
		
		if ($machinenetNic1DefaultGateway -match $regexIPAddress)
	    {
	        writeToLogFile $logfile "$machinewinHostname netNic1DefaultGateway: $machinenetNic1DefaultGateway is well formed.)" -ForegroundColor Green
	    }
	    else
	    {
	        writeToLogFile $logfile "$machinewinHostname netNic1DefaultGateway: $machinenetNic1DefaultGateway is NOT a well formed IP Address" -ForegroundColor Red
	    }
	}

	Write-host "Press any key to continue"
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Clear-Host
	
	#check virtual machine settings
	
	#if attached to SCVMM server, verify the servers are up
	

	
	#Present the count of reference architecture roles
	writeToLogFile $logfile ""
	writeToLogFile $logfile "===================================================================="
	writeToLogFile $logfile " Verifying Nic IP Addresses are in the same subnet as their gateway"
	writeToLogFile $logfile ""
	
	
	#verify gateway within range
	#http://get-powershell.com/post/2010/01/30/Determining-if-IP-addresses-are-on-the-same-subnet.aspx
	Function Test-SameSubnet { 
	param ( 
		[parameter(Mandatory=$true)] 
		[Net.IPAddress] 
		$ip1, 

		[parameter(Mandatory=$true)] 
		[Net.IPAddress] 
		$ip2, 

		[parameter()] 
		[alias("SubnetMask")] 
		[Net.IPAddress] 
		$mask
	) 
		if (!($ip1 -or $ip2 -or $mask)){writeToLogFile $logfile "ip1, ip2, or subnet not specified" ; throw "need all three parameters"}
		if (($ip1.address -band $mask.address) -eq ($ip2.address -band $mask.address)) {[bool]$sameSubnet = $true} 
		else {[bool]$sameSubnet = $false} 

		Return $sameSubnet
	} 
	
	foreach ($machine in $machines)
	{
	    [string]$machinewinHostname = $machine.winHostname
	    [string]$machinenetNic1IpAddress = $machine.netNic1IpAddress
	    [string]$machinenetNic1MacAddress = $machine.netNic1MacAddress
	    [string]$machinenetNic1SubnetMask = $machine.netNic1SubnetMask
		[string]$machinenetNic1DefaultGateway = $machine.netNic1DefaultGateway
	    [string]$machinenetNic1DnsRegistrationEnabled = $machine.netNic1DnsRegistrationEnabled.ToUpper()

		if ($machinenetNic1DefaultGateway -match $regexIPAddress)
		{
			[bool]$gatewayGood = $false
			$gatewayGood = Test-SameSubnet -ip1 $machinenetNic1DefaultGateway -ip2 $machinenetNic1IpAddress  -SubnetMask $machinenetNic1SubnetMask
			
			if ($gatewayGood -eq $true)
		    {
		        writeToLogFile $logfile "$machinewinHostname netNic1DefaultGateway: $machinenetNic1DefaultGateway and netNic1IpAddress: $machinenetNic1IpAddress are in the same subnet.)" -ForegroundColor Green
		    }
		    else
		    {
		        writeToLogFile $logfile "$machinewinHostname netNic1DefaultGateway: $machinenetNic1DefaultGateway and netNic1IpAddress: $machinenetNic1IpAddress are NOT in the same subnet.)" -ForegroundColor Red
		    }
				
		}
	}	
	
	Write-host "Press any key to continue"
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

	Clear-Host
	
	writeToLogFile $logfile ""
	writeToLogFile $logfile "===================================================================="
	writeToLogFile $logfile " Checking winHostname is using the correct case in the manifest"
	writeToLogFile $logfile ""
	
	foreach ($machine in $machines)
	{
	    [string]$machineName = $machine.winHostname
	    
	    foreach ($key in $machine.keys)
	    {
	        if ($key -eq "winHostname")
	        {
	            if (!($key -clike "winHostname"))
	            {
	                [string]$keyname = $key
					writeToLogFile $logfile "Case is not correct for $keyname ($machineName)" -ForegroundColor Red
	                writeToLogFile $logfile "Variable name should be winHostname (only the H should be capitalized)." -ForegroundColor Red
					[bool]$foundErrorNameCase = $true
	            }
	        }
	    }
	}

	if ($foundErrorNameCase -eq $false){writeToLogFile $logfile "	No errors found" -ForegrounColor Green}

	Write-host "Press any key to continue"
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Clear-Host
	
	<#
    #############################
	#check manifest against the reference architecture table
	$result = YesNoExit -message "Would you like to check against the reference architecture?" -default "yes"
	
	switch ($result)
    {
        0 {

		  } #yes
		  
        1 {. $parentMenu} #no
        2 {. $parentMenu} #exit
    }
	
	#select the refarch table file
	$refarchTablePath = Select-Tool -Label "RefarchTable" -path "$refarchTablePath" -parentMenu $parentMenu -filter "CSV Files (*.CSV)|*.CSV"
	
	#sanitized the table path in the pervious function using select-tool
	$refarchTable = Import-Csv $refarchTablePath
	
	if (!($refarchTable))
	{
		writeToLogFile $logfile "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		writeToLogFile $logfile "RefarchTable is empty!"
		writeToLogFile $logfile "$refarchtablepath"
		
		Write-host "Press any key to continue"
		$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

		. $parentMenu
	}

	
	#Present the count of reference architecture roles
	writeToLogFile $logfile ""
	writeToLogFile $logfile "===================================================================="
	writeToLogFile $logfile " Checking to see which reference architecture roles are present and missing"
	writeToLogFile $logfile ""
	

	
	#$refarchTable = buildRefarchTable

	$refarchRows = $refarchTable.Rows.Count
	writeToLogFile $logfile "There are $refarchRows unique machine types defined in the reference architecture library."

	$machineTypeHashCount = @{}

	foreach ($refarch in $refarchTable.Rows)
	{
	    [string]$refarchMachinetype = $refarch.machineType
	    [int]$machineTypeCount = 0
	    
	    Foreach ($machine in $machines)
	    {
	        [string]$machineMachinetype = $machine.machinetype

	        if ($machineMachinetype -eq $refarchMachinetype)
	        {
	            $machineTypeCount++
	        }
	    }

	    $machineTypeHashCount.Add("$refarchmachineType", "$machineTypeCount")
	}

	$machineTypeHashCount

	writeToLogFile $logfile "If your machine count is zero for a role, the machinetype is either incorrect in the manifest, or the machine is not present in the manifest"

	Write-host "Press any key to continue"
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	
	Clear-Host

	#check for correct IIS settings
	writeToLogFile $logfile ""
	writeToLogFile $logfile "===================================================================="
	writeToLogFile $logfile " Checking IIS is configured correctly according to the reference architecture"
	writeToLogFile $logfile ""
	foreach ($machine in $machines)
	{
	    [string]$machineWinHostname = $machine.winHostname
	    [string]$machineMachinetype = $machine.machinetype
	    [string]$machineWinIISRequired = $machine.winIISRequired.ToUpper()

	    foreach ($refarch in $refarchTable.Rows)
	    {
	        [string]$refarchMachinetype = $refarch.machineType
	        if($refarch.winIISRequired){[string]$refarchWinIISRequired = $refarch.winIISRequired.ToUpper()}
	        
	        if ($machineMachinetype -eq $refarchMachinetype)
	        {
	            if ($machineWinIISRequired -eq $refarchWinIISRequired)
	            {
	                writeToLogFile $logfile "$machineWinHostname IIS requirement is set correctly in the manifest ($machineWinIISRequired)" -ForegroundColor Green
	            }
	            else
	            {
	                writeToLogFile $logfile "$machineWinHostname IIS requirement is NOT set correctly in the manifest" -Foregroundcolor Red
	            }
	        }
	    }
	}
	#>
	Write-host "Press any key to continue"
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

}	#function scanManifestForCommonErrors