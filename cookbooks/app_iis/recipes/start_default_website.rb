# Cookbook Name:: app_iis
# Recipe:: start_default_website
#
# Copyright 2010, RightScale, Inc.
#
# All rights reserved

# start the default website
powershell "Start Default Web Site and configure AutoStart" do
  # Create the powershell script
  powershell_script = <<-EOF
    #tell the script to "stop" or "continue" when a command fails
    $ErrorActionPreference = "stop"
    # starts the default website on IIS7
    $appcmd_path = $env:systemroot + "\\system32\\inetsrv\\APPCMD.exe"
    $appcmd_exists = Test-Path $appcmd_path
    if ($appcmd_exists)
    {
        &$appcmd_path start SITE "Default Web Site"
        &$appcmd_path set SITE "Default Web Site" /serverAutoStart:true
    }
    else
    {
        Write-Output "APPCMD.EXE is missing on 2003 image, but Default Web Site is starting by default at boot time" 
    }
    EOF

  source(powershell_script)
end
