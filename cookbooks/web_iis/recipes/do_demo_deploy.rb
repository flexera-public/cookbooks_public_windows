# Cookbook Name:: db_sqlserver
# Recipe:: do_backup
#
# Copyright 2009, RightScale, Inc.
#
# All rights reserved - Do Not Redistribute

# deploy web app zips to the wwwroot directory.
powershell "Deploy demo web app from cookbook-relative zipped source to wwwroot under IIS" do
  # FIX: avoiding remote_file provider in windows until it is tested.
  web_app_src_zips = File.expand_path(File.join(File.dirname(__FILE__), '..', 'files', 'default', 'i386'))
  parameters('WEB_APP_ZIP_DIR_PATH' => web_app_src_zips,
             'CHECK_FOR_EXISTANCE' => 'true')

  source_file_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'files', 'default', 'do_simple_app_deploy.ps1'))
  source_path(source_file_path)
end
