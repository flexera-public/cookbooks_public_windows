# Cookbook Name:: db_sqlserver
# Recipe:: restart_sql_service
#
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

# enable the SQL service
powershell "Restart the MSSQL Server" do
  # Create the powershell script
  powershell_script = <<'POWERSHELL_SCRIPT'
    $sqlServiceName='MSSQL$SQLEXPRESS'
    $serviceController = get-service $sqlServiceName 2> $null
    if ($Null -eq $serviceController)
    {
        $sqlServiceName='MSSQLSERVER'
        $serviceController = get-service $sqlServiceName 2> $null
        if ($Null -eq $serviceController)
        {
            Write-Error "SQL Server service is not installed"
            exit 110
        }
    }

    if ($serviceController.Status -eq "Stopped")
    {
       net start $sqlServiceName
    }
    else
    {
        net stop $sqlServiceName
        net start $sqlServiceName
    }
POWERSHELL_SCRIPT

  source(powershell_script)
end
