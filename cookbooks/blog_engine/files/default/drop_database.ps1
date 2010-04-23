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
$serverName = $env:SQL_SERVER_NAME
if ("$serverName" -eq "")
{
    Write-Error "The SQL_SERVER_NAME environment variable was not set"
    exit 1
}

$databaseName = $env:DATABASE_NAME
if ("$databaseName" -eq "")
{
    Write-Error "The DATABASE_NAME environment variable was not set"
    exit 1
}

"server name = ""$serverName"" database name = ""$databaseName""  "

# load SQL Server assemblies
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") | Out-Null

# connect to server.
$server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $serverName

# iterate user databases (ignoring system databases) and drop any found.
foreach ($db in $server.Databases | where { (!$_.IsSystemObject_) -and ($_.Name -eq $databaseName) } )
{
    $dbName = $db.Name

    $Error.Clear()
    $db.Drop()
    if ($Error.Count -eq 0)
    {
        "Dropped database named ""$dbName"""
        exit 0
    }
    else
    {
        # report error but keep trying to drop additional databases.
        Write-Error 'Failed to drop ""$dbName.ToString()"" because ""$Error.ToString()""'
        exit 1
    }
}
