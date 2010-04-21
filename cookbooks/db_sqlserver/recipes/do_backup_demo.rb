# Cookbook Name:: db_sqlserver
# Recipe:: do_load_demo
#
# Copyright 2010, RightScale, Inc.
#
# All rights reserved - Do Not Redistribute

# backs up the demo database to a specified local machine directory.
db_sqlserver_powershell_database "BlogEngine" do
  backup_dir_path @node[:db_sqlserver][:backup][:database_backup_dir]
  backup_file_name_pattern @node[:db_sqlserver][:backup][:backup_file_name_pattern]
  backup_file_name_format @node[:db_sqlserver][:backup][:backup_file_name_format]
  server_name @node[:db_sqlserver][:server_name]

  action :backup
end
