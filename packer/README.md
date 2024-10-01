# Cyber Hygiene Packer templates #

## AMIs ##

The following AMIs are available in this Packer template:

| Template name | Description |
| ------------- | ----------- |
| bastion | Provides a jump box to a private VPC. |
| dashboard | The Cyber Hygiene dashboard application. |
| docker | Runs Docker configurations to perform BOD 18-01 and 20-01 scanning as well as generate the DHS [code.gov](https://code.gov) inventory. |
| mongo | Provides the MongoDB database used by the Cyber Hygiene scanning system as well as running [cisagov/cyhy-commander]. |
| nessus | A Nessus scanner for the Cyber Hygiene scanning system (referred to as a `vulnscanner`). |
| nmap | An Nmap scanner for the Cyber Hygiene scanning system (referred to as a `portscanner`). |
| reporter | Runs the daily notification and weekly report generation using [cisagov/cyhy-reports] |

## Building ##

Build an AMI with:

```console
cd packer
ansible-galaxy install --role-file ansible/requirements.yml
packer init .
packer build -only amazon-ebs.<target AMI> .
```

Also note that

```console
ansible-galaxy install --force --role-file ansible/requirements.yml
```

will update the roles that are being pulled from external sources.  This
may be required, for example, if a role that is being pulled from a
GitHub repository has been updated and you want the new changes.  By
default `ansible-galaxy install` *will not* upgrade roles.

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
