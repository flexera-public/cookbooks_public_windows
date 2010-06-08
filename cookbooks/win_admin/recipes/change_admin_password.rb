# Cookbook Name:: win_admin
# Recipe:: change_admin_password
#
# Copyright 2010, RightScale, Inc.
#
# All rights reserved

# change admin password
powershell "Change the administrator password" do
  parameters('ADMIN_PASSWORD' => @node[:win_admin][:admin_password])

  # Create the powershell script
  powershell_script = <<'POWERSHELL_SCRIPT'
    net user administrator "$env:ADMIN_PASSWORD"
POWERSHELL_SCRIPT

  source(powershell_script)
end
