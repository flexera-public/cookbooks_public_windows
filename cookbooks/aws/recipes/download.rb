# Cookbook Name:: aws
# Recipe:: download
#
# Copyright 2010, RightScale, Inc.
#
# All rights reserved

# download
aws_s3 "downloadmyfile" do
  access_key_id @node[:aws][:access_key_id]
  secret_access_key @node[:aws][:secret_access_key]
  s3_bucket @node[:s3][:bucket]
  s3_file @node[:s3][:file]
  download_dir @node[:aws][:download_dir]
  action :get
end

powershell "list drive c" do
  chef_attribute = Chef::Node::Attribute.new(
                      {},
                      {},
                      {})
  parameters(chef_attribute)

  # Create the powershell script
  powershell_script = <<'POWERSHELL_SCRIPT'
    ls c:\
POWERSHELL_SCRIPT

  source(powershell_script)
end
