# IBM NextGen Cloud VSI (virtual machine) example with public SSH access

This example creates a virtual machine (VM) in the IBM Cloud and makes it
externally available (read: publicly accessible) via SSH. Once the VM is
done being created, its public IP address will be displayed for easy access.
By default, an Ubuntu VM will be created, but this can be changed by updating
the Terraform variables (see below) to point to a different image.

More specifically, it creates the following resources:

* a VPC
* a subnet
* a VM within the VPC and a particular region and availability zone (AZ)
* a floating IP (FIP) address on the public Internet
* a security group that allows ingress traffic on port 22 (for SSH)

To run the example, you will need to:

1. Clone this Git repository
2. [Download and configure](https://github.com/IBM-Cloud/terraform-provider-ibm) the IBM Cloud Terraform provider (0.17.3 or later)
3. Obtain your [IBM Cloud API key](https://cloud.ibm.com) (needed for step #5)
4. [Upload your public SSH key](https://cloud.ibm.com/vpc/compute/sshKeys) to IBM Cloud (the ID is needed for step #5)
5. Update the variables.tfvars file to suit your needs

Next, you can run the example by invoking...

The planning phase (validates the Terraform configuration)

```shell
. ./setup.sh (only needed to run against the NextGen Beta environment)
terraform init
terraform plan -var-file=variables.tfvars
```

The apply phase (provisions the infrastructure)

```shell
terraform apply -var-file=variables.tfvars
```

The destroy phase (deletes the infrastructure)

```shell
terraform destroy -var-file=variables.tfvars
```
