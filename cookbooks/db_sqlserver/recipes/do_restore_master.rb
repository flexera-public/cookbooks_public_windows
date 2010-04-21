# Cookbook Name:: db_sqlserver
# Recipe:: do_restore_master
#
# Copyright 2009, RightScale, Inc.
#
# All rights reserved - Do Not Redistribute

# do the restore.
# TODO: currently no distinction between master or slave
# TODO: currently reliant on local volumes, no support for buckets.
powershell "Restore all databases from a backup directory" do
  server_name = @node[:db_sqlserver][:server_name]
  database_restore_dir = @node[:db_sqlserver][:restore][:database_restore_dir]
  parameters('SQL_BACKUP_DIR_PATH' => database_restore_dir,
             'SQL_SERVER_NAME' => server_name)

  # FIX: avoiding remote_file provider in windows until it is tested.
  source_file_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'files', 'default', 'do_restore_master.ps1'))
  source_path(source_file_path)
end
