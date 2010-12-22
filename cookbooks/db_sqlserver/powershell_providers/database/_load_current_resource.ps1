# Copyright (c) 2010 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# locals.
$cookbookName = Get-NewResource cookbook_name
$resourceName = Get-NewResource resource_name
$dbName = Get-NewResource name
$nodePath = $cookbookName,$resourceName,$dbName
$serverName = Get-NewResource server_name

# initialize hash representing current state of database, if necessary.
$dbData = Get-ChefNode $nodePath
if ($dbData -eq $NULL)
{
    $dbData = @{ exists = $False }
    Set-ChefNode $nodePath -HashValue $dbData
    Write-Verbose "Initialized ""$nodePath"""
}
else
{
    Write-Warning "Skipping initialization of ""$nodePath"""
    exit 0
}

# connect to server.
$server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $serverName

# query for database by name to get current resource details.
$Error.Clear()
$db = $server.Databases | where { $_.name -eq $dbName }
if ($Error.count -ne 0)
{
    Write-Error "Failed to connect to ""$serverName"""
    exit 100
}
if ($db)
{
    # set "exists".
    Set-ChefNode ($nodePath + "exists") $True

    # get the list of backup files applied to this server
    $command = "SELECT [bmf].[physical_device_name] AS restore_file_path
        FROM msdb..restorehistory rs
                  INNER JOIN msdb..backupset bs ON [rs].[backup_set_id] = [bs].[backup_set_id]
                  INNER JOIN msdb..backupmediafamily bmf ON [bs].[media_set_id] = [bmf].[media_set_id]
                WHERE rs.destination_database_name = '{0}'" -f $dbName

    $resultSet = $server.ConnectionContext.ExecuteWithResults($command)

    # build a hash of already-restored .bak file paths (for idempotency checks,
    # etc.) using the file name as the key and the full path as value.
    $restoreFilePaths = @{}
    foreach ($table in $resultSet.Tables)
    {
        foreach ($row in $table.Rows)
        {
            $restoreFilePath = $row.Item("restore_file_path")
            if ("$restoreFilePath" -ne "")
            {
                $restoreFileName = Split-Path -leaf $restoreFilePath
                if ("$restoreFileName" -ne "")
                {
                    # hashes in powershell have case-insensitive keys, but the
                    # equivalent hash in the Chef node will be case-sensitive so
                    # use a lowercase key to make it possible to query the value
                    # directly from the Chef node.
                    $restoreFilePaths.($restoreFileName.ToLower()) = $restoreFilePath
                }
            }
        }
    }
    Set-ChefNode ($nodePath + "restore_file_paths") -HashValue $restoreFilePaths
}
