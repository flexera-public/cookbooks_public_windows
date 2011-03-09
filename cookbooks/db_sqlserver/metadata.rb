maintainer       "RightScale, Inc."
maintainer_email "support@rightscale.com"
license          IO.read(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'LICENSE')))
description      "Microsoft SQL Server recipes and providers"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.4.1"

depends 'aws'

recipe 'db_sqlserver::default', 'Sets up default user and enables SQL service.'
recipe "db_sqlserver::backup", "Backs up database to a local machine directory."
recipe "db_sqlserver::backup_to_s3", "Backs up database to S3."
recipe "db_sqlserver::restore", "Restores database from a local machine directory."
recipe "db_sqlserver::restore_once", "Restores database from a local machine directory. Usually executed on first boot."
recipe "db_sqlserver::drop", "Drops a database."
recipe "db_sqlserver::import_dump_from_s3", 'Downloads SQL dump from S3 bucket and imports it into database.'
recipe "db_sqlserver::enable_sql_service", "Enables the SQL Server service if disabled"
recipe "db_sqlserver::restart_sql_service", "Restarts the MSSQL Server"
recipe "db_sqlserver::enable_sql_mixed_mode_authentication", "Enables Mixed authentication for the SQL Server"
recipe "db_sqlserver::create_user", "Creates a user with read/write permissions to the database"
recipe "db_sqlserver::create_login", "Creates a login with password"

attribute "db_sqlserver/server_name",
  :display_name => "SQL Server instance network name",
  :description => "The network name of the SQL Server instance used by recipes. Ex: 'localhost\\SQLEXPRESS' for SQL EXPRESS or 'localhost' for SQL STANDARD",
  :recipes => ["db_sqlserver::default", "db_sqlserver::import_dump_from_s3", "db_sqlserver::backup", "db_sqlserver::backup_to_s3", "db_sqlserver::restore", "db_sqlserver::restore_once", "db_sqlserver::drop", "db_sqlserver::enable_sql_mixed_mode_authentication", "db_sqlserver::create_user", "db_sqlserver::create_login"],
  :required => "required"

attribute "db_sqlserver/database_name",
  :display_name => "SQL Server database name",
  :description => "SQL Server database(schema) name. Ex: production",
  :recipes => ["db_sqlserver::default", "db_sqlserver::backup", "db_sqlserver::backup_to_s3", "db_sqlserver::restore", "db_sqlserver::restore_once", "db_sqlserver::drop", "db_sqlserver::enable_sql_mixed_mode_authentication", "db_sqlserver::create_user", "db_sqlserver::create_login"],
  :required => "required"

attribute "db_sqlserver/backup/database_backup_dir",
  :display_name => "SQL Server backup .bak directory",
  :description => "The local drive path or UNC path to the directory which will contain new SQL Server database backup (.bak) files. Note that network drives are not supported by SQL Server.",
  :default => "c:\\datastore\\sqlserver\\databases",
  :recipes => ["db_sqlserver::backup", "db_sqlserver::backup_to_s3", "db_sqlserver::restore", "db_sqlserver::restore_once"]

attribute "db_sqlserver/backup/backup_file_name_format",
  :display_name => "Backup file name format",
  :description => "Format string with Powershell-style string format arguments for creating backup files. The 0 argument represents the database name and the 1 argument represents a generated time stamp. Ex: {0}_{1}.bak",
  :default => "{0}_{1}.bak",
  :recipes => ["db_sqlserver::default", "db_sqlserver::backup", "db_sqlserver::backup_to_s3", "db_sqlserver::restore", "db_sqlserver::restore_once"]

attribute "db_sqlserver/backup/existing_backup_file_name_pattern",
  :display_name => "Pattern matching backup file names",
  :description => "Wildcard file matching pattern (i.e. not a Regex) with Powershell-style string format arguments for finding backup files. The 0 argument represents the database name and the rest of the pattern should match the file names generated from the backup_file_name_format. Ex: {0}_*.bak",
  :default => "{0}_*.bak",
  :recipes => ["db_sqlserver::default", "db_sqlserver::backup", "db_sqlserver::backup_to_s3", "db_sqlserver::restore", "db_sqlserver::restore_once"]

attribute "db_sqlserver/backup/backups_to_keep",
  :display_name => "Old backups to keep",
  :description => "Defines the number of old backups to keep. Ex: 30",
  :recipes => ["db_sqlserver::backup", "db_sqlserver::backup_to_s3"],
  :required => "required"

attribute "db_sqlserver/restore/force_restore",
  :display_name => "Force restore",
  :description => "Whether to force restoring backup on top of any pre-existing database",
  :recipes => ["db_sqlserver::restore", "db_sqlserver::restore_once"],
  :choice => ['true', 'false'],
  :default => "false"

attribute "db_sqlserver/application_user",
  :display_name => "DB Application user",
  :description => "The username to be used for read/write access to the database. Ex: dbuser",
  :recipes => ["db_sqlserver::create_user", "db_sqlserver::create_login"],
  :required => "required"

attribute "db_sqlserver/application_pass",
  :display_name => "DB Application pass",
  :description => "The password to be used for read/write access to the database. Ex: dbpass",
  :recipes => ["db_sqlserver::create_user", "db_sqlserver::create_login"],
  :required => "required"

attribute "s3/file_dump",
  :display_name => "Sql dump file",
  :description => "Sql dump file to be retrieved from the s3 bucket. Ex: production-dump.sql or production-dump.sql.zip",
  :recipes => ["db_sqlserver::default", "db_sqlserver::import_dump_from_s3"],
  :required => "required"

attribute "s3/bucket_dump",
  :display_name => "Bucket for sql dump",
  :description => "The name of the S3 bucket. Ex: production-bucket-dumps",
  :recipes => ["db_sqlserver::default", "db_sqlserver::import_dump_from_s3"],
  :required => "required"

attribute "s3/bucket_backups",
  :display_name => "Bucket to store backups",
  :description => "The name of the S3 bucket. Ex: production-bucket-backup",
  :recipes => ["db_sqlserver::backup_to_s3"],
  :required => "required"

attribute "aws/access_key_id",
  :display_name => "Access Key Id",
  :description => "This is an Amazon credential. Log in to your AWS account at aws.amazon.com to retrieve you access identifiers. Ex: 1JHQQ4KVEVM02KVEVM02",
  :recipes => ["db_sqlserver::default", "db_sqlserver::import_dump_from_s3", "db_sqlserver::backup_to_s3"],
  :required => "required"

attribute "aws/secret_access_key",
  :display_name => "Secret Access Key",
  :description => "This is an Amazon credential. Log in to your AWS account at aws.amazon.com to retrieve your access identifiers. Ex: XVdxPgOM4auGcMlPz61IZGotpr9LzzI07tT8s2Ws",
  :recipes => ["db_sqlserver::default", "db_sqlserver::import_dump_from_s3", "db_sqlserver::backup_to_s3"],
  :required => "required"
