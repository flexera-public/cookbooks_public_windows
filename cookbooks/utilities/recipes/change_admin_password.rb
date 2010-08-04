# Cookbook Name:: utilities
# Recipe:: change_admin_password
#
# Copyright 2010, RightScale, Inc.
#
# All rights reserved

# change admin password
powershell "Changes the administrator password" do
  parameters({'ADMIN_PASSWORD' => @node[:utilities][:admin_password]})

  # Create the powershell script
  powershell_script = <<'POWERSHELL_SCRIPT'
    net user administrator "$env:ADMIN_PASSWORD"
POWERSHELL_SCRIPT

  source(powershell_script)
end
