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

# Collect and send disk usage
#
# === Return
# true:: Always return true
def run
  drives = execute_wmi_query("Select deviceid, freespace, size from win32_logicaldisk")
  for drive in drives do
    if drive.deviceid =~ /^(\w):$/
      drive_letter = $1
      free_space_val = drive.freespace
      drive_size_val = drive.size
      if is_number?(free_space_val) && is_number?(drive_size_val)
        used_space = drive_size_val.to_i - free_space_val.to_i
        @logger.debug("Drive #{drive_letter}: has #{free_space_val} free and #{used_space} used space")
        gauge('df', '', 'df', "drive_#{drive_letter}", [ used_space, free_space_val.to_i ])
      end
    end
  end
end
