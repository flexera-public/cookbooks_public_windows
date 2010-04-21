# Backs up all non-system SQL Server databases to a backup directory.
#
# Copyright 2009, RightScale, Inc.
#
# All rights reserved - Do Not Redistribute

# check inputs
$serverName = $env:SQL_SERVER_NAME
if ("$serverName" -eq "")
{
    Write-Error "The SQL_SERVER_NAME environment variable was not set"
    exit 1
}

$databaseName = $env:DATABASE_NAME
if ("$databaseName" -eq "")
{
    Write-Error "The DATABASE_NAME environment variable was not set"
    exit 1
}

"server name = ""$serverName"" database name = ""$databaseName""  "

# load SQL Server assemblies
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") | Out-Null

# connect to server.
$server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $serverName

# iterate user databases (ignoring system databases) and drop any found.
foreach ($db in $server.Databases | where { (!$_.IsSystemObject_) -and ($_.Name -eq $databaseName) } )
{
    $dbName = $db.Name

    $Error.Clear()
    $db.Drop()
    if ($Error.Count -eq 0)
    {
        "Dropped database named ""$dbName"""
        exit 0
    }
    else
    {
        # report error but keep trying to drop additional databases.
        Write-Error 'Failed to drop ""$dbName.ToString()"" because ""$Error.ToString()""'
        exit 1
    }
}
