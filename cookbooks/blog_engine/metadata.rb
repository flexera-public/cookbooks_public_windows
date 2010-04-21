maintainer       "RightScale, Inc."
maintainer_email "support@rightscale.com"
license          IO.read(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'LICENSE')))
description      "Install and configure the Blog Engine application"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.0.1"

depends 'win_admin'
depends 'sys_monitoring'
depends 'db_sqlserver'
depends 'web_iis'

recipe 'blog_engine::default', 'Loads the database and installs the Blog Engine application as the default IIS site'

attribute 'win_admin/admin_password',
  :display_name => 'New administrator password',
  :description => 'New administrator password'

attribute "db_sqlserver/server_name",
  :display_name => "SQL Server instance network name",
  :description => "The network name of the SQL Server instance used by recipes.",
  :default => "localhost\\SQLEXPRESS"

attribute "db_sqlserver/database_name",
  :display_name => "Database Name",
  :description => "The name of a database running on this SQL Server instance",
  :default => "BlogEngine",
  :recipes => ["db_sqlserver::do_drop_database"]

attribute "db_sqlserver/backup/database_backup_dir",
  :display_name => "SQL Server backup .bak directory",
  :description => "The local drive path or UNC path to the directory which will contain new SQL Server database backup (.bak) files. Note that network drives are not supported by SQL Server.",
  :default => "c:\\datastore\\sqlserver\\databases",
  :recipes => ["db_sqlserver::do_backup", "db_sqlserver::do_backup_demo"]

attribute "db_sqlserver/backup/backup_file_name_pattern",
  :display_name => "Backup file name format",
  :description => "Format string with Powershell-style string format arguments for creating backup files. The 0 argument represents the database name and the 1 argument represents a generated time stamp.",
  :default => "{0}_{1}.bak"

attribute "web_iis/deploy/web_app_src_zips",
  :display_name => "Web App Source Zips Directory",
  :description => "The path to the directory containing one or more web application source .zip file(s).",
  :default => "d:\\datastore\\aspdotnet\\webapps",
  :recipes => ["web_iis::do_simple_app_deploy"]

