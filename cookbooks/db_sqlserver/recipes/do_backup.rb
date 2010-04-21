# Cookbook Name:: db_sqlserver
# Recipe:: do_backup
#
# Copyright 2009, RightScale, Inc.
#
# All rights reserved - Do Not Redistribute

# do the backup
# TODO: currently no distinction between master or slave
# TODO: currently reliant on local volumes, no support for buckets.
powershell "Backup all non-system SQL Server databases to a backup directory" do
  server_name = @node[:db_sqlserver][:server_name]
  database_backup_dir = @node[:db_sqlserver][:backup][:database_backup_dir]
  parameters('SQL_BACKUP_DIR_PATH' => database_backup_dir,
             'SQL_SERVER_NAME' => server_name)

  # FIX: avoiding remote_file provider in windows until it is tested.
  source_file_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'files', 'default', 'do_backup.ps1'))
  source_path(source_file_path)
end
