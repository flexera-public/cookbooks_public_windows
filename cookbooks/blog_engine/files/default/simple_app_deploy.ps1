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

# Deploys all web app from zipped source to wwwroot under IIS.
$checkForExistence = "$env:CHECK_FOR_EXISTENCE" -ne "false"
$sevenZipExePath = $env:SEVEN_ZIP_EXE_PATH
$webAppZipDirPath = $env:WEB_APP_ZIP_DIR_PATH

# check inputs.
if ("$webAppZipDirPath" -eq "")
{
    Write-Error "The WEB_APP_ZIP_DIR_PATH environment variable was not set"
    exit 100
}
if (("$sevenZipExePath" -eq "") -or !(test-path $sevenZipExePath))
{
    Write-Error "The SEVEN_ZIP_EXE_PATH environment variable was not set or is invalid."
    exit 101
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
$webConfigFileName = "web.config"
if ($checkForExistence -and (test-path (join-path $wwwRootDirPath $webConfigFileName)))
{
    $doInstall = $false
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
        exit 102
    }

    # iterate webapp files unzipping each to the wwwroot location. if there are
    # multiple .zip files, they must not have colliding file names (i.e. we cannot
    # deploy multiple web apps to the wwwroot directory, but different pieces
    # of the same web app can be deployed from multiple .zip files).
    foreach ($webAppZipFile in $zipFilesToExtract)
    {
        $webAppZipFilePath = $webAppZipFile.FullName
        Write-Verbose "Unzipping ""$webAppZipFilePath"" to ""$wwwRootDirPath"""

        # use bundled 7-zip for simplicity; if multiple recipes depend on 7-zip
        # then it should be installed by recipe.
        Write-Verbose """$sevenZipExePath"" x ""$webAppZipFilePath"" ""-o$wwwRootDirPath"" -r"
        & "$sevenZipExePath" x "$webAppZipFilePath" "-o$wwwRootDirPath" -r | Out-Null
        if ($LastExitCode -ne 0)
        {
            Write-Error "Unzip failed."
            exit 103
        }

        # verify config file exists.
        $webConfigDstFile = Join-path $wwwRootDirPath $webConfigFileName | Get-Item -ea SilentlyContinue
        if ("$webConfigDstFile" -eq "")
        {
            Write-Error "Failed to deploy ""$webConfigFileName"" to ""$wwwRootDirPath"""
            exit 104
        }

        # note that we currently do not modify the connection strings for web apps and
        # just assume they are pre-configured for the instance's server name, etc.
    }
}
else
{
    Write-Output "Web application already exists, no need to deploy."
}
