# Cookbook Name:: db_sqlserver
# Recipe:: do_load_demo
#
# Copyright 2010, RightScale, Inc.
#
# All rights reserved - Do Not Redistribute

# restores the demo database from a specified local machine directory.
db_sqlserver_powershell_database "BlogEngine" do
  backup_dir_path @node[:db_sqlserver][:restore][:database_restore_dir]
  backup_file_name_pattern @node[:db_sqlserver][:backup][:backup_file_name_pattern]
  server_name @node[:db_sqlserver][:server_name]
  force_restore true

  action :restore
end
