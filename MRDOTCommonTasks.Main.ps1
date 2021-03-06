[version]$menuVersion = "0.3.0.0"
[string]$thisScript = $MyInvocation.Mycommand.Path
[string]$defaultsTextColor = "Yellow"
[string]$menuBannerColor = "DarkYellow"
[string]$subMenu1HeaderColor = "Green"


####
#Menu Functions
####

function mainMenu
{
    do{        
        #initialize available items array
        $availItems = @()
        
        Clear-Host
        write-host ""
        write-host "=====================================================================" -foregroundcolor $menuBannerColor
        write-host "    Mediaroom Deployment and Operations Tool Kit                     " -foregroundcolor $menuBannerColor
        write-host "=====================================================================" -foregroundcolor $menuBannerColor
        write-host ""
        displayManifestPath
        write-host ""        
	    Write-host "    1. Manifest Tools" -ForegroundColor White; $availItems += 1
    
        if ($sccmPresent -eq $false){Write-host "    2. SCCM 2007 Tools (unavailable)" -ForegroundColor Gray}
        else {Write-host "    2. SCCM 2007 Tools" -ForegroundColor White; $availItems += 2}
        
        if ($scvmm2008R2Present -eq $false){Write-host "    3. SCVMM 2008 R2 Tools (unavailable)" -ForegroundColor Gray}
        else {Write-host "    3. SCVMM 2008 R2 Tools" -ForegroundColor White; $availItems += 3}
        
        if ($scvmm2012R2Present -eq $false){Write-host "    4. SCVMM 2012 R2 Tools (unavailable)" -ForegroundColor Gray}
        else {Write-host "    4. SCVMM 2012 R2 Tools" -ForegroundColor White; $availItems += 4}

        if ($mediaroomPresent  -eq $false){Write-host "    5. Mediaroom Tools (unavailable)" -ForegroundColor Gray}
        else {Write-host "    5. Mediaroom Tools" -ForegroundColor White; $availItems += 5}
        
        Write-host "    6. Set Default Manifest File" -ForegroundColor White; $availItems += 6
    
        #if ($mrDotToolsPresent  -eq $false){Write-host "    6. MRDOT Tools (unavailable)" -ForegroundColor Gray}
        #else {Write-host "    6. MRDOT Tools" -ForegroundColor White; $availItems += 6}

        #Write-host "    . Windows Tools"  -ForegroundColor White
	    #Write-host "    . Azuki Deployment Tools"
        #write-host "    . System information and default values"
	    Write-host "    0. Quit" -ForegroundColor White; $availItems += 0
        write-host ""
        
        #convert to regex
        [string]$regexMatch ="^[" + "$availItems".Replace(" ","") + "]$"

	    $local:menuChoice = read-host "Please enter an option and press Enter"  
	    [string]$thisFunction = $MyInvocation.MyCommand

		$ok = $menuChoice -match $regexMatch
	
	}until($ok)
	
    Switch ($menuChoice){
        
        1{manifestToolsMenu; Break}
		
		2{sccmToolsMenu; Break}
		
        3{vmm2008ToolsMenu; Break}
		
		4{vmm2012R2ToolsMenu; Break}
        
        5{mediaroomServerToolsMenu; Break}
        
        6{$manifestPath = Select-Tool -Label "Manifest" -path $manifestPath -parentMenu $parentMenu -filter "XML Files (*.XML)|*.XML"; Break}

        0{clear-host; Exit 0}
    }
}



function Load-LibraryFile{
param (
    [Parameter(Mandatory=$TRUE,Position=1)]$lib
)
	#handle MRDOT override in library file
	if ($mrdotRoot){$global:dotRootPerm = $mrdotRoot.Clone()}

	if (!(Test-Path $lib))
	{
		write-host "Unable to find library $lib"
		write-host "Press any key to exit."			
	    $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		Exit 1
	}
	else
	{
		write-host "Initializing Library $lib"
		. $lib
	}
	
	#handle MRDOT override in library file
	if($mrdotRootPerm){$mrdotRoot = $mrdotRootPerm}
}


function Load-GlobalVarsFile{
param (
    [Parameter(Mandatory=$TRUE,Position=1)]$globalvarsfile,
    [Parameter(Mandatory=$FALSE,Position=2)]$mrdotRoot
)

	if(!(test-path $globalvarsfile)){Write-host "Unable to find file."; Return}
    [xml]$xmlManifest = get-content $globalvarsfile

    #find $mrdotRoot first (fix problem with xml variable expansions)
    
    foreach ($site in $xmlManifest.GlobalValuesManifest.Site)
    {
	    #set the actual variables
	    foreach ($property in $site.property)
	    {  
            [string]$propertyName = $property.name
            if ($propertyName -eq "mrdotRoot")
            {
                [string]$propertyValue = $property.value
                Write-Host "	Name: $propertyName		Value: $propertyValue" -ForegroundColor Yellow
		        Set-Variable -Name $propertyName -Value "$propertyValue" -scope Global 
                #-option ReadOnly -Force
                Break
            }
        }
    }
    

    #add the rest of the values
	foreach ($site in $xmlManifest.GlobalValuesManifest.Site)
	{
	    write-host "Setting Variables for this session"

	    #set the actual variables
	    foreach ($property in $site.property)
	    {  
            [string]$propertyName = $property.name
            #if ($propertyName -eq "mrdotRoot"){Continue}
           
            
			[string]$propertyValue = $property.value
            $propertyValue = $ExecutionContext.InvokeCommand.ExpandString("$propertyValue") 

			Write-Host "	Name: $propertyName		Value: $propertyValue" -ForegroundColor Yellow
		    Set-Variable -Name $propertyName -Value "$propertyValue" -scope Global
	    }				
	}
}


