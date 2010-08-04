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
  #$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine")

#  $file = "ruby-1.8.6-p383-i386-mingw32-rc1.7z"
#  $url = "http://rubyforge.org/frs/download.php/66873/"+$file
#  cmd /c "C:\Program Files\RightScale\SandBox\Git\bin\curl.exe" --max-time 120 -C - -O $url

  cmd /c 7z x -y "${env:ATTACHMENTS_PATH}/ruby-1.8.6-p383-i386-mingw32-rc1.7z"
  mv ruby-1.8.6-p383-i386-mingw32 c:\Ruby
  rm $file

  #Permanently update windows Path
  [environment]::SetEnvironmentvariable("Path", $env:Path+";C:\Ruby\bin", "Machine")
POWERSHELL_SCRIPT

  source(powershell_script)
end
