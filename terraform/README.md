# Cyber Hygiene and BOD 18-01 Scanning Terraform Code for AWS ☁️ #

## Pre-requisites ##

In order to access certain AWS resources, the following AWS profiles must be
set up in your AWS credentials file:

* `cool-dns-route53resourcechange-cyber.dhs.gov`
* `cool-terraform-readstate`

The easiest way to set up those profiles is to use our
[`aws-profile-sync`](https://github.com/cisagov/aws-profile-sync) utility.
Follow the usage instructions in that repository before continuing with the
next steps.  Note that you will need to know where your team stores their
remote profile data in order to use
[`aws-profile-sync`](https://github.com/cisagov/aws-profile-sync).

## Building ##

Build Terraform-based infrastructure with:

```console
ansible-galaxy install -r ansible/requirements.yml
cd terraform
terraform workspace select <your_workspace>
./configure.py
terraform init
terraform apply -var-file=<your_workspace>.yml
```

Also note that

```console
ansible-galaxy install --force -r ansible/requirements.yml
```

will update the roles that are being pulled from external sources.  This
may be required, for example, if a role that is being pulled from a
GitHub repository has been updated and you want the new changes.  By
default `ansible-galaxy install` _will not_ upgrade roles.

## Destroying ##

Tear down Terraform-based infrastructure with:

```console
cd terraform
terraform workspace select <your_workspace>
./configure.py
terraform init
terraform destroy -var-file=<your_workspace>.yml
```

## `ssh` configuration for connecting to EC2 instances ##

You can use `ssh` to connect directly to the bastion EC2 instances in the
Cyber Hygiene and BOD VPCs:

```console
ssh bastion.<your_workspace>.cyhy
ssh bastion.<your_workspace>.bod
```

Other EC2 instances in these two VPCs can only be connected to by
proxying the `ssh` connection via the corresponding bastion host.
This can be done automatically by `ssh` if you add something like the
following to your `~/.ssh/config`:

```console
Host *.bod *.cyhy
     User <your_username>

Host bastion.*.bod bastion.*.cyhy
     HostName %h.cyber.dhs.gov

Host !bastion.*.bod *.bod !bastion.*.cyhy *.cyhy
     ProxyCommand ssh -W $(sed "s/^\([^.]*\)\..*$/\1/" <<< %h):22 $(sed s/^[^.]*/bastion/ <<< %h)
```

This `ssh` configuration snippet allows you to `ssh` directly to
`reporter.<your_workspace>.cyhy` or `docker.<your_workspace>.bod`,
for example:

```console
ssh reporter.<your_workspace>.cyhy
ssh docker.<your_workspace>.bod
```

## `ssh` port forwarding ##

You may also find it helpful to configure `ssh` to automatically
forward the Nessus UI and MongoDB ports when connecting to the Cyber
Hygiene VPC:

```console
Host bastion.*.cyhy
     LocalForward 8834 vulnscan1:8834
     LocalForward 8835 vulnscan2:8834
     LocalForward 0.0.0.0:27017 database1:27017
```

Note that the last `LocalForward` line forwards port 27017 *on any
interface* to port 27017 on the MongoDB instance.  This allows any
local Docker containers to take advantage of the port forwarding.

## Creating the management VPC ##

To create the management VPC, first modify your Terraform variables file
(`<your_workspace>.yml`) such that:

```console
enable_mgmt_vpc = true
```

If you want to include one or more Nessus instances in your management VPC,
ensure that the correct license keys are entered in your Terraform variables
file:

```console
mgmt_nessus_activation_codes = [ "LICENSE-KEY-1", "LICENSE-KEY-2" ]
```

Next, update `configure.py` to include a single management bastion instance and
if desired, one or more Nessus instances in your workspace.  In the example
below, there is one Nessus instance:

```console
WORKSPACE_CONFIGS = {
    "your-workspace": {
        "nmap": 1,
        "nessus": 1,
        "mongo": 1,
        "mgmt_bastion": 1,
        "mgmt_nessus": 1
      }
```

Note that the number of `nmap`, `nessus`, and `mongo` instances listed above
have no bearing on the creation of the management VPC.  They are simply listed
to show the complete workspace configuration block.

After `configure.py` has been updated, run it to re-configure your Terraform
environment:

```console
./configure.py
```

Next, re-initialize your reconfigured Terraform environment (it's also a good
idea to add the optional `--upgrade=true` parameter):

```console
terraform init
```

At this point, you are ready to create all of the management VPC infrastructure
by running:

```console
terraform apply -var-file=<your_workspace>.yml
```

## Destroying the management VPC ##

To destroy the management VPC, first modify your Terraform variables file
(`<your_workspace>.yml`) such that:

```console
enable_mgmt_vpc = false
```

Next, update `configure.py` to remove the management bastion and any Nessus
instances from your workspace (i.e. set them to zero):

```console
WORKSPACE_CONFIGS = {
    "your-workspace": {
        "nmap": 1,
        "nessus": 1,
        "mongo": 1,
        "mgmt_bastion": 0,
        "mgmt_nessus": 0
      }
```

Note that the number of `nmap`, `nessus`, and `mongo` instances listed above
have no bearing on the destruction of the management VPC.  They are simply
listed to show the complete workspace configuration block.

After `configure.py` has been updated, run it to re-configure your Terraform
environment:

```console
./configure.py
```

Next, re-initialize your reconfigured Terraform environment (it's also a good
idea to add the optional `--upgrade=true` parameter):

```console
terraform init
```

At this point, you are ready to destroy all of the management VPC
infrastructure by running:

```console
terraform apply -var-file=<your_workspace>.yml
```

## License ##

This project is in the worldwide [public domain](LICENSE.md).

This project is in the public domain within the United States, and
copyright and related rights in the work worldwide are waived through
the [CC0 1.0 Universal public domain
dedication](https://creativecommons.org/publicdomain/zero/1.0/).

All contributions to this project will be released under the CC0
dedication. By submitting a pull request, you are agreeing to comply
with this waiver of copyright interest.
