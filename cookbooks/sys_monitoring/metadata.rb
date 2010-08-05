maintainer       "RightScale, Inc."
maintainer_email "support@rightscale.com"
license          IO.read(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'LICENSE')))
description      "Send collectd data to RightScale"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.3.13"

recipe "sys_monitoring::default", "Install monitoring plugin"
