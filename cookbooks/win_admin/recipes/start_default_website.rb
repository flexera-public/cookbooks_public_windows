# Cookbook Name:: win_admin
# Recipe:: start_default_website
#
# Copyright 2010, RightScale, Inc.
#
# All rights reserved

# start the default website
  powershell "Start Default Web Site" do
    # Create the powershell script
    powershell_script = <<-EOF
      # starts the default website on IIS7
      $appcmd_path = $env:systemroot + "\\system32\\inetsrv\\APPCMD.exe"
      $appcmd_exists = Test-Path $appcmd_path
      if ($appcmd_exists)
      {
          &$appcmd_path start SITE "Default Web Site"
      }
      EOF

    source(powershell_script)
  end
