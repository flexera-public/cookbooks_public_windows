# Cookbook Name:: utilities
# Recipe:: online_attached_drives
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

powershell "Change 'Offline' status to 'Online' for the attached drives" do

# Create the powershell script
powershell_script = <<'POWERSHELL_SCRIPT'
  $diskpart_path = $env:systemroot + '\system32\diskpart.exe'
  if (!(Test-Path $diskpart_path))
  {
    Write-Warning "diskpart.exe is missing, probably 2003 image."
    exit 0 
  }

  $offlinedisks = invoke-expression 'Write-Output "list disk" | diskpart.exe | where {$_ -match "Offline"}'
  echo "*** Offline disks:[`n$offlinedisks]"

  $offlinediskids=$offlinedisks -replace ".*Disk (\d+).*","`$1"

  #change disk state from 'Offline' to 'Online' and clear readonly flag
  echo $offlinediskids | Foreach-Object {
    if ($_ -match "^\d+$") {
      $command=@"
      select disk=$_
      online disk
      attributes disk clear readonly
"@
      
      $command | diskpart.exe
    }
  }

  Write-Output "*** All disks:" 
  Write-Output "list disk" | diskpart.exe
POWERSHELL_SCRIPT

source(powershell_script)
end






