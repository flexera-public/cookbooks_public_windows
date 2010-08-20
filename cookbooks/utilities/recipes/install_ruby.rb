# Cookbook Name:: utilities
# Recipe:: install_ruby
#
# Copyright 2010, RightScale, Inc.
#
# All rights reserved

powershell "Installs Ruby" do
  attachments_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'files', 'ruby'))
  parameters({'ATTACHMENTS_PATH' => attachments_path})

  # Create the powershell script
  powershell_script = <<'POWERSHELL_SCRIPT'
  cmd /c 7z x -y "${env:ATTACHMENTS_PATH}/ruby-1.8.6-p383-i386-mingw32-rc1.7z"
  mv ruby-1.8.6-p383-i386-mingw32 c:\Ruby
  rm $file

  #Permanently update windows Path
  [environment]::SetEnvironmentvariable("Path", $env:Path+";C:\Ruby\bin", "Machine")
POWERSHELL_SCRIPT

  source(powershell_script)
end
