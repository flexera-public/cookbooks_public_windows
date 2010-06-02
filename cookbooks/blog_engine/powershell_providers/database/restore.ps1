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
$backupDirPath = Get-NewResource backup_dir_path
$forceRestore = Get-NewResource force_restore
$backupFileNamePattern = (Get-NewResource existing_backup_file_name_pattern) -f $dbName

# check if database exists before restoring.
if (!$forceRestore -and (Get-ChefNode ($nodePath + "exists")))
{
    Write-Warning "Not restoring ""$dbName"" because it already exists."
    exit 0
}

# connect to server.
$server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $serverName

# require existing backup directory.
$backupDir     = Get-Item $backupDirPath -ea Stop
$backupDirPath = $backupDir.FullName
Write-Verbose "Using backup directory ""$backupDirPath"""

# select backup file for restore by first match of backup file pattern.
$backupFiles = $backupDir.GetFiles($backupFileNamePattern)

if ($backupFile = $backupFiles[0])
{
    # check restore history to see if this revision has already been applied,
    # even if the database was subsequently dropped. this is intended to support
    # script idempotency, but the behavior can be overridden by setting the
    # force_restore flag on the resource.
    $backupFilePath = $backupFile.FullName
    $backupFileName = Split-Path -leaf $backupFilePath
    if (!$forceRestore)
    {
        $restoredFilePath = Get-ChefNode ($nodePath + "restore_file_paths" + $backupFileName.ToLower())
        if ($restoredFilePath)
        {
            Write-Warning "Not restoring ""$backupFilePath"" because an equivalent database was already restored from ""$restoredFilePath""."
            exit 0
        }
    }

    $backupDevice = New-Object("Microsoft.SqlServer.Management.Smo.BackupDeviceItem") ($backupFilePath, "File")
    $restore      = New-Object("Microsoft.SqlServer.Management.Smo.Restore")

    $restore.Devices.Add($backupDevice)
    $restore.NoRecovery      = $false
    $restore.ReplaceDatabase = $true

    $Error.Clear()
    $backupHeader = $restore.ReadBackupHeader($server)
    if ($Error.Count -ne 0)
    {
        Write-Error "Failed to read backup header from ""$backupFilePath"""
        Write-Warning "SQL Server fails to backup/restore to/from network drives but will accept the equivalent UNC path so long as the database user has sufficient network privileges. Ensure that the SQL_BACKUP_DIR_PATH environment variable does not refer to a shared drive."
        exit 100
    }
    $headerDbName = $backupHeader.Rows[0]["DatabaseName"]
    if ($headerDbName -ne $dbName)
    {
        Write-Error "Name of database read from backup header ""$headerDbName"" does not match ""$dbName""".
        exit 101
    }
    $restore.Database = $headerDbName

    # restore.
    $restore.SqlRestore($server)
    if ($Error.Count -eq 0)
    {
        Write-Output "Restored database named ""$dbName"" from ""$backupFilePath"""
        Set-ChefNode ($nodePath + "exists") $True
        Set-ChefNode ($nodePath + "restore_file_paths" + $backupFileName.ToLower()) $backupFilePath
        Set-NewResource updated $True
        exit 0
    }
    else
    {
        Write-Error "Failed to restore database named ""$dbName"" from ""$backupFilePath"""
        exit 103
    }
}
else
{
    Write-Error "There was no backup file matching ""$backupFileNamePattern"" to restore."
    exit 104
}
