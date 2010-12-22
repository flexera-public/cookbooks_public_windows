maintainer       "RightScale, Inc."
maintainer_email "support@rightscale.com"
license          IO.read(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'LICENSE')))
description      "Send collectd data to RightScale"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.3.15"

recipe "sys_monitoring::default", "Install monitoring plugin"
recipe "sys_monitoring::add_file_stats", 'Monitors file size and last modified time in seconds'
recipe "sys_monitoring::add_process_stats", 'Monitors process and thread count'
recipe "sys_monitoring::add_iis_stats", 'Monitors IIS stats'

attribute "sys_monitoring/monitor_files",
  :display_name => "Monitor files",
  :description => 'A space separated list of files to be monitored. Full paths are required and patterns are accepted also. If a pattern matches more than one file, the latest modified file will be used. Ex: c:\tmp\a.txt d:\backups\mydb.*bak',
  :recipes => ["sys_monitoring::add_file_stats"],
  :required => "required"
  
attribute "sys_monitoring/monitor_processes",
  :display_name => "Monitor processes",
  :description => 'A space separated list of processes to monitor process and thread count. Ex: winlogon.exe cmd.exe',
  :recipes => ["sys_monitoring::add_process_stats"],
  :required => "required"