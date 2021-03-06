function mcSelectSite{
param (
    [Parameter(Mandatory=$TRUE,Position=1)][string]$customer,
	[Parameter(Mandatory=$FALSE,Position=2)][string]$mcBasePath = "D:\Deploy\ManifestCompiler"
)

	$sitesFolderPath = "$mcBasePath\Client\$customer\Sites"

	$sites = Get-ChildItem $sitesFolderPath | ?{ $_.PSIsContainer } | Select-Object Name

	[int]$listNumber = 0
	
	$listArray = @()
	
	

	foreach ($site in $sites)
	{
		$listHash = @{}
		$listNumber++
		$siteName = $site.Name
		$listHash.Add("$listNumber","$siteName")	

		$listArray += $listHash
	}

	Write-Host "Please select a manifest compiler site:"
	foreach ($item in $listArray)
	{


		$listName = $item.Property
		$listValue = $item.value
		write-host "  $listName. $listValue"
		#Write-Host $item


	}
	
	$selectedSite = Read-Host "Pick a site for $customer"
	
	foreach ($item in $listHash)
	{

		$listName = $item.Name
		$listValue = $item.value
		
		if ($selectedSite -eq $listName){$compilerSite = $listValue}
		
		write-host "  $sitesFolderPath\$compilerSite"

	}

}

mcSelectSite "SolutionsLab"




function manifestCompilerSubMenu($parentMenu){
do{
		clear-host
	    write-host ""
	    write-host "=====================================================================" -foregroundcolor $menuBannerColor
	    write-host "    Manifest Compiler Menu  (will be cut for final build)                               " -foregroundcolor $menuBannerColor
	    write-host "=====================================================================" -foregroundcolor $menuBannerColor
	    write-host ""
	    write-host "    1. Compile a manifest"
	    Write-host "    2. Create a new Customer" 
	    Write-host "    3. Create a new Site under a Customer"
		Write-host "    4. Open an explorer window for a Site"
		Write-host "    0. Return to the Main Menu"
	    write-host ""
	
    	$local:menuChoice = read-host "Please enter an option and press Enter"  
	    [string]$thisFunction = $MyInvocation.MyCommand

		$ok = $menuChoice -match '^[1234]$'
	
	}until($ok)

    Switch($menuChoice)
    {
        1{CompileManifest $thisFunction}

		2{$thisFunction}
		
		3{$thisFunction}
		
		0{mainMenu}
    }

}