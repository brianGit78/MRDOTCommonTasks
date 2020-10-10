

#############################################################
#   Utility Functions
#
#############################################################


#########
#check for local instances of products and then load their modules

function checkForSccmLocal{

    $sccmInstalled = Get-Service -name SMS_EXECUTIVE -ErrorAction SilentlyContinue

    if ($sccmInstalled){Return $true}

    Return $false;


}


function checkForMediaroomLocal{

    $mediaroomConfigEngine = "C:\Program Files\Microsoft IPTV Services\bin\ComPlus\configuration.dll"

    if (test-path $mediaroomConfigEngine)
    {	
        $null = [System.Reflection.Assembly]::LoadFrom("$mediaroomConfigEngine");
        $global:configEngine = New-Object Microsoft.TV2.Server.Common.Configuration.InstalledEngine;
	    $mrName = $global:configEngine.GetCurrentPublicName()
		$branchName = $global:configEngine.GetCurrentBranchName();

        Return $true	
    }
	else {Return $false}


}

function checkForScvmm2008R2Local{

	#Check if Virtual Machine Manager Cmdlts vmm 2008 R2 snapin is installed	
    [string]$vmm2008R2PSModule = "C:\Program Files\Microsoft System Center Virtual Machine Manager 2008 R2\bin\virtualmachinemanager.types.ps1xml"
	if(test-path $vmm2008R2PSModule){Return $true}

    Return $false;
}


function checkForScvmm2012R2Local{

	#Check if Virtual Machine Manager Cmdlts are installed
	[string]$vmm2012R2PSModule = "C:\Program Files\Microsoft System Center 2012 R2\Virtual Machine Manager\bin\psModules\virtualmachinemanager\virtualmachinemanager.psd1"
	if (test-path $vmm2012R2PSModule){Return $true}
    
    Return $false;
}


#defaults for environment, kinda buggy
function viewMenuDefaults
{
    clear-host
	write-host "====================================================================="
    write-host "Default Values"
    write-host "====================================================================="
    write-host "To edit these values, open up the script file" -nonewline
    write-host " $thisScript " -foregroundcolor $defaultsTextColor -nonewline
    write-host "in notepad and change the values at the begining of the file."
    write-host ""        
    write-host "Items that are " -NoNewline
	write-host "Red " -ForegroundColor Red -NoNewline
	write-host "are not found"
	write-host "====================================================================="
	write-host ""  
	
	
	Write-Host "Menu Version		       " $menuVersion.ToString()
	if (!(test-path $librariesPath)){$statusColor = "Red"}else {$statusColor = "Green"}
    write-host "Path to Libraries:" -nonewline
    write-host "		$librariesPath" -foregroundcolor $statusColor
	
	getControllerPrereqs
	getVMMPrereqs
	getMRPrereqs
	
	Write-Host ".Net Framework Versions		" -NoNewline
	Foreach ($framework in $frameworkVersions){Write-Host "$framework " -nonewline}
	write-host ""
	write-host ""
	Read-host "Press Enter to return to the main menu"
}





#get all of the framework versions installed on this machine
#http://blog.smoothfriction.nl/archive/2011/01/18/powershell-detecting-installed-net-versions.aspx
function Get-Framework-Versions()
{
    function Test-Key([string]$path, [string]$key)
    {
        if(!(Test-Path $path)) { return $false }
        if ((Get-ItemProperty $path).$key -eq $null) { return $false }
        return $true
    }
    
    $installedFrameworks = @()
    if(Test-Key "HKLM:\Software\Microsoft\.NETFramework\Policy\v1.0" "3705") { $installedFrameworks += "1.0" }
    if(Test-Key "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v1.1.4322" "Install") { $installedFrameworks += "1.1" }
    if(Test-Key "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v2.0.50727" "Install") { $installedFrameworks += "2.0" }
    if(Test-Key "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v3.0\Setup" "InstallSuccess") { $installedFrameworks += "3.0" }
    if(Test-Key "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v3.5" "Install") { $installedFrameworks += "3.5" }
    if(Test-Key "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Client" "Install") { $installedFrameworks += "4.0c" }
    if(Test-Key "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Full" "Install") { $installedFrameworks += "4.0" }   
     
    return $installedFrameworks
}


function displayManifestPath
{
	#check for manifest (defined in begining of file)
	if (!(test-path $manifestPath)){$statusColor = "Red"}else{$statusColor = "Green"}
	
	#reserve for later when i think of a good concatination method to fit on the screen
	#if (($manifestPath) -and ($manifestPath.length -ge 20)){}
	
    write-host "Default Manifest:" -nonewline
    write-host "  $manifestPath" -foregroundcolor $statusColor -nonewline
    if ($statusColor -eq "Red"){write-host "  (Not Found)" -foregroundcolor gray}else{write-host ""}
}


