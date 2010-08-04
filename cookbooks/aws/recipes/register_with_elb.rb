# Cookbook Name:: aws
# Recipe:: register_with_elb
#
# Copyright 2010, RightScale, Inc.
#
# All rights reserved
#

# register instance with elb
aws_elb "register instance provider call" do
  access_key_id @node[:aws][:access_key_id]
  secret_access_key @node[:aws][:secret_access_key]
  elb_name @node[:aws][:elb_name]
  action :register
end