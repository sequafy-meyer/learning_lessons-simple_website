# Various files
## List of content
|File name| Purpose|
|----|-----|
|functions.php|Several php functions for the simple website|
|index.php|Index files for the simple website|
|webserver.pkr.hcl|Packer file for the creation of the [AWS AMI](https://docs.aws.amazon.com/de_de/AWSEC2/latest/UserGuide/AMIs.html) needed for the webserver instances. Further information about the creation of the AMI can be found in the [Packer section](##Packer).|
## Packer
Packer is a free tool to automate build of machine images. Further information can be found on the official [website](https://www.packer.io/).\
The AMI can be build by following command:\
`packer build webserver.pkr.hcl`
