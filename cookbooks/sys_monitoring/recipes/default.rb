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

require 'fileutils'

# Copy collectd and monitor library file(s).
ruby 'setup monitoring' do
  src_dir_path = File.join(File.dirname(__FILE__), '..', 'files', 'default')
  dst_dir_path = File.expand_path(File.join(RightScale::RightLinkConfig[:rs_root_path], '..', 'RightLinkService', 'scripts', 'lib'))
  FileUtils.mkdir_p(dst_dir_path)
  FileUtils.cp_r(File.join(src_dir_path, '.'), dst_dir_path)
end

# Enable monitoring in the dashboard
right_link_tag 'rs_monitoring:state=active'

# Configure and enable monitoring script
template File.join(RightScale::RightLinkConfig[:rs_root_path], '..', 'RightLinkService', 'scripts', 'monitoring.rb') do
  source 'monitoring.rb.erb'
end
