maintainer       "RightScale, Inc."
maintainer_email "alex@rightscale.com"
license          IO.read(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'LICENSE')))
description      "Windows Admin"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.3.0"

recipe "win_admin::default", "Not yet implemented"
recipe "win_admin::change_admin_password", "Changes the administrator password"
recipe "win_admin::enable_sql_express_service", "Enables the SQL Express service if disabled"

attribute "win_admin/admin_password",
  :display_name => "New administrator password",
  :description => "New administrator password",
  :recipes => ["win_admin::change_admin_password"]
