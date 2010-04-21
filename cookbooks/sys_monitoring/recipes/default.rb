# Cookbook Name:: sys_monitoring
# Recipe:: default
#
# Copyright 2009, RightScale, Inc.
#
# All rights reserved - Do Not Redistribute

# Install collectd gem
ruby 'setup monitoring' do
  code <<-EOC 
    require 'fileutils'
    FileUtils.mkdir_p('#{File.join(RightScale::RightLinkConfig[:rs_root_path], '..', 'RightLinkService', 'scripts')}')
  EOC
end

# Enable monitoring in the dashboard
right_link_tag 'rs_monitoring:state=active'

# Configure and enable monitoring script
template File.join(RightScale::RightLinkConfig[:rs_root_path], '..', 'RightLinkService', 'scripts', 'monitoring.rb') do
  source 'monitoring.rb.erb'
end