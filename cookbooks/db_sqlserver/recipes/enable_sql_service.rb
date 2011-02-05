# Cookbook Name:: db_sqlserver
# Recipe:: enable_sql_service
#
# Copyright 2010, RightScale, Inc.
#
# All rights reserved

# enable the SQL service
powershell "Enable the SQL service" do
  # Create the powershell script
  powershell_script = <<'POWERSHELL_SCRIPT'
    #tell the script to "stop" or "continue" when a command fails
    $ErrorActionPreference = "stop"
    if (get-service | findstr 'MSSQL\$SQLEXPRESS') {
      $sqlServiceName='MSSQL$SQLEXPRESS'
    } else {
      $sqlServiceName='MSSQLSERVER'
    }
    $serviceController = get-service $sqlServiceName -ErrorAction SilentlyContinue
    if ($serviceController -eq $Null)
    {
        Write-Error "SQL Server service is not installed"
        exit 100
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

    # Exit with a smile
    exit 0
POWERSHELL_SCRIPT

  source(powershell_script)
end