############################################
############################################
##         script entry point
Write-Host "Loading MRDOT Menu..."

#set the menu version
$Host.UI.RawUI.WindowTitle = "MRDOT Menu $menuVersion"

#find our local execution path
[string]$localPath = Split-Path -parent $MyInvocation.MyCommand.Definition;

#currently disabled below
function checkForElevation{
    # Get the ID and security principal of the current user account
     $myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
     $myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
  
     # Get the security principal for the Administrator role
     $adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
  
     # Check to see if we are currently running "as Administrator"
    if (!($myWindowsPrincipal.IsInRole($adminRole)))
    {
        # We are not running as Administrator
        write-host "You are not running as Administrator."
        Write-host "Asking for permission to elevate..."
        
        #Write-host "Press any key to continue"
	    #$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        # Create a new process object that starts PowerShell
        $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
    
        # Specify the current script path and name as a parameter
        $newProc = $localPath + "\MRDOTCommonTasks.cmd"
        #$newProcess.Arguments = $myInvocation.MyCommand.Definition;
        $newProcess.Arguments = $newProc
    
        # Indicate that the process should be elevated
        $newProcess.Verb = "runas";
    
        # Start the new process
        [System.Diagnostics.Process]::Start($newProcess);
    
        # Exit from the current, unelevated, process
        exit
     }
}

checkForElevation


###
#load the config file parameters
$globalVariablesPath = "$localPath\MRDOTCommonTasks.xml"
write-host $globalVariablesPath
if(!(test-path $globalVariablesPath))
{
	write-host "Variables file does not exist."
	write-host "   $globalVariablesPath"
	Write-Host "Press any key to continue ..."
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Exit 1
}
Load-GlobalVarsFile "$globalVariablesPath" $mrdotRoot
#should allow to create a sample file instead of stopping


####################
#Setup the base libraries

if (!(test-path $mrdotRoot))
{
	write-host "Unable to find $mrdotRoot"
	Write-Host "Press any key to continue ..."
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Exit 1
}

#Include Libraries

# load the base mrdot libraries, the remainder will be opened under their module if found (ex SCVMM)
. Load-LibraryFile "$librariesPath\MRDOT.Common.ps1"
. Load-LibraryFile "$librariesPath\MRDOT.Manifest.ps1"
. Load-LibraryFile "$librariesPath\MRDOT.XML.ps1"

# load menu libraries
. Load-LibraryFile "$localPath\MRDOTCommonTasks.Libraries.ps1"
. Load-LibraryFile "$localPath\MRDOTCommonTasks.Manifest.ps1"
. Load-LibraryFile "$localPath\MRDOTCommonTasks.ScanManifest.ps1"


#determine the platform we're running on
$hostOS = Get-WmiObject -class Win32_OperatingSystem

$frameworkVersions = Get-Framework-Versions

#calls to library
[bool]$mediaroomPresent = checkForMediaroomLocal
if ($mediaroomPresent -eq $true){
    . Load-LibraryFile "$localPath\MRDOTCommonTasks.Mediaroom.ps1"
    . Load-LibraryFile "$librariesPath\MRDOT.Mediaroom.ps1"}

[bool]$sccmPresent = checkForSccmLocal
if ($sccmPresent -eq $true){
    . Load-LibraryFile "$localPath\MRDOTCommonTasks.ConfigMgr.ps1"
    . Load-LibraryFile "$librariesPath\MRDOT.ConfigMgr.2007.ps1"}
    
[bool]$scvmm2008R2Present = checkForScvmm2008R2Local
if ($scvmm2008R2Present -eq $true){
    . Load-LibraryFile "$localPath\MRDOTCommonTasks.Virtualization.2008.ps1"
    . Load-LibraryFile "$librariesPath\MRDOT.Virtualization.2008.ps1"}

[bool]$scvmm2012R2Present = checkForScvmm2012R2Local
if ($scvmm2012R2Present -eq $true){
    . Load-LibraryFile "$localPath\MRDOTCommonTasks.Virtualization.2012.ps1"
    . Load-LibraryFile "$librariesPath\MRDOT.Virtualization.2012.ps1"}

$pshost = get-host
$pswindow = $pshost.ui.rawui

$newsize = $pswindow.buffersize
$newsize.height = 3000
$newsize.width = 100
$pswindow.buffersize = $newsize

$newsize = $pswindow.windowsize
$newsize.height = 30
$newsize.width = 100
$pswindow.windowsize = $newsize

$pswindow.BackgroundColor = "DarkBlue"
$pswindow.ForegroundColor = "Gray"

do {mainMenu} while ($menuChoice -ne 6)

