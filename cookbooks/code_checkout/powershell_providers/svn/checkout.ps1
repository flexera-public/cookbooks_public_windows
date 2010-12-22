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
$svnPath = Get-NewResource name
$svnUsername = Get-NewResource svn_username
$svnPassword = Get-NewResource svn_password

$forceCheckout = Get-NewResource force_checkout
$releasesPath = Get-NewResource releases_path

#check inputs.
$Error.Clear()
if (($svnPath -eq $NULL) -or ($svnPath -eq ""))
{
    Write-Error "Error: provider requires a 'name' parameter to be set! Ex: 'http://example.com/svn/trunk'"
    exit 131
}
if (($releasesPath -eq $NULL) -or ($releasesPath -eq ""))
{
    Write-Error "Error: provider requires 'root_path' parameter to be set! Ex: 'c:\\inetpub'"
    exit 132
}

if ($svnUsername -eq $NULL)
{
    $svnUsername=""
}
if ($svnPassword -eq $NULL)
{
    $svnPassword=""
}

#tell the script to "stop" or "continue" when a command fails
$ErrorActionPreference = "stop"

$releasesPath = Join-Path $releasesPath ""

if (!(Test-Path $releasesPath)) {
    Write-Output "Creating directory: $releasesPath"
    New-Item $releasesPath -type directory > $null
}

$deploy_date = $(get-date -uformat "%Y%m%d%H%M%S")
$deploy_path = Join-Path $releasesPath $deploy_date

Write-Output "Creating new releases directory [$deploy_path]"

$latest_release=Get-ChildItem $releasesPath | Sort-Object Name -descending | Select-Object Name | Select-Object -first 1
if (($latest_release -eq $null) -or ($forceCheckout -eq "true"))
{
    New-Item $deploy_path -type directory > $null
    Write-Output "SVN checkout in [$deploy_path]"
}
else
{
    $latest_release = Join-Path $releasesPath $latest_release.Name

    Write-Output "xcopy from [$latest_release] to [$deploy_path]"
   
    xcopy $latest_release $deploy_path /E /I /Q /H /K /Y

    if ($LastExitCode -eq 0)
    {
        Write-Output "SVN update in [$deploy_path]"
    }
    else
    {
        Write-Warning "xcopy failed, proceeding with a full checkout in [$deploy_path]"
        if (Test-Path $deploy_path)
        {
            Write-Output "Deleting directory [$deploy_path]"
            Remove-Item $deploy_path -r -force
        }
        Write-Output "Creating new releases directory [$deploy_path]"
        New-Item $deploy_path -type directory > $null
    } 
}

svn.cmd --quiet --non-interactive --no-auth-cache --username `"$svnUsername`" --password `"$svnPassword`" checkout $svnPath $deploy_path

if ($LastExitCode -ne 0)
{ 
    Write-Error "Error: SVN checkout failed" 
    exit 133
}
else
{
    Set-ChefNode checkoutpath $deploy_path
}
