# Cookbook Name:: win_admin
# Recipe:: enable_sql_express_service
#
# Copyright 2010, RightScale, Inc.
#
# All rights reserved

# enable the SQL Express service
powershell "Enable the SQL Express service" do
  # Create the powershell script
  powershell_script = <<EOF
    $serviceController = get-service 'MSSQL$SQLEXPRESS'
    if ($Null -eq $serviceController)
    {
        Write-Error "SQL Express service is not installed"
        exit 100
    }
    elseif ($serviceController.Status -eq "Stopped")
    {
        sc.exe config 'MSSQL$SQLEXPRESS' start= auto
        if ($LastExitCode -eq 0)
        {
            net start 'MSSQL$SQLEXPRESS'
            if ($LastExitCode -ne 0)
            {
                Write-Error "Failed to start SQL Express service"
                exit $LastExitCode
            }
        }
        else
        {
            Write-Error "Failed to enable SQL Express service"
            exit $LastExitCode
        }
    }
    else
    {
        $message = "SQL Express service is already " + $serviceController.Status
        Write-Output $message
    }
EOF

  source(powershell_script)
end