function Get-Folder{
 param(
	[string]$Description="Select Folder",
    [string]$rootFolder="Desktop"
)
	[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
	$OpenFolderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
	
	$OpenFolderDialog.RootFolder = $rootFolder
	$OpenFolderDialog.Description = $Description
    $openFOlderDialog.ShowNewFolderButton = $true
	[void]$OpenFolderDialog.ShowDialog()

    write-host "User Selected :" $OpenFolderDialog.SelectedPath
	
    Return $OpenFolderDialog.SelectedPath

	
} #function Get-Folder, called from Select Folder (UI)





function Select-Folder{ 
 param(
    [string]$currentFolder
)
	try{
	    
        write-host ""
        write-host "Current folder to save output: " $currentFolder
		if (!(test-path $currentFolder)){$statusColor = "Red";[bool]$found=$false}else{$statusColor = "Green";[bool]$found=$true}
		
	    write-host "$rootFolder" -foregroundcolor $statusColor
	    if($found -eq $false){write-host "`(Path not found`)" -ForegroundColor Gray}
	    
	    Write-Host ""
		$message = "Do you want to select a new destination folder?"
	    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Open file dialog to select a folder"
	    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Keep current folder: $rootFolder"
	    $exit = New-Object System.Management.Automation.Host.ChoiceDescription "E&xit", "Exit this function."
		
		#if the folder is not found, force only yes (select new) or exit
	    if ($found -eq $false)
	    {
	        
	        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $exit)
	        [int]$defaultSelection = 0

	        $result = $host.ui.PromptForChoice($title, $message, $options, $defaultSelection) 
	        
	        switch ($result)
	        {
	            0 {
					$getfolderpath = Get-Folder
					if(!($getfolderpath)){. $parentMenu}else{$folder = $getfolderpath; $selected = $true}
					} #yes
	            1 {. $parentMenu} #exit
	        }

	    }
	    else #if we found the foulder  "Do you want to select a new destination folder?"
	    {
	        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
	        [int]$defaultSelection = 1

	        $result = $host.ui.PromptForChoice($title, $message, $options, $defaultSelection) 

	        switch ($result)
	        {
	            0 {
					$folder = Get-Folder
					
					#if(!($getfolderpath)){. $parentMenu}else{$folder = $getfolderpath; $selected = $true}
					} #yes
	            1 {$folder = $currentFolder} #no

			}
	    }  #if ($found -eq $false)
		
		if (!(test-path $folder)){write-host "Unable to find folder"; $folder = $mrdotRoot}
		
		Return $folder
		
	  }
	  catch{
	  	$Message = "Select-Folder " + $_.Exception.Message;
	 	Write-Host $Message;	
	  }

}


Function Get-FileName{   
 param (
    [Parameter(Mandatory=$TRUE,Position=1)]$initialDirectory,
    [Parameter(Mandatory=$FALSE,Position=2)]$filter = "All files (*.*)| *.*"
)

     [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

     $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
     $OpenFileDialog.initialDirectory = $initialDirectory

     $OpenFileDialog.filter = "$filter"
	 
     $OpenFileDialog.ShowHelp = $true
     $OpenFileDialog.ShowDialog() | Out-Null
     $OpenFileDialog.filename

     $fileName = $OpenFileDialog.FileName
     Return $fileName

} #end function Get-FileName, called from Select-Tool




function Select-Tool{
 param (
    [Parameter(Mandatory=$TRUE,Position=1)][string]$label,
    [Parameter(Mandatory=$TRUE)][string]$path,
    [Parameter(Mandatory=$FALSE)]$parentMenu,
    [Parameter(Mandatory=$FALSE)][string]$filter
)

try{
    write-host "Please select $label"
	if (!(test-path $path)){$statusColor = "Red";[bool]$found=$false}else{$statusColor = "Green";[bool]$found=$true}
	
	#reserve for later when i think of a good concatination method to fit on the screen
	#if (($path) -and ($path.length -ge 20)){}
	
    write-host "$path" -foregroundcolor $statusColor
    if($found -eq $false){write-host "`(File not found.`)" -ForegroundColor Gray}
    
    Write-Host ""
	$message = "Do you want to select a new $label ?"
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Open file dialog to select $label"
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Keep current path: $path"
    $exit = New-Object System.Management.Automation.Host.ChoiceDescription "E&xit", "Exit this function."

    #if the file is not found, force only yes (select new) or exit
    if ($found -eq $false)
    {
        
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $exit)
        [int]$defaultSelection = 0

        $result = $host.ui.PromptForChoice($title, $message, $options, $defaultSelection) 
        
        switch ($result)
        {
            0 {
				$getfilepath = Get-FileName -initialDirectory "$mrdotRoot" -filter $filter
                
                if($getfilepath.Count -gt 1){$getfilepath =$getfilepath[0]}
				if(!($getfilepath)){. $parentMenu}else{$path = $getfilepath; $selected = $true}
				
              }

            1 {. $parentMenu}
        }

    }
    else 
    {
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        [int]$defaultSelection = 1

        $result = $host.ui.PromptForChoice($title, $message, $options, $defaultSelection) 

        switch ($result)
        {
            0 {
				$getfilepath = Get-FileName -initialDirectory "$mrdotRoot" -filter $filter
                

				if(!($getfilepath))
                {
                    write-host "No file selected!!"
                    . $parentMenu
                }
                elseif ($getfilepath.Count -gt 1)
                {
                    $path = $getfilepath[0]
                    $selected = $true
                    write-host $path
                }
                else
                {
                    $path = $getfilepath 
                    $selected = $true
                    write-host $path
                }


   			  } #0

            1 {}

		}
    }  #if ($found -eq $false)


    if (!(test-path $path)){write-host "Unable to find $label"; Return}

    if (($label -eq "Manifest") -and ($selected -eq $true))
    {
        #decide to make change permanent

        $inputline = $myinvocation.line

        function makeVarPermanent($path)
        {
            updateNode $globalVariablesPath "Property[@Name='manifestPath']" "" Value "$path"
        }

        $message = "Save change?"
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Make this selection permanent."
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Make this selection temporary."
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        #unremark to enable save change
        $result = $host.ui.PromptForChoice($title, $message, $options, 0)

        switch ($result)
        {
            0 {makeVarPermanent $path}
            1 {}
        }
    } #if (($label -eq "Manifest")
	
    Return $path
	
  } #try
  catch{
  	$Message = "Select-Tool " + $_.Exception.Message;
 	Write-Host $Message;	
  }
}

