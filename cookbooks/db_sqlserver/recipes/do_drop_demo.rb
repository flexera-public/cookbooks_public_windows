# Cookbook Name:: db_sqlserver
# Recipe:: do_load_demo
#
# Copyright 2010, RightScale, Inc.
#
# All rights reserved - Do Not Redistribute

# drops the demo database.
db_sqlserver_powershell_database "BlogEngine" do
  server_name @node[:db_sqlserver][:server_name]

  action :drop
end
