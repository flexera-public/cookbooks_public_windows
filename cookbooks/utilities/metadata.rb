maintainer       "RightScale, Inc."
maintainer_email "support@rightscale.com"
license          IO.read(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'LICENSE')))
description      "Windows Admin recipes and providers"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.3.2"

recipe "utilities::default", "Not yet implemented"
recipe "utilities::change_admin_password", "Changes the administrator password"
recipe "utilities::system_reboot", "Reboots the system"
recipe "utilities::system_shutdown", "Shuts down the system"
recipe "utilities::install_firefox", "Installs Mozilla Firefox 3.6"
recipe "utilities::install_7zip", "Installs 7-Zip"
recipe "utilities::install_ruby", "Installs Ruby"
recipe "utilities::create_scheduled_task", "Creates the 'rs_scheduled_task' scheduled task under the 'administrator' user. Uses the SCHTASKS Windows command"
recipe "utilities::delete_scheduled_task", "Deletes the 'rs_scheduled_task' scheduled task under the 'administrator' user. Uses the SCHTASKS Windows command"

attribute "utilities/admin_password",
  :display_name => "New administrator password",
  :description => "New administrator password",
  :recipes => ["utilities::change_admin_password", "utilities::create_scheduled_task"],
  :required => "required"

attribute "schtasks/command",
  :display_name => "Task command",
  :description => "Defines the shell command to run. (e.g., dir >> c:\\dir.txt)",
  :recipes => ["utilities::create_scheduled_task"],
  :required => "required"

attribute "schtasks/hourly_frequency",
  :display_name => "Task Hourly frequency",
  :description => "Defines the task frequency in hours. Valid values: 1 up to 24. When 24 is specified the 'Task daily time' input is required also.",
  :recipes => ["utilities::create_scheduled_task"],
  :required => "required"

attribute "schtasks/daily_time",
  :display_name => "Task daily time",
  :description => "The time of the day, based on the server's timezone, to run the task when the 'Hourly frequency' input is set to 24. Format: hh:mm (e.g., 22:30)",
  :recipes => ["utilities::create_scheduled_task"],
  :required => "optional",
  :default => ""
