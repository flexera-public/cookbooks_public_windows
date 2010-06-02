# locals.
$cookbookName = Get-NewResource cookbook_name
$resourceName = Get-NewResource resource_name
$dbName = Get-NewResource name
$nodePath = $cookbookName,$resourceName,$dbName
$serverName = Get-NewResource server_name

# check if database exists before restoring.
if (!(Get-ChefNode ($nodePath + "exists")))
{
    Write-Warning "Not dropping ""$dbName"" because it does not exist."
    exit 0
}

# connect to server.
$server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $serverName

# intentionally fail if asked to drop a system database.
$db = $server.Databases | where { !$_.IsSystemObject_ -and ($_.Name -eq $dbName) }
if ($db)
{
    $Error.Clear()
    $db.Drop()
    if ($Error.Count -eq 0)
    {
        Write-Output "Dropped database named ""$dbName"""
        Set-ChefNode ($nodePath + "exists") $False
        Set-NewResource updated $True
        exit 0
    }
    else
    {
        Write-Error 'Failed to drop ""$dbName.ToString()"" because ""$Error.ToString()""'
        exit 100
    }
}
else
{
    Write-Error "Failed to find a non-system database named ""$dbName"""
    exit 101
}
