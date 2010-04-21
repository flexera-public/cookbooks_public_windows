# Cookbook Name:: db_sqlserver
# Recipe:: do_load_demo
#
# Copyright 2010, RightScale, Inc.
#
# All rights reserved - Do Not Redistribute

# loads the demo database from cookbook-relative backup file.
db_sqlserver_powershell_database "BlogEngine" do
  machine_type = @node[:kernel][:machine]

  backup_dir_path File.expand_path(File.join(File.dirname(__FILE__), '..', 'files', 'default', machine_type))
  backup_file_name_pattern @node[:db_sqlserver][:backup][:backup_file_name_pattern]
  server_name @node[:db_sqlserver][:server_name]
  force_restore false

  action :restore
end
