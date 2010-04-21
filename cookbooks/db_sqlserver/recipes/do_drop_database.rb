# Cookbook Name:: db_sqlserver
# Recipe:: do_backup
#
# Copyright 2009, RightScale, Inc.
#
# All rights reserved - Do Not Redistribute


powershell "Drop the specified database" do
  server_name = @node[:db_sqlserver][:server_name]
  database_name = @node[:db_sqlserver][:database_name]
  parameters('DATABASE_NAME' => database_name,
             'SQL_SERVER_NAME' => server_name)

  # FIX: avoiding remote_file provider in windows until it is tested.
  source_file_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'files', 'default', 'do_drop_database.ps1'))
  source_path(source_file_path)
end
