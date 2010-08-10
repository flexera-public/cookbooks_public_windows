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
    #check to see if the package is already installed
    if (Test-Path (${env:programfiles(x86)}+"\7-Zip")) { 
      $7zip_path = ${env:programfiles(x86)}+"\7-Zip" 
    } Elseif (Test-Path (${env:programfiles}+"\7-Zip")) { 
      $7zip_path = ${env:programfiles}+"\7-Zip" 
    }

    if ($7zip_path -ne $null) {
      Write-Output "7-Zip package is already installed in [$7zip_path]. Skipping installation."
      exit 0
    }
  
    cd "$env:ATTACHMENTS_PATH"
    $file="7z465.exe"
    cmd /c $file /S

    #Permanently update windows Path
    if (Test-Path (${env:programfiles(x86)}+"\7-Zip")) { 
      [environment]::SetEnvironmentvariable("Path", $env:Path+";"+${env:programfiles(x86)}+"\7-Zip", "Machine")
    } Elseif (Test-Path (${env:programfiles}+"\7-Zip")) { 
      [environment]::SetEnvironmentvariable("Path", $env:Path+";"+${env:programfiles}+"\7-Zip", "Machine")
    } Else {
      Write-Error "Failed to install 7-Zip. Aborting."
      exit 19
    }
POWERSHELL_SCRIPT

  source(powershell_script)
end
