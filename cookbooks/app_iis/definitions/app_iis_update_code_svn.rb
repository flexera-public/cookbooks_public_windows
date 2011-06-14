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

define :app_iis_update_code_svn, :repo_path => nil,
       :svn_username => nil,
       :svn_password => nil,
       :svn_force_checkout => true,
       :releases_dir => "C:/inetpub/releases" do

  code_checkout_svn params[:repo_path] do
    releases_path params[:releases_dir]
    svn_username params[:svn_username]
    svn_password params[:svn_password]
    force_checkout params[:svn_force_checkout]
    action :checkout
  end

  app_iis_site "Default Web Site" do
    physical_path_node_attr "checkoutpath"
    action :update
  end

end