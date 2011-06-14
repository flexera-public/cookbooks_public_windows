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

$site_name = Get-NewResource site_name
$physical_path = Get-NewResource physical_path
$appcmd_path = "$env:systemroot\system32\inetsrv\APPCMD.exe"
if ($env:PROCESSOR_ARCHITECTURE -ne "x86")
{
  $appcmd_path = "$env:systemroot\sysnative\inetsrv\APPCMD.exe"
}

# An explicit physical path was not provided, try to find it in the node attribute supplied
if (!$physical_path)
{
  $node_attr_name = Get-NewResource physical_path_node_attr
  if ($node_attr_name)
  {
    $physical_path = Get-ChefNode $node_attr_name
  }
}

# If we don't have one now, it simply wasn't supplied
if (!$physical_path)
{
  Write-Error "Error: No physical path was provided for the website [$site_name]"
  exit 100
}

#tell the script to "stop" or "continue" when a command fails
$ErrorActionPreference = "stop"

if (Test-Path $physical_path -PathType Container)
{
    # change the physicalPath for the IIS site
    if (Test-Path $appcmd_path)
    {
      &$appcmd_path set SITE "Default Web Site" "/[path='/'].[path='/'].physicalPath:$physical_path"
    }
    else
    {
      Write-Output "APPCMD.EXE is missing, probably 2003 image. Trying ADSI"

      $siteName = "Default Web Site"
      $iis = [ADSI]"IIS://localhost/W3SVC"
      $site = $iis.psbase.children | where { $_.keyType -eq "IIsWebServer" -AND $_.ServerComment -eq $siteName }
      $path = [ADSI]($site.psbase.path+"/ROOT")
      $path.psbase.properties.path[0] = $physical_path
      #DefaultDoc cannot be configured in web.config for IIS6
      $path.psbase.properties.DefaultDoc[0]="default.aspx,index.aspx,Default.htm,Default.asp,index.html,index.htm,iisstart.htm,index.php"
      $path.psbase.CommitChanges()
    }
}
else
{
  Write-Error "Error: Invalid physical path [$physical_path]"
  exit 135
}