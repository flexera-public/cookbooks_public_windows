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

unless @node[:boot_run]
  include_recipe 'win_admin::change_admin_password'
  include_recipe 'sys_monitoring::default'

  # loads the demo database from cookbook-relative backup file.
  blog_engine_powershell_database "BlogEngine" do
    machine_type = @node[:kernel][:machine]

    backup_dir_path File.expand_path(File.join(File.dirname(__FILE__), '..', 'files', 'default', machine_type))
    existing_backup_file_name_pattern @node[:db_sqlserver][:backup][:existing_backup_file_name_pattern]
    server_name @node[:db_sqlserver][:server_name]
    force_restore false

    action :restore
  end

  # deploy web app zips to the wwwroot directory.
  powershell "Deploy demo web app from cookbook-relative zipped source to wwwroot under IIS" do
    web_app_src_zips = File.expand_path(File.join(File.dirname(__FILE__), '..', 'files', 'default', 'i386'))
    parameters('WEB_APP_ZIP_DIR_PATH' => web_app_src_zips,
               'CHECK_FOR_EXISTANCE' => 'true')

    source_file_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'files', 'default', 'simple_app_deploy.ps1'))
    source_path(source_file_path)
  end

  @node[:boot_run] = true
end

