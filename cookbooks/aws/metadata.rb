maintainer       "RightScale, Inc."
maintainer_email "support@rightscale.com"
license          IO.read(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'LICENSE')))
description      "Amazon Web Services recipes and providers for Windows"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.1.7"


recipe "aws::default", "Install Amazon Web Services SDK for .NET"
recipe "aws::register_with_elb", "Register the instance with an Elastic Load Balancer created in the same ec2 region. Requires recipe: 'aws::default'"
recipe "aws::deregister_from_elb", "Deregister the instance with an Elastic Load Balancer created in the same ec2 region. Requires recipe: 'aws::default'"
recipe "aws::download", "Retrieves a file from an S3 bucket"
recipe "aws::upload", "Uploads a file to an S3 bucket"
recipe "aws::terminate_instance", "Terminates the current instance. Requires recipe: 'aws::default'"


attribute "aws/access_key_id",
  :display_name => "Access Key Id",
  :description => "This is an Amazon credential. Log in to your AWS account at aws.amazon.com to retrieve you access identifiers. Ex: 1JHQQ4KVEVM02KVEVM02",
  :recipes => ["aws::register_with_elb", "aws::deregister_from_elb", "aws::download", "aws::upload", "aws::terminate_instance"],
  :required => "required"
  
attribute "aws/secret_access_key",
  :display_name => "Secret Access Key",
  :description => "This is an Amazon credential. Log in to your AWS account at aws.amazon.com to retrieve your access identifiers. Ex: XVdxPgOM4auGcMlPz61IZGotpr9LzzI07tT8s2Ws",
  :recipes => ["aws::register_with_elb", "aws::deregister_from_elb", "aws::download", "aws::upload", "aws::terminate_instance"],
  :required => "required"
  
attribute "aws/elb_name",
  :display_name => "ELB Name",
  :description => "The name of the Elastic Load Balancer to register/deregister the instance with. (e.g., production-elb). The ELB needs to be created and configured prior to the execution of the recipe.",
  :recipes => ["aws::register_with_elb", "aws::deregister_from_elb"],
  :required => "required"

attribute "aws/file_path",
  :display_name => "File Path",
  :description => "The full path to the file to be uploaded. Ex: c:\\tmp\\my.txt",
  :recipes => ["aws::upload"],
  :required => "required"
  
attribute "s3/file",
  :display_name => "File",
  :description => "File to be retrieved from the s3 bucket. Ex: app.zip or dir/app.zip",
  :recipes => ["aws::download"],
  :required => "required"

attribute "s3/bucket",
  :display_name => "Bucket",
  :description => "The name of the S3 bucket",
  :recipes => ["aws::download", "aws::upload"],
  :required => "required"
  
attribute "aws/download_dir",
  :display_name => "Download Dir",
  :description => "The directory where the file from s3 will be downloaded. Ex: c:\\tmp\\",
  :recipes => ["aws::download"],
  :required => "required"
