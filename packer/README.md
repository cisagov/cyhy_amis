# Cyber Hygiene Packer template #

## Amazon Machine Images (AMIs) ##

The following AMIs are available in this Packer template:

| AMI name | Description | x86_64 | arm64 |
| -------- | ----------- | ------ | ----- |
| bastion | Provides a jump box to a private VPC. | ✔ | ✔ |
| dashboard | The Cyber Hygiene dashboard application. | ✔ | ❌ |
| docker | Runs Docker configurations to perform BOD 18-01 and 20-01 scanning as well as generate the DHS [code.gov](https://code.gov) inventory. | ✔ | ❌ |
| mongo | Provides the MongoDB database used by the Cyber Hygiene scanning system as well as running [cisagov/cyhy-commander]. | ✔ | ❌ |
| nessus | A Nessus scanner for the Cyber Hygiene scanning system (referred to as a `vulnscanner`). | ✔ | ❌ |
| nmap | An Nmap scanner for the Cyber Hygiene scanning system (referred to as a `portscanner`). | ✔ | ✔ |
| reporter | Runs the daily notification and weekly report generation using [cisagov/cyhy-reports]. | ✔ | ❌ |

## Building the AMIs ##

> [!NOTE]
> Ansible requirements should be installed automatically when you build an image.

Initialize the Packer template:

```console
cd packer
packer init .
```

Once that is completed you can build a specific AMI:

```console
packer build -only amazon-ebs.<target AMI>_<target architecture> .
```

or you can build all of the AMIs in the template:

```console
packer build .
```

If building a non-default AMI (e.g., for testing), the prefix for the
created AMI can be changed from the default value of `cyhy` like so:

```console
packer build -var ami_prefix=testing -only amazon-ebs.bastion_x86_64 .
```

You can also use a `.pkrvars.hcl` file to set any variables.  For example:

```hcl
ami_prefix = "testing"
```

Also note that if you need to update the Ansible roles that are used by the
Packer template, you can adjust the `force_install_ansible_requirements` and
`force_install_ansible_requirements_with_dependencies` variables in the same
manner as the `ami_prefix` variable above. This may be required, for example,
if a role that is being pulled from a GitHub repository has been updated and
you want the new changes. This will not occur by default when you build an AMI.

<!-- BEGIN_TF_DOCS -->
## Requirements ##

No requirements.

## Providers ##

| Name | Version |
| ---- | ------- |
| amazon-ami | n/a |
| amazon-parameterstore | n/a |

## Modules ##

No modules.

## Resources ##

| Name | Type |
| ---- | ---- |
| [amazon-ami_amazon-ami.debian_bookworm_arm64](https://registry.terraform.io/providers/hashicorp/amazon-ami/latest/docs/data-sources/amazon-ami) | data source |
| [amazon-ami_amazon-ami.debian_bookworm_x86_64](https://registry.terraform.io/providers/hashicorp/amazon-ami/latest/docs/data-sources/amazon-ami) | data source |
| [amazon-ami_amazon-ami.debian_buster_x86_64](https://registry.terraform.io/providers/hashicorp/amazon-ami/latest/docs/data-sources/amazon-ami) | data source |
| [amazon-ami_amazon-ami.debian_trixie_arm64](https://registry.terraform.io/providers/hashicorp/amazon-ami/latest/docs/data-sources/amazon-ami) | data source |
| [amazon-ami_amazon-ami.debian_trixie_x86_64](https://registry.terraform.io/providers/hashicorp/amazon-ami/latest/docs/data-sources/amazon-ami) | data source |
| [amazon-parameterstore_amazon-parameterstore.maxmind_account_id](https://registry.terraform.io/providers/hashicorp/amazon-parameterstore/latest/docs/data-sources/amazon-parameterstore) | data source |
| [amazon-parameterstore_amazon-parameterstore.maxmind_license_key](https://registry.terraform.io/providers/hashicorp/amazon-parameterstore/latest/docs/data-sources/amazon-parameterstore) | data source |

## Inputs ##

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| ami\_prefix | The prefix to use for the names of AMIs created. | `string` | `"cyhy"` | no |
| ami\_regions | The list of AWS regions to copy the AMI to once it has been created. Example: ["us-east-1"] | `list(string)` | ```[ "us-east-1", "us-west-1", "us-west-2" ]``` | no |
| build\_region | The region in which to retrieve the base AMI from and build the new AMI. | `string` | `"us-east-2"` | no |
| cyhy\_user\_information | The user information for the Cyber Hygiene user. | ```object({ home_directory = string ssh_public_key = string user_id = string username = string })``` | ```{ "home_directory": "/var/cyhy", "ssh_public_key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOreUDnms12MPI0gh7K+YGaESYgC2TY1zA+kSK/g+n5+ cyhy", "user_id": "2048", "username": "cyhy" }``` | no |
| force\_install\_ansible\_requirements | Indicate if the Ansible requirements should be force installed. | `bool` | `false` | no |
| force\_install\_ansible\_requirements\_with\_dependencies | Indicate if the Ansible requirements *and* their dependencies should be force installed. | `bool` | `false` | no |
| is\_prerelease | The pre-release status to use for the tags applied to the created AMI. | `bool` | `false` | no |
| maxmind\_ssm\_parameter\_names | The SSM parameter store names that contain the MaxMind account ID and license key. | ```object({ account_id = string license_key = string })``` | ```{ "account_id": "/cyhy/core/geoip/account_id", "license_key": "/cyhy/core/geoip/license_key" }``` | no |

## Outputs ##

No outputs.
<!-- END_TF_DOCS -->

## License ##

This project is in the worldwide [public domain](LICENSE.md).

This project is in the public domain within the United States, and
copyright and related rights in the work worldwide are waived through
the [CC0 1.0 Universal public domain
dedication](https://creativecommons.org/publicdomain/zero/1.0/).

All contributions to this project will be released under the CC0
dedication. By submitting a pull request, you are agreeing to comply
with this waiver of copyright interest.

[cisagov/cyhy-commander]: https://github.com/cisagov/cyhy-commander
[cisagov/cyhy-reports]: https://github.com/cisagov/cyhy-reports
