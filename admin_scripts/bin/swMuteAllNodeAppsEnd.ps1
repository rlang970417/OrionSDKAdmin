<#
    Script : swMuteAllNodeAppsEnd.ps1
	USAGE : ${SCRIPT} "Raleigh" "08/29/2020 16:00" "..\dat\srvList.csv"
	ARGS: This Script, Data Center, Outage End Time, Server List
	API Usage : https://solarwinds.github.io/OrionSDK/schema/
	DESC : This script will immediately suppress all alerting for node applications from a CSV supplied list within SolarWinds Orion and make use of a supplied end time for the alert suppression.
#>
param 
(
    [Parameter(Mandatory=$true)][string]$swEnv,
    [Parameter(Mandatory=$true)][string]$endTime,
	[Parameter(Mandatory=$true)][string]$myNodeList
)
# Import required modules
Import-Module SwisPowerShell

# Time variables
$diffNowEnd=(New-TimeSpan -Start(Get-Date) -End(Get-Date $endTime)).TotalSeconds
$outageSeconds=[int]$diffNowEnd
$outageEndInMinutes=[int]($diffNowEnd/60)

# Make sure second argument is not in the past.
if ($outageSeconds -lt 0) 
{
    throw "Outage end time cannot happen in the past. Temporal Error!"
}

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
	* Update the object in the DB 'AlertSuppression'
#>
$swConn = Connect-Swis -Hostname $swHost -Credential $admCred
$myCSV = Import-Csv $myNodeList -Header @("Node","IP")

ForEach ($line in $myCSV) 
{
    $curNode = $line.IP
    $swUriObj = Get-SwisData -SwisConnection $swConn "SELECT Uri FROM Orion.APM.Application WHERE NodeID IN (SELECT NodeID FROM Orion.Nodes WHERE IPAddress = '$curNode')"
	$entityUris = @( $swUriObj |% {[string]$_} )
    ForEach-Object { Invoke-SwisVerb -SwisConnection $swConn "Orion.AlertSuppression" SuppressAlerts @($entityUris, 
	    [DateTime]::UtcNow, [DateTime]::UtcNow.AddMinutes($outageEndInMinutes)) | Out-Null}
}
