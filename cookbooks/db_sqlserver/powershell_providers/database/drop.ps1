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
