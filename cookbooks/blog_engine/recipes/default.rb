# Copyright (c) 2010 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

unless @node[:blog_engine_default_executed]

  include_recipe 'utilities::change_admin_password'
  include_recipe 'sys_monitoring::default'
  include_recipe 'db_sqlserver::enable_sql_service'

  # deploy web app zips to the wwwroot directory.
  powershell "Deploy demo web app from cookbook-relative zipped source to wwwroot under IIS" do
    seven_zip_exe_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'files', 'default', 'bin', '7z.exe'))
    web_app_src_zips = File.expand_path(File.join(File.dirname(__FILE__), '..', 'files', 'default', 'app'))
    parameters('WEB_APP_ZIP_DIR_PATH' => web_app_src_zips,
               'CHECK_FOR_EXISTENCE' => 'true',
               'SEVEN_ZIP_EXE_PATH' => seven_zip_exe_path)

    source_file_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'files', 'default', 'simple_app_deploy.ps1'))
    source_path(source_file_path)
  end

  # load the demo database from deployed SQL script.
  blog_engine_database "master" do
    server_name @node[:db_sqlserver][:server_name]
    commands ["CREATE DATABASE [BlogEngine]"]
    action :run_command
  end

  # load the initial demo database from deployed SQL script.
  blog_engine_database "BlogEngine" do
    server_name @node[:db_sqlserver][:server_name]
    script_path "c:\\inetpub\\wwwroot\\setup\\SQLServer\\MSSQLSetup1.5.0.0.sql"
    action :run_script
  end

  # load the initial demo database from deployed SQL script.
  blog_engine_database "BlogEngine" do
    server_name @node[:db_sqlserver][:server_name]
    commands ["CREATE USER [NetworkService] FOR LOGIN [NT AUTHORITY\\NETWORK SERVICE]",
              "EXEC sp_addrolemember 'db_datareader', 'NetworkService'",
              "EXEC sp_addrolemember 'db_datawriter', 'NetworkService'"]
    action :run_command
  end

  include_recipe 'app_iis::start_default_website'

  @node[:blog_engine_default_executed] = true
end
