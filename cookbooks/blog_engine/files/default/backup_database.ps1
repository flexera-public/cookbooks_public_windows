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

#
# Backs up all non-system SQL Server databases to a backup directory.
#

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

# force creation of backup directory or ignore if already exists.
if (!(Test-Path $backupDirPath))
{
    md $backupDirPath | Out-Null
}
$backupDir     = Get-Item $backupDirPath -ea Stop
$backupDirPath = $backupDir.FullName
Write-Verbose "Using backup directory ""$backupDirPath"""

# load SQL Server assemblies
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") | Out-Null

# connect to server.
$server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $serverName

# rename existing .bak to .old after deleting existing .old files.
# TODO: cleanup old backup files by some algorithm (allow 3 per database, older than 1 week, etc.)
foreach ($oldBackupFile in $backupDir.GetFiles("*.old")) { del $oldBackupFile.FullName }
foreach ($backupFile in $backupDir.GetFiles("*.bak")) { ren $backupFile.FullName ($backupFile.Name + ".old") }

# iterate user databases (ignoring system databases) and backup any found.
foreach ($db in $server.Databases | where { !$_.IsSystemObject } )
{
    $dbName         = $db.Name
    $timestamp      = Get-Date -format yyyyMMddHHmmss
    $backupFilePath = $backupDirPath + "\" + $dbName + "_" + $timestamp + ".bak"

    $backup                      = New-Object ("Microsoft.SqlServer.Management.Smo.Backup")
    $backup.Action               = "Database" # full databse backup. TODO: also backup the transaction log.
    $backup.BackupSetDescription = "Full backup of $dbName"
    $backup.BackupSetName        = "$dbName backup"
    $backup.Database             = $dbName
    $backup.MediaDescription     = "Disk"
    $backup.LogTruncation        = "Truncate"
    $backup.Devices.AddDevice($backupFilePath, "File")

    $Error.Clear()
    $backup.SqlBackup($server)
    if ($Error.Count -eq 0)
    {
        "Backed up database named ""$dbName"" to ""$backupFilePath"""
    }
    else
    {
        # report error but keep trying to backup additional databases.
        Write-Error "Failed to backup ""$dbName"""
        Write-Warning "SQL Server fails to backup/restore to/from network drives but will accept the equivalent UNC path so long as the database user has sufficient network privileges. Ensure that the SQL_BACKUP_DIR_PATH environment variable does not refer to a shared drive."
    }
}
