# Cyber Hygiene and BOD 18-01 Scanning Terraform Code for AWS :cloud: #

## Building ##

Build Terraform-based infrastructure with:
```
cd terraform
terraform workspace select <your_workspace>
./configure.py
terraform init
terraform apply -var-file=<your_workspace>.yml
```

## Destroying ##

Tear down Terraform-based infrastructure with:
```
cd terraform
terraform workspace select <your_workspace>
./configure.py
terraform init
terraform destroy -var-file=<your_workspace>.yml
```

## `ssh` configuration for connecting to EC2 instances ##

You can use `ssh` to connect directly to the bastion EC2 instances in the
Cyber Hygiene and BOD VPCs:
```
ssh bastion.<your_workspace>.cyhy
ssh bastion.<your_workspace>.bod
```

Other EC2 instances in these two VPCs can only be connected to by
proxying the `ssh` connection via the corresponding bastion host.
This can be done automatically by `ssh` if you add something like the
following to your `~/.ssh/config`:
```
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
```
ssh reporter.<your_workspace>.cyhy
ssh docker.<your_workspace>.bod
```

## `ssh` port forwarding ##

You may also find it helpful to configure `ssh` to automatically
forward the Nessus UI and MongoDB ports when connecting to the Cyber
Hygiene VPC:
```
Host bastion.*.cyhy
     LocalForward 8834 vulnscan1:8834
     LocalForward 8835 vulnscan2:8834
     LocalForward 0.0.0.0:27017 database1:27017
```

Note that the last `LocalForward` line forwards port 27017 *on any
interface* to port 27017 on the MongoDB instance.  This allows any
local Docker containers to take advantage of the port forwarding.

## License ##

This project is in the worldwide [public domain](LICENSE.md).

This project is in the public domain within the United States, and
copyright and related rights in the work worldwide are waived through
the [CC0 1.0 Universal public domain
dedication](https://creativecommons.org/publicdomain/zero/1.0/).

All contributions to this project will be released under the CC0
dedication. By submitting a pull request, you are agreeing to comply
with this waiver of copyright interest.
