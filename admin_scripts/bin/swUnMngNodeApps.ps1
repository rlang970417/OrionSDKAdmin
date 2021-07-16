<#
    Script : swUnMngNodeApps.ps1
	USAGE : ${SCRIPT} "Raleigh" "..\dat\srvList.csv"
	ARGS: This Script, Data Center, Server List
	API Usage : https://solarwinds.github.io/OrionSDK/schema/
	DESC : This script will put all assigned node applications from a CSV supplied list into an indefinite Un-Managed state state within SolarWinds Orion
	
	NOTE : Invoke-SwisVerb : Verb Orion.APM.Application.Unmanage requires 4 parameters not less
#>
param 
(
    [Parameter(Mandatory=$true)][string]$swEnv,
	[Parameter(Mandatory=$true)][string]$myNodeList
)
# Import required modules
Import-Module SwisPowerShell

# Encrypted user password. User is set in the following switch statement "admusr2".
$admPass = ConvertTo-SecureString 'F@k3P@55' -AsPlainText -Force

# Set the SolarWinds Orion server environment
switch ($swEnv) 
{
    "Raleigh"  
    {
         $admCred = New-Object System.Management.Automation.PSCredential ('admusr2', $admPass)
         $swHost = 'MSSRV0850.rdu.example.com'
    }
    "Dallas"
    {
        $admCred = New-Object System.Management.Automation.PSCredential ('admusr2', $admPass)
        $swHost = 'MSSRV0725.dfw.example.com'
    }
    "Denver"
    {
        $admCred = New-Object System.Management.Automation.PSCredential ('admusr2', $admPass)
        $swHost = 'MSSRV0490.den.example.com'
    }
    "Portland"
    {
        $admCred = New-Object System.Management.Automation.PSCredential ('admusr2', $admPass)
        $swHost = 'MSSRV0535.pdx.example.com'
    }
    default
    {
        $admCred = New-Object System.Management.Automation.PSCredential ('admusr2', $admPass)
        $swHost = 'MSSRV0850.rdu.example.com'
    }
}


<#
1) Create connection string with 'swConn'
2) Import CSV file with list of servers. Fourth argument with variable name of $myNodeList
3) For every server listed in CSV file
	* Query DB using SWQL with server IP and assign all ID's for assigned apps to object $swIdObj
	* Build an array of strings and append `AA:` for each ID
	* Invoke-SwisVerb on each object in the array to perform the desired function (e.g.: Unmanage, Remanage) 
	* Schedule with UnmanageFrom and UnmanageUntil argurments
#>
$swConn = Connect-Swis -Hostname $swHost -Credential $admCred
$myCSV = Import-Csv $myNodeList -Header @("Node","IP")

ForEach ($line in $myCSV) 
{
    $curNode = $line.IP
    $swIdObj = Get-SwisData -SwisConnection $swConn "SELECT id FROM Orion.APM.Application WHERE NodeID IN (SELECT NodeID FROM Orion.Nodes WHERE IPAddress = '$curNode')"
	$netObjectId = @( $swIdObj |% {[string]"AA:"+"$_"} )
	# C-Style for loop was need to avoid data type conversion errors from array to string arguments
    for ($i = 0; $i -lt $netObjectId.Count ; $i++) 
    {
		<#  unmanage all apps on node - start time and end time as arguments   #>
        Invoke-SwisVerb -SwisConnection $swConn -EntityName Orion.APM.Application -Verb Unmanage -Arguments @( 
            $netObjectId[$i], [DateTime]::UtcNow, [DateTime]::UtcNow.AddDays(3650), "false" )  | Out-Null
    }
}
