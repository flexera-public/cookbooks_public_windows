# Cookbook Name:: db_sqlserver
# Recipe:: enable_sql_service
#
# Copyright 2010, RightScale, Inc.
#
# All rights reserved

# enable the SQL service
powershell "Enable the SQL service" do
  # Create the powershell script
  powershell_script = <<EOF
    $sqlServiceName='MSSQL$SQLEXPRESS'
    $serviceController = get-service $sqlServiceName 2> $null
    if ($Null -eq $serviceController)
    {
        $sqlServiceName='MSSQLSERVER'
        $serviceController = get-service $sqlServiceName 2> $null
        if ($Null -eq $serviceController)
        {
            Write-Error "SQL Server service is not installed"
            exit 100
        }
    }

    if ($serviceController.Status -eq "Stopped")
    {
        sc.exe config $sqlServiceName start= auto
        if ($LastExitCode -eq 0)
        {
            net start $sqlServiceName
            if ($LastExitCode -ne 0)
            {
                Write-Error "Failed to start $sqlServiceName service"
                exit $LastExitCode
            }
        }
        else
        {
            Write-Error "Failed to enable $sqlServiceName service"
            exit $LastExitCode
        }
    }
    else
    {
        $message = "$sqlServiceName service is already " + $serviceController.Status
        Write-Output $message
    }
EOF

  source(powershell_script)
end
