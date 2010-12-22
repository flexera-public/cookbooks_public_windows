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

actions :backup, :drop, :restore, :run_command, :run_script

attribute :backup_dir_path, :kind_of => [ String ]
attribute :backup_file_name_format, :kind_of => [ String ]
attribute :existing_backup_file_name_pattern, :kind_of => [ String ]
attribute :server_name, :kind_of => [ String ]
attribute :force_restore, :equal_to => [ true, false ]
attribute :commands, :kind_of => [ Array ]
attribute :script_path, :kind_of => [ String ]
attribute :zip_backup, :equal_to => [ true, false ]
attribute :delete_sql_after_zip, :equal_to => [ true, false ]
attribute :max_old_backups_to_keep, :kind_of => [ String ]
attribute :statement_timeout_seconds, :kind_of => [ Integer ]
