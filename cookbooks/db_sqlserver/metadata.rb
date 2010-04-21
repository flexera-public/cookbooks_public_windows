maintainer       "RightScale, Inc."
maintainer_email "support@rightscale.com"
license          IO.read(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'LICENSE')))
description      "Manages a SQL Server instance"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.0.23"

recipe "db_sqlserver::default", "Not yet implemented"
recipe "db_sqlserver::do_load_demo", "Loads the demo database from a cookbook-relative directory."
recipe "db_sqlserver::do_backup_demo", "Backs up the demo database to a local machine directory."
recipe "db_sqlserver::do_drop_demo", "Drops the demo database."
recipe "db_sqlserver::do_restore_demo", "Restores the demo database from a local machine directory."
recipe "db_sqlserver::do_backup", "Backs up all non-system SQL Server databases to a backup directory."
recipe "db_sqlserver::do_restore_master", "Restore all databases from a backup directory."
recipe "db_sqlserver::do_drop_database", "Drop the specified database."

# general
attribute "db_sqlserver",
  :display_name => "General SQL Server database options",
  :type => "hash"

attribute "db_sqlserver/server_name",
  :display_name => "SQL Server instance network name",
  :description => "The network name of the SQL Server instance used by recipes.",
  :default => "localhost\\SQLEXPRESS"

attribute "db_sqlserver/database_name",
  :display_name => "Database Name",
  :description => "The name of a database running on this SQL Server instance",
  :default => "BlogEngine",
  :recipes => ["db_sqlserver::do_drop_database"]

# backup
attribute "db_sqlserver/backup",
  :display_name => "SQL Server database backup options",
  :type => "hash"

attribute "db_sqlserver/backup/database_backup_dir",
  :display_name => "SQL Server backup .bak directory",
  :description => "The local drive path or UNC path to the directory which will contain new SQL Server database backup (.bak) files. Note that network drives are not supported by SQL Server.",
  :default => "c:\\datastore\\sqlserver\\databases",
  :recipes => ["db_sqlserver::do_backup", "db_sqlserver::do_backup_demo"]

attribute "db_sqlserver/backup/backup_file_name_format",
  :display_name => "Backup file name format",
  :description => "Format string with Powershell-style string format arguments for creating backup files. The 0 argument represents the database name and the 1 argument represents a generated time stamp.",
  :default => "{0}_{1}.bak",
  :recipes => ["db_sqlserver::do_backup_demo"]

attribute "db_sqlserver/backup/backup_file_name_pattern",
  :display_name => "Backup file name pattern",
  :description => "Wildcard file matching pattern (i.e. not a Regex) with Powershell-style string format arguments for finding backup files. The 0 argument represents the database name and the rest of the pattern should match the file names generated from the backup_file_name_format.",
  :default => "{0}_*.bak",
  :recipes => ["db_sqlserver::do_load_demo", "db_sqlserver::do_restore_demo"]

# restore
attribute "db_sqlserver/restore",
  :display_name => "SQL Server database restore options",
  :type => "hash"

attribute "db_sqlserver/restore/database_restore_dir",
  :display_name => "SQL Server restore .bak directory",
  :description => "The local drive path or UNC path to the directory containing existing SQL Server database backup (.bak) files to be restored. Note that network drives are not supported by SQL Server.",
  :default => "c:\\datastore\\sqlserver\\databases",
  :recipes => ["db_sqlserver::do_restore_master", "db_sqlserver::do_restore_demo"]
