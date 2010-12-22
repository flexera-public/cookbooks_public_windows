# Cookbook Name:: utilities
# Recipe:: register_dns_name
#
# Copyright 2010, RightScale, Inc.
#
# All rights reserved

# Configures the DNS name for current instance's public IP
dns node[:dns][:dns_id] do
  user node[:dns][:user]
  passwd node[:dns][:password]
  ip_address (node[:dns][:address_type] == 'private') ? ENV['EC2_LOCAL_IPV4'] : ENV['EC2_PUBLIC_IPV4']
end
