# Cookbook Name:: aws
# Recipe:: default
#
# Copyright 2010, RightScale, Inc.
#
# All rights reserved

powershell "Install AWS SDK" do
  attachments_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'files', 'install_dotnet_sdk'))
  parameters({'ATTACHMENTS_PATH' => attachments_path})

  # Create the powershell script
  powershell_script = <<'POWERSHELL_SCRIPT'
    $aws_sdk = "AWS SDK for .NET"

    #check to see if the package is already installed
    if (Test-Path (${env:programfiles(x86)}+"\"+$aws_sdk)) { 
      $aws_sdk_path = ${env:programfiles(x86)}+"\"+$aws_sdk 
    } Elseif (Test-Path (${env:programfiles}+"\"+$aws_sdk)) { 
      $aws_sdk_path = ${env:programfiles}+"\"+$aws_sdk 
    }
    
    if ($aws_sdk_path -ne $null) {
      Write-Output "*** AWS SDK for .NET already installed in [$aws_sdk_path]. Skipping installation."
    }
    Else {
      cd "$env:ATTACHMENTS_PATH"
      Write-Output "*** Installing AWS SDK for .NET msi"
      cmd /c msiexec /package AWSSDKForNET_1.0.11.msi /quiet
    }
POWERSHELL_SCRIPT

  source(powershell_script)
end