function displayToolBanner($message)
{
    Clear-Host 
    write-host "=====================================================================" -foregroundcolor $menuBannerColor
    write-host "    $message                                                   " -foregroundcolor $menuBannerColor
    write-host "=====================================================================" -foregroundcolor $menuBannerColor

    write-host "Hello $ENV:USERDOMAIN\$ENV:USERNAME !" 
    write-host ""

}

function YesNoExit{
param (
	[Parameter(Mandatory=$TRUE,Position=2)]$message,
	[Parameter(Mandatory=$FALSE)][string]$defaultOption = "YES",
	[Parameter(Mandatory=$FALSE)][string]$yesText = "Continue",
	[Parameter(Mandatory=$FALSE)][string]$noText = "Skip this step",
	[Parameter(Mandatory=$FALSE)][string]$exitText = "Exit this function"
)

	switch($defaultOption.ToUpper())
	{
		"YES" {$default = 0}
		"NO" {$default = 1}
		"EXIT" {$default = 2}
	
	}

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", $yesText
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", $noText
    $exit = New-Object System.Management.Automation.Host.ChoiceDescription "E&xit", $exitText
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no, $exit)
    $result = $host.ui.PromptForChoice($title, $message, $options, $default)
	
	#Out-File -FilePath $logfile -append -InputObject $message
	
	Return $result
}


function writeToLogFile{
param (
    [Parameter(Mandatory=$TRUE,Position=1)]$logfile,
	[Parameter(Mandatory=$TRUE,Position=2)]$message,
	[Parameter(Mandatory=$FALSE)]$foregroundcolor
)
	
	if ($foregroundcolor){Write-Host $message -ForegroundColor $foregroundcolor}
	else{Write-Host $message}
	
	Out-File -FilePath $logfile -append -InputObject $message
}


function Get-Machines ($manifestPath){

    <#
    $return = YesNoExit -message "Do you want to specify a simple filter on winHostName?" -default "no"
    switch($return){

        0{  $filter = read-host "Please enter a string you would like to match with winhostname (case insensitive)."
            $machines = Get-ManifestAsHashList $manifestPath -filter $filter
         } #Yes

        1{$machines = Get-ManifestAsHashList $manifestPath} #No

        2{Return} #Exit
        }
    #>

    $machines = Get-ManifestAsHashList $manifestPath

    if(!($machines)){
        write-host "There are no machines in the collection"
       	Write-host "Press any key to continue"
    	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        . $parentMenu

    }

    Foreach($machine in $machines){$machineName = $machine.Name; Write-host "Found host $machineName"}

    Return $machines

}

function pressAnyKeyToReturn{
param (
	[Parameter(Mandatory=$FALSE,Position=1)]$parentMenu,
    [Parameter(Mandatory=$FALSE)]$message = "Press any key to continue"
    
)
            Write-host $message
        	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            if($parentMenu){. $parentMenu}
}