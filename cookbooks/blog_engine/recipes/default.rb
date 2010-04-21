#
# Cookbook Name:: web_iis
# Recipe:: default
#
# Copyright 2010, RightScale, Inc.
#
# All rights reserved - Do Not Redistribute
#
unless @node[:boot_run]
  include_recipe 'win_admin::change_admin_password'
  include_recipe 'sys_monitoring::default'
  include_recipe 'db_sqlserver::do_load_demo'
  include_recipe 'web_iis::do_demo_deploy'
  @node[:boot_run] = true
end

