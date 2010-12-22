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

# locals.
$name = Get-NewResource name
$username = Get-NewResource username
$password = Get-NewResource password
$command = Get-NewResource command

$dailyTime = Get-NewResource daily_time
$hourlyFrequency = Get-NewResource hourly_frequency

# "Stop" or "Continue" the powershell script execution when a command fails
$ErrorActionPreference = "Stop"

#check inputs.
$Error.Clear()
if (($name -eq $NULL) -or ($name -eq ""))
{
    Write-Error "Error: 'name' is a required attribute for the 'scheduled_tasks' provider. Aborting..."
    exit 131
}
if (($username -eq $NULL) -or ($username -eq ""))
{
    Write-Error "Error: 'username' is a required attribute for the 'scheduled_tasks' provider. Aborting..."
    exit 132
}
if (($password -eq $NULL) -or ($password -eq ""))
{
    Write-Error "Error: 'password' is a required attribute for the 'scheduled_tasks' provider. Aborting..."
    exit 133
}
if (($hourlyFrequency -eq $NULL) -or ($hourlyFrequency -eq ""))
{
    Write-Error "Error: 'hourly_frequency' is a required attribute for the 'scheduled_tasks' provider. Aborting..."
    exit 134
}

#remove any characters that might brake the command
$name = $name -replace '[^\w]', ''

Write-Output "Converting hourly frequency [$hourlyFrequency] into an integer."
$hourlyFrequency=[int]$hourlyFrequency

if ((($dailyTime -eq $NULL) -or ($dailyTime -eq "")) -and ($hourly_frequency -eq 24))
{
    Write-Error "Error: 'daily_time' is a required attribute for the 'scheduled_tasks' provider when 'hourly_frequency=24'. Aborting..."
    exit 135
}


if ($hourlyFrequency -ge 1 -and $hourlyFrequency -le 23)
{
  Write-Output "Setting task name [$name] with hourly frequency [$hourlyFrequency]"
  schtasks.exe /Create /F /SC HOURLY /MO $hourlyFrequency /RU $username /RP $password /TN $name /TR "$command"
}
elseif ($hourlyFrequency -eq 24)
{
  if (!($dailyTime -match "^[0-2]\d:[0-5]\d$"))
  {
    Write-Error "Error: The 'daily_time' attribute[$dailyTime] is incorrect. Please use the 'hh:mm' format."
    exit 136
  }
  Write-Output "Setting task name [$name] daily at [$dailyTime]"
  schtasks.exe /Create /F /SC DAILY /ST $dailyTime /RU $username /RP $password /TN $name /TR "$command"
}
else
{
  Write-Error "Error: Hourly frequency is not between 1 and 24, aborting..."
  exit 137
}

if (!$?)
{
    Write-Error "Error: SCHTASKS execution failed."
    exit 138
}

#/Query /TN available only in 2008
#schtasks.exe /Query /TN $name