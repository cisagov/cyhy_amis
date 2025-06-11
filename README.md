# CISA Cyber Hygiene (CyHy) AWS AMIs 📀 #

[![GitHub Build Status](https://github.com/cisagov/cyhy_amis/workflows/build/badge.svg)](https://github.com/cisagov/cyhy_amis/actions)
[![CodeQL](https://github.com/cisagov/cyhy_amis/workflows/CodeQL/badge.svg)](https://github.com/cisagov/cyhy_amis/actions/workflows/codeql-analysis.yml)

## Building the AMIs ##

Instructions for building the AMIs defined in this project can be found in the
[Packer template's README](packer/README.md).

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
