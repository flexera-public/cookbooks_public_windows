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

# check inputs
$backupDirPath = $env:SQL_BACKUP_DIR_PATH
if ("$backupDirPath" -eq "")
{
    Write-Error "The SQL_BACKUP_DIR_PATH environment variable was not set"
    exit 1
}
$serverName = $env:SQL_SERVER_NAME
if ("$serverName" -eq "")
{
    Write-Error "The SQL_SERVER_NAME environment variable was not set"
    exit 1
}

$checkForRestore = $env:CHECK_FOR_RESTORE
if (("$checkForRestore" -eq "") -or ("$checkForRestore" -eq "false"))
{
    $checkForRestore = $false
}
else
{
    $checkForRestore = $true
}

# load SQL Server assemblies
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") | Out-Null

# connect to server.
$server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $serverName

# require existing backup directory.
$backupDir     = Get-Item $backupDirPath -ea Stop
$backupDirPath = $backupDir.FullName

# check if already restored, if checking...
$doRestore = $true
if ($checkForRestore -eq $true)
{
    # Get the list of backup files applied to this server
    $command = "SELECT [bmf].[physical_device_name] AS restore_file_path
		FROM msdb..restorehistory rs 
                INNER JOIN msdb..backupset bs ON [rs].[backup_set_id] = [bs].[backup_set_id] 
                INNER JOIN msdb..backupmediafamily bmf ON [bs].[media_set_id] = [bmf].[media_set_id]"

    $resultSet = $server.ConnectionContext.ExecuteWithResults($command)

    # Check applied files to the list of backup files to apply.  If any file
    # has been applied, then assume the database has already been loaded once.
    foreach ($table in $resultSet.Tables)
    {
	foreach ($row in $table.Rows)
    	{
            $restore_file_path = $row.Item("restore_file_path")
            if ("$restore_file_path" -ne "")
            {
                $restore_file_name = Split-Path -leaf $restore_file_path
                $existing_restore = Join-path $backupDirPath $restore_file_name
                if (Test-path $existing_restore)
                {
                    Write-Output "Backup has already been applied to this database, no need to restore."
                    $doRestore = $false
                    break
                }
            }
    	}

        # break if found restore
	if ($doRestore -eq $false)
	{
            break
	}
    }
}

if ($doRestore -eq $true)
{
    Write-Verbose "Using backup directory ""$backupDirPath"""

    # iterate backup files restoring each.
    # note that there is no checking for redundant .bak files restoring the same
    # database multiple times, so use .old for older backups to avoid this.
    foreach ($backupFile in $backupDir.GetFiles("*.bak"))
    {
        $backupFilePath = $backupFile.FullName
        $backupDevice   = New-Object ("Microsoft.SqlServer.Management.Smo.BackupDeviceItem") ($backupFilePath, "File")
        $restore        = New-Object("Microsoft.SqlServer.Management.Smo.Restore")

        $restore.Devices.Add($backupDevice)
        $restore.NoRecovery      = $false
        $restore.ReplaceDatabase = $true

        $Error.Clear()
        $backupHeader = $restore.ReadBackupHeader($server)
        if ($Error.Count -ne 0)
        {
            Write-Error "Failed to read backup header from ""$backupFilePath"""
            Write-Warning "SQL Server fails to backup/restore to/from network drives but will accept the equivalent UNC path so long as the database user has sufficient network privileges. Ensure that the SQL_BACKUP_DIR_PATH environment variable does not refer to a shared drive."
            exit 2
        }

        $dbName = $backupHeader.Rows[0]["DatabaseName"]
        $restore.Database = $dbName

        # restore.
        $restore.SqlRestore($server)
        if ($Error.Count -eq 0)
        {
            "Restored database named ""$dbName"" to ""$backupFilePath"""
        }
        else
        {
            Write-Error "Failed to restore database named ""$dbName"" to ""$backupFilePath"""
            exit 3
        }
    }
}