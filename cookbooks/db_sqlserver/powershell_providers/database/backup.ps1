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
$existingBackupFileNamePattern = (Get-NewResource existing_backup_file_name_pattern) -f $dbName
$maxoldbackups = (Get-NewResource max_old_backups_to_keep)
$backupFileNameFormat = Get-NewResource backup_file_name_format
$zipBackup = Get-NewResource zip_backup
$deleteSqlAfterZip = Get-NewResource delete_sql_after_zip
$statementTimeoutSeconds = Get-NewResource statement_timeout_seconds

#check inputs.
$Error.Clear()
if (($maxoldbackups -eq $NULL) -or ($maxoldbackups -eq "") -or (!$maxoldbackups -match "^\d+$"))
{
    Write-Error "Error: 'max_old_backups_to_keep' is a required numeric attribute for the 'backup' provider. Aborting..."
    exit 140
}

# check if database exists before backing up.
if (!(Get-ChefNode ($nodePath + "exists")))
{
    Write-Warning "Not backing up ""$dbName"" because it does not exist."
    exit 141
}

# connect to server.
$server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $serverName

# default StatementTimeout to int32 max if undefined
if (($statementTimeoutSeconds -eq $NULL) -or ($statementTimeoutSeconds -eq ""))
{
    $statementTimeoutSeconds = [System.Int32]::MaxValue
}
$server.Connectioncontext.StatementTimeout = $statementTimeoutSeconds

# force creation of backup directory or ignore if already exists.
if (!(Test-Path $backupDirPath))
{
    md $backupDirPath | Out-Null
}
$backupDir     = Get-Item $backupDirPath -ea Stop
$backupDirPath = $backupDir.FullName
Write-Output "Using backup directory ""$backupDirPath"""

$backupDir     = Get-Item $backupDirPath -ea Stop

# rename existing .bak to .old after deleting existing .old files.
foreach ($backupFile in $backupDir.GetFiles($existingBackupFileNamePattern)) { ren $backupFile.FullName ($backupFile.Name + ".old") }

$oldcount=$backupDir.GetFiles($existingBackupFileNamePattern+".old").count
# TODO: cleanup old backup files by some algorithm (allow 3 per database, older than 1 week, etc.)
if ($oldcount -gt $maxoldbackups)
{
    $deletecount=$oldcount-$maxoldbackups
    write-output "***Deleting [$deletecount] old backup(s):"
    foreach ($oldBackupFile in $backupDir.GetFiles($existingBackupFileNamePattern+".old") | Select-Object -first $deletecount)
    {
        write-output "   ***Deleting old backup: $oldBackupFile"
        del $oldBackupFile.FullName
    }
}

if ($zipBackup -eq "true")
{
    #get count and substract one(latest zip backup)
    $oldcount=$backupDir.GetFiles($existingBackupFileNamePattern+".zip").count-1
    # TODO: cleanup old zipped backup files by some algorithm (allow 3 per database, older than 1 week, etc.)
    if ($oldcount -gt $maxoldbackups)
    {
        $deletecount=$oldcount-$maxoldbackups
        write-output "Deleting [$deletecount] old zipped backups"
        foreach ($oldBackupFile in $backupDir.GetFiles($existingBackupFileNamePattern+".zip") | Select-Object -first $deletecount)
        {
            write-output "Deleting $oldBackupFile"
            del $oldBackupFile.FullName
        }
    }
}


# iterate user databases (ignoring system databases) and backup any found.
$db = $server.Databases | where { !$_.IsSystemObject_ -and ($_.Name -eq $dbName) }
if ($db)
{
    $dbName         = $db.Name
    $timestamp      = Get-Date -format yyyyMMddHHmmss
    $backupFileName = $backupFileNameFormat -f $dbName, $timestamp
    $backupFilePath = Join-Path $backupDirPath $backupFileName

    $backup                      = New-Object ("Microsoft.SqlServer.Management.Smo.Backup")
    $backup.Action               = "Database"  # full database backup. TODO: also backup the transaction log.
    $backup.BackupSetDescription = "Full backup of $dbName"
    $backup.BackupSetName        = "$dbName backup"
    $backup.Database             = $dbName
    $backup.MediaDescription     = "Disk"
    $backup.LogTruncation        = "Truncate"
    $backup.Devices.AddDevice($backupFilePath, "File")

    $Error.Clear()

    function Resolve-Error ($ErrorRecord=$Error[0])
    {
        $ErrorRecord | Format-List * -Force
        $ErrorRecord.InvocationInfo |Format-List *
        $Exception = $ErrorRecord.Exception
        for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
        {
            "$i" * 80
            $Exception |Format-List * -Force
        }
    }

    try
    {
        $backup.SqlBackup($server)
    }
    catch [System.Exception]
    {
        Resolve-Error
        Write-Error "Failed to backup ""$dbName"""
        exit 105
    }

    if ($Error.Count -eq 0)
    {
        Write-Output "Backed up database named ""$dbName"" to ""$backupFilePath"""
        if ($zipBackup -eq "true")
        {
            Write-Output "Zipping the backup"
            $output=invoke-expression 'cmd /c 7z a -tzip "$backupFilePath.zip" $backupFilePath'
            Write-Output $output
            if ($output -match "Everything is Ok")
            {
                if ($deleteSqlAfterZip -eq "true")
                {
                    Write-Output "Deleting the bak file"
                    Remove-Item $backupFilePath
                }
                Set-ChefNode backupfilename $backupFileName".zip"
            }
        }
        else
        {
            Set-ChefNode backupfilename $backupFileName
        }
    }
    else
    {
        # report error but keep trying to backup additional databases.
        Write-Error "Failed to backup ""$dbName"""
        Write-Warning "SQL Server fails to backup/restore to/from network drives but will accept the equivalent UNC path so long as the database user has sufficient network privileges. Ensure that the SQL_BACKUP_DIR_PATH environment variable does not refer to a shared drive."
    }
}
