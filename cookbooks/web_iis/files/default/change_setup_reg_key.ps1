  $RegKey ="HKLM:\Software\Microsoft\Windows\CurrentVersion\Setup"
  set-ItemProperty -path $RegKey -name SourcePath -value "D:\Disk1"
  set-ItemProperty -path $RegKey -name ServicePackSourcePath -value "D:\Disk1"