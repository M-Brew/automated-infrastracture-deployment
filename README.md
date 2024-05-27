# automated-infrastracture-deployment
Using Terraform to automate the deployment of a simple infrastructure in AWS, including a VPC, subnets, security groups and EC2 instances.


Steps

1. Create VPC
2. Create Internet Gateway
3. Create custom Route Table
4. Create a Subnet
5. Associate Subnet with Route Table
6. Create Security Group to allow ports 22, 80 and 443
7. Create a Network Interface with an IP in the Subnet that was created in Step 4
8. Assign an Elastic IP to the Network Interface that was created in Step 7
9. Create Ubuntu server and install Nginx


Create a terraform.tfvars and populate the following variables:
region            = ""
availability_zone = ""
key_name          = ""
aws_access_key    = ""
aws_secret_key    = ""

Initialize terraform with the command: terraform init
Validate code syntax with: terraform validate
Create infrastructure with: terraform apply