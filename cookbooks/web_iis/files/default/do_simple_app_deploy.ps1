# Deploys all web app from zipped source to wwwroot under IIS.
#
# Copyright 2009, RightScale, Inc.
#
# All rights reserved - Do Not Redistribute

# check inputs.
$webAppZipDirPath = $env:WEB_APP_ZIP_DIR_PATH
if ("$webAppZipDirPath" -eq "")
{
    Write-Error "The WEB_APP_ZIP_DIR_PATH environment variable was not set"
    exit 100
}

$checkForExistance = $env:CHECK_FOR_EXISTANCE
if (("$checkForExistance" -eq "") -or ("$checkForExistance" -eq "false"))
{
    $checkForExistance = $false
}
else
{
    $checkForExistance = $true
}

# wwwroot is always found at the same location (at least for simple deployment).
$wwwRootDirPath = "C:\Inetpub\wwwroot"
$wwwRootDir     = Get-Item $wwwRootDirPath -ea Stop
$webAppZipDir   = Get-Item $webAppZipDirPath -ea Stop
$webAppZipDirPath = $webAppZipDir.FullName

# need a shell application COM object for unzipping
$shellApplication = New-Object -com shell.application
$zipFilesToExtract = $webAppZipDir.GetFiles("*.zip")

# check existence, if requested.
$doInstall = $true
if ($checkForExistance -eq $true)
{
    # check each .zip for web.config and compare date against installed date.
    $webConfigFileName = "web.config"
    Write-Verbose "Checking for existence of ""$webAppZipFilePath"" in ""$wwwRootDirPath"""

    foreach ($webAppZipFile in $zipFilesToExtract)
    {
        $webAppZipFilePath = $webAppZipFile.FullName
        $zipPackage        = $shellApplication.NameSpace($webAppZipFilePath)
        $items             = $zipPackage.Items()
        $webConfigSrcFile  = $items | where-object {$_.Name -eq $webConfigFileName}
        if ("$webConfigSrcFile" -ne "")
        {
            $webConfigDstFile = Join-path $wwwRootDirPath $webConfigFileName | Get-Item -ea SilentlyContinue
            $doInstall = (("$webConfigDstFile" -eq "") -or (("$webConfigDstFile" -ne "") -and ($webConfigSrcFile.ModifyDate -gt $webConfigDstFile.LastWriteTime)))
        }
    }
}

if ($doInstall -eq $true)
{
    # require existing web application directory.
    Write-Verbose "Deploying webapps from ""$webAppZipDirPath"""
    Write-Verbose "Deploying webapps to ""$wwwRootDirPath"""

    # clean out any leftover files in wwwroot (from installing IIS, etc.)
    Write-Verbose "Cleaning ""$wwwRootDirPath"" prior to deployment..."
    $Error.Clear()
    foreach ($item in (dir $wwwRootDirPath)) { Remove-Item $item.FullName -recurse }
    if ($Error.Count -ne 0)
    {
        Write-Error "Failed to clean the ""$wwwRootDirPath"" directory. Some files may still be in use."
        exit 104
    }

    # iterate webapp files unzipping each to the wwwroot location. if there are
    # multiple .zip files, they must not have colliding file names (i.e. we cannot
    # deploy multiple web apps to the wwwroot directory, but different pieces
    # of the same web app can be deployed from multiple .zip files).
    foreach ($webAppZipFile in $zipFilesToExtract)
    {
        $webAppZipFilePath = $webAppZipFile.FullName
        Write-Verbose "Unzipping ""$webAppZipFilePath"" to ""$wwwRootDirPath"""

        $zipPackage       = $shellApplication.NameSpace($webAppZipFilePath)
        $targetDir        = $shellApplication.NameSpace($wwwRootDirPath)

        # see http://msdn.microsoft.com/en-us/library/bb787866%28VS.85%29.aspx or the "Folder"
        # shell object "CopyHere" method reference for the following copy options.
        #
        # note that the Windows 2003 Server shell appears to ignore any provided options and
        # the progress dialog appears anyway. so long as there are no copy errors, this is ok.
        # if copying fails (or same named files exist), the call will hang waiting for user response.
        # we could use another free-ware command-line unzip utility for windows (7-zip, etc.), but
        # this is the only unzip utility that doesn't need to be installed (under WinXP+).
        $copyOptions = 4 +    # Do not display a progress dialog box.
                       16 +   # Respond with "Yes to All" for any dialog box that is displayed.
                       1024;  # Do not display a user interface if an error occurs.

        $targetDir.CopyHere($zipPackage.Items(), $copyOptions)

        # note that we currently do not modify the connection strings for web apps and
        # just assume they are pre-configured for the instance's server name, etc.
    }
}
else
{
    Write-Output "Web application already exists, no need to deploy."
}
