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

$aws_sdk = "AWS SDK for .NET"

#check to see if the package is already installed
if (Test-Path (${env:programfiles(x86)}+"\"+$aws_sdk)) { 
  $aws_sdk_path = ${env:programfiles(x86)}+"\"+$aws_sdk 
} Elseif (Test-Path (${env:programfiles}+"\"+$aws_sdk)) { 
  $aws_sdk_path = ${env:programfiles}+"\"+$aws_sdk 
}

if ($aws_sdk_path -eq $null) {
  Write-Error "*** AWS SDK for .NET package is not installed on the system. Aborting."
  exit 12
}

#use the AWS SDK dll
Add-Type -Path "$aws_sdk_path\bin\AWSSDK.dll"
