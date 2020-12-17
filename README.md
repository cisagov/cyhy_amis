# NCATS AWS AMIs :dvd: #

[![GitHub Build Status](https://github.com/cisagov/cyhy_amis/workflows/build/badge.svg)](https://github.com/cisagov/cyhy_amis/actions)

## Building the AMIs ##
The AMIs are built like so:
```
ansible-galaxy install -r packer/ansible/requirements.yml
packer build packer/bastion.json
packer build packer/docker.json
packer build packer/mongo.json
packer build packer/nessus.json
packer build packer/nmap.json
AWS_MAX_ATTEMPTS=60 AWS_POLL_DELAY_SECONDS=60 packer build packer/reporter.json
AWS_MAX_ATTEMPTS=60 AWS_POLL_DELAY_SECONDS=60 packer build packer/dashboard.json
```

Note the environment variables in the `packer` command lines
corresponding to `feeds.json` and `reporter.json`.  They are present
because the AMIs produced by those lines are large and need extra time
to be copied, as discussed
[here](https://github.com/hashicorp/packer/issues/6536#issuecomment-407925535).

Also note that
```
ansible-galaxy install --force -r packer/ansible/requirements.yml
```
will update the roles that are being pulled from external sources.  This
may be required, for example, if a role that is being pulled from a
GitHub repository has been updated and you want the new changes.  By
default `ansible-galaxy install` _will not_ upgrade roles.

## Building the Terraform-based infrastructure ##
The Terraform-based infrastructure is built like so:
```
ansible-galaxy install -r ansible/requirements.yml
cd terraform
terraform workspace select <your_workspace>
./configure.py
terraform init
terraform apply -var-file=<your_workspace>.yml
```

Again, in some cases you may find it useful to add the `--force` flag
to the `ansible-galaxy` command.

## Tearing down the Terraform-based infrastructure ##
The Terraform-based infrastructure is torn down like so:
```
cd terraform
terraform workspace select <your_workspace>
./configure.py
terraform init
terraform destroy -var-file=<your_workspace>.yml
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
