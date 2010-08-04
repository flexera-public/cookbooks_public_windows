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
$dbName = Get-NewResource name
$commands = Get-NewResource commands
$serverName = Get-NewResource server_name

#check inputs.
$Error.Clear()
if (($dbName -eq $Null) -or ($dbName -eq ""))
{
    Write-Error "Invalid or missing database name".
    exit 100
}
if (($commands -eq $Null) -or ($commands.Count -eq 0))
{
    Write-Error "No SQL commands provided in resource".
    exit 101
}
if (($serverName -eq $Null) -or ($serverName -eq ""))
{
    Write-Error "Invalid or missing server name".
    exit 102
}
if (0 -ne $Error.Count)
{
    exit 103
}

# client connection.
$sqlClient = new-object System.Data.SqlClient.SqlConnection "server=$serverName;database=$dbName;trusted_connection=true;"
$sqlClient.Open()
if (0 -ne $Error.Count)
{
    exit 104
}

$sqlCommand = New-Object System.Data.SQLClient.SQLCommand
$sqlCommand.Connection = $sqlClient
$result = $True
foreach ($command in $commands)
{
    Write-Verbose "Executing ""$command"""
    $sqlCommand.CommandText = $command
    $rowCount = $sqlCommand.ExecuteNonQuery()
    if ($rowCount -ge 0)
    {
        Write-Verbose "Rows affected = $rowCount"
    }
    if (0 -ne $Error.Count)
    {
        $result = $False
        break
    }
}
$sqlClient.Close()

if (!$result)
{
    exit 105
}
