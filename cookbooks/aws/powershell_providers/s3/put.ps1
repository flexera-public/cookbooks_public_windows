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
$accessKeyID = Get-NewResource access_key_id
$secretAccessKey = Get-NewResource secret_access_key
$s3Bucket = Get-NewResource s3_bucket
$s3File = Get-NewResource s3_file
$filePath = Get-NewResource file_path
$timeoutSeconds = Get-NewResource timeout_seconds

#stop and fail script when a command fails
$ErrorActionPreference="Stop"

#check inputs.
$Error.Clear()
if (($s3Bucket -eq $NULL) -or ($s3Bucket -eq ""))
{
    Write-Error "***Error: provider requires 's3_bucket' parameter to be set!"
    exit 117
}
if (($filePath -eq $NULL) -or ($filePath -eq ""))
{
    Write-Error "***Error: provider requires 'file_path' parameter to be set!"
    exit 118
}
if (($accessKeyID -eq $NULL) -or ($accessKeyID -eq ""))
{
    Write-Error "***Error: provider requires 'access_key_id' parameter to be set!"
    exit 119
}
if (($secretAccessKey -eq $NULL) -or ($secretAccessKey -eq ""))
{
    Write-Error "***Error: provider requires 'secret_access_key' parameter to be set!"
    exit 120
}

$client=[Amazon.AWSClientFactory]::CreateAmazonS3Client($accessKeyID,$secretAccessKey)

$fileObject = [System.IO.FileInfo]$filePath

#if fileObject is a directory, uploading the latest file from the directory
if (test-path $fileObject.FullName -PathType Container)
{
    Write-Output("***["+$fileObject.FullName+"] is a directory, trying to find the latest file inside.")
    $latest_file=Get-ChildItem -force $fileObject.FullName | Where-Object { !($_.Attributes -match "Directory") } | Sort-Object LastWriteTime -descending | Select-Object Name, FullName | Select-Object -first 1
    if ($latest_file -eq $null)
    {
        Write-Error("***["+$fileObject.FullName+"] directory has no file, aborting...")
        exit 120
    }
    else
    {
        $fileObject=$latest_file
        Write-Output("***The latest file in ["+$fileObject.FullName+"] directory is ["+$fileObject.Name+"]")
    }
}


if (($s3File -eq $NULL) -or ($s3File -eq ""))
{
    $s3File = $fileObject.Name
}

Write-Output("***Uploading file["+$fileObject.Name+"] to bucket[$s3Bucket] as[$s3File]")

$request = New-Object -TypeName Amazon.S3.Model.PutObjectRequest
[void]$request.WithFilePath($fileObject.FullName)
[void]$request.WithBucketName($s3Bucket)
[void]$request.WithKey($s3File)

#NOTE: upload defaults to 20 minute timeout.
if ($timeoutSeconds -is [int])
{  
    #timeout is in miliseconds
    $request.timeout=1000*$timeoutSeconds
}

#If download fails it will throw an exception and $S3Response will be $null 
$S3Response = $client.PutObject($request)

if($S3Response -eq $null)
{ 
    Write-Error "ERROR: Amazon S3 put requrest failed. Aborting..." 
    exit 121
}
else
{
    Write-Output "***Upload successfully. AWS Response:"$S3Response
}