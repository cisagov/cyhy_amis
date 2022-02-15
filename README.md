# NCATS AWS AMIs 📀 #

[![GitHub Build Status](https://github.com/cisagov/cyhy_amis/workflows/build/badge.svg)](https://github.com/cisagov/cyhy_amis/actions)

## Building the AMIs ##

The AMIs are built like so:

```console
cd packer
ansible-galaxy install --role-file ansible/requirements.yml
packer build bastion.json
packer build dashboard.json
packer build docker.json
packer build mongo.json
packer build nessus.json
packer build nmap.json
packer build reporter.json
```

Also note that

```console
ansible-galaxy install --force --role-file ansible/requirements.yml
```

will update the roles that are being pulled from external sources.  This
may be required, for example, if a role that is being pulled from a
GitHub repository has been updated and you want the new changes.  By
default `ansible-galaxy install` _will not_ upgrade roles.

## Building the Terraform-based infrastructure ##

The Terraform-based infrastructure is built like so:

```console
ansible-galaxy install --role-file ansible/requirements.yml
cd terraform
terraform workspace select <your_workspace>
terraform init
terraform apply -var-file=<your_workspace>.tfvars
```

Again, in some cases you may find it useful to add the `--force` flag
to the `ansible-galaxy` command.

## Tearing down the Terraform-based infrastructure ##

The Terraform-based infrastructure is torn down like so:

```console
cd terraform
terraform workspace select <your_workspace>
terraform init
terraform destroy -var-file=<your_workspace>.tfvars
```

## Contributing ##

We welcome contributions!  Please see [`CONTRIBUTING.md`](CONTRIBUTING.md) for
details.

## License ##

This project is in the worldwide [public domain](LICENSE).

This project is in the public domain within the United States, and
copyright and related rights in the work worldwide are waived through
the [CC0 1.0 Universal public domain
dedication](https://creativecommons.org/publicdomain/zero/1.0/).

All contributions to this project will be released under the CC0
dedication. By submitting a pull request, you are agreeing to comply
with this waiver of copyright interest.
