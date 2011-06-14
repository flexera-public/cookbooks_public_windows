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

define :app_iis_update_code_s3, :access_key_id => nil,
       :secret_access_key => nil,
       :application_code_bucket => nil,
       :application_code_package => nil,
       :releases_dir => "C:/inetpub/releases" do

  temp_dir = ENV['TMP']

  # download the code from s3
  aws_s3 "Download code from S3 bucket" do
    access_key_id params[:access_key_id]
    secret_access_key params[:secret_access_key]
    s3_bucket params[:application_code_bucket]
    s3_file params[:application_code_package]
    download_dir temp_dir
    action :get
  end


  # Unpack code in params[:releases_dir]
  code_checkout_package "Unpacking code in the releases directory" do
    releases_path params[:releases_dir]
    package_path ::File.join(temp_dir, params[:application_code_package])
    action :unpack
  end

  app_iis_site "Default Web Site" do
    physical_path_node_attr "releasesunpackpath"
    action :update
  end

end