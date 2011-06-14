#  Author: Ryan J. Geyer (<me@ryangeyer.com>)
#  Copyright 2011 Ryan J. Geyer
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

if !File.directory?(node[:app_iis][:releases_dir]) || Dir.entries(node[:app_iis][:releases_dir]).size == 2

  app_iis_update_code_svn "Download Code & Configure IIS" do
    repo_path node[:svn][:repo_path]
    svn_username node[:svn][:username]
    svn_password node[:svn][:password]
    svn_force_checkout node[:svn][:force_checkout] == 'true'
    releases_dir node[:app_iis][:releases_dir]
  end

else

  newest_release_dir = Dir.entries(node[:app_iis][:releases_dir]).sort{|a,b| b <=> a }.first
  newest_release_path = ::File.join(node[:app_iis][:releases_dir], newest_release_dir)

  app_iis_site "Default Web Site" do
    physical_path newest_release_path
    action :update
  end

end