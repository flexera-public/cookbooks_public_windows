# Cookbook Name:: win_admin
# Recipe:: start_default_website
#
# Copyright 2010, RightScale, Inc.
#
# All rights reserved

# Start the website named "Default Web Site"
powershell "Start Web Site" do
  # Create the powershell script
  powershell_script = <<EOF
    $site = Get-WmiObject -Namespace "root\\webadministration" -Class Site -Filter "Name = 'Default Web Site'";
    if ($Null -eq $site)
    {
        Write-Error "The website named (Default Web Site) does not exist on the machine"
        exit 100
    }
    else
    {
        $run_state = $site.GetState().ReturnValue
        if ($run_state -eq 3)
        {
            Write-Output "Starting the default web site"
            $site.start();
        }
        elseif ($run_state -eq 1)
        {
            Write-Output "The default website is running.  No need to start it."
        }
        else
        {
            $message = "The default website is neither running nor stopped.  It's current state is:" + $run_state
            Write-Output $message
        }
    }
EOF

  source(powershell_script)
end
