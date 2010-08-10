# Cookbook Name:: utilities
# Recipe:: install_7zip
#
# Copyright 2010, RightScale, Inc.
#
# All rights reserved

powershell "Installs 7zip" do
  attachments_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'files', 'install_7zip'))
  parameters({'ATTACHMENTS_PATH' => attachments_path})

  # Create the powershell script
  powershell_script = <<'POWERSHELL_SCRIPT'
    cd "$env:ATTACHMENTS_PATH"
    $file="7z465.exe"
    cmd /c $file /S

    #Permanently update windows Path
    if (Test-Path ${env:programfiles(x86)}) { 
      [environment]::SetEnvironmentvariable("Path", $env:Path+";"+$env:programfiles(x86)+"\7-Zip", "Machine")
    } Elseif (Test-Path ${env:programfiles}) { 
      [environment]::SetEnvironmentvariable("Path", $env:Path+";"+$env:programfiles+"\7-Zip", "Machine")
    }
POWERSHELL_SCRIPT

  source(powershell_script)
end
