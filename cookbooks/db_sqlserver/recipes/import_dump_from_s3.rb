# Cookbook Name:: db_sqlserver
# Recipe:: import_dump_from_s3
#
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

unless (!@node[:s3][:file_dump].to_s.empty? && !@node[:s3][:bucket_dump].to_s.empty?)
  Chef::Log.info("*** Bucket or dump file not specified, skipping dump import...")
else
  if (@node[:db_sqlserver_import_dump_from_s3_executed])
    Chef::Log.info("*** Recipe 'db_sqlserver::import_dump_from_s3' already executed, skipping...")
  else
    # download the sql dump
    aws_s3 "Download SqlServer dump from S3 bucket" do
      access_key_id @node[:aws][:access_key_id]
      secret_access_key @node[:aws][:secret_access_key]
      s3_bucket @node[:s3][:bucket_dump]
      s3_file @node[:s3][:file_dump]
      download_dir "c:/tmp"
      action :get
    end
  
    sql_dump=@node[:s3][:file_dump]
  
    # unpack the dump file. Example: mydump.sql.zip
    if (@node[:s3][:file_dump] =~ /(.*)\.(zip|7z|rar)/)
      sql_dump=$1
      Chef::Log.info("*** Unpacking database dump.")
      powershell "Unpacking "+@node[:s3][:file_dump] do
        parameters({'PACKAGE' => @node[:s3][:file_dump]})
        # Create the powershell script
        powershell_script = <<'POWERSHELL_SCRIPT'
          cd c:/tmp
          cmd /c 7z x -y "c:/tmp/${env:PACKAGE}"
POWERSHELL_SCRIPT
        source(powershell_script)
      end
    end
  
    # load the initial demo database from deployed SQL script.
    # no schema provided for this import call
    db_sqlserver_database "noschemayet" do
      server_name @node[:db_sqlserver][:server_name]
      script_path "c:/tmp/"+sql_dump
      action :run_script
    end
  
    @node[:db_sqlserver_import_dump_from_s3_executed] = true
  end
end