<#
    Script : swUnMuteAllNodeApps.ps1
	USAGE : ${SCRIPT} "Raleigh" "..\dat\srvList.csv"
	ARGS: This Script, Data Center, Server List
	API Usage : https://solarwinds.github.io/OrionSDK/schema/
	DESC : This script will resume all alerting for node applications from a CSV supplied list within SolarWinds Orion
#>
param (
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
2) Import CSV file with list of servers. Last "param" with variable name of $myNodeList
3) For every server listed in CSV file
	* Query DB using SWQL to set Uri with server IP and assign to object $Nodes
	* Update the object in the DB 'AlertSuppression'. Resume alerting.
#>
$swConn = Connect-Swis -Hostname $swHost -Credential $admCred
$myCSV = Import-Csv $myNodeList -Header @("Node","IP")

ForEach ($line in $myCSV) 
{
    $curNode = $line.IP
    $swUriObj = Get-SwisData -SwisConnection $swConn "SELECT Uri FROM Orion.APM.Application WHERE NodeID IN (SELECT NodeID FROM Orion.Nodes WHERE IPAddress = '$curNode')"
	$entityUris = @( $swUriObj |% {[string]$_} )
    ForEach-Object { Invoke-SwisVerb -SwisConnection $swConn "Orion.AlertSuppression" -Verb ResumeAlerts -Arguments @($entityUris, [DateTime]::UtcNow ) | Out-Null }
}
