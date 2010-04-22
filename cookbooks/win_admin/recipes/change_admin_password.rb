# Cookbook Name:: win_admin
# Recipe:: change_admin_password
#
# Copyright 2010, RightScale, Inc.
#
# All rights reserved

# change admin password
powershell "Changes the administrator password" do
  chef_attribute = Chef::Node::Attribute.new(
                      {'ADMIN_PASSWORD' => @node[:win_admin][:admin_password]},
                      {},
                      {})
  parameters(chef_attribute)

  # Create the powershell script
  powershell_script = <<'POWERSHELL_SCRIPT'
    net user administrator "$env:ADMIN_PASSWORD"
POWERSHELL_SCRIPT

  source(powershell_script)
end
