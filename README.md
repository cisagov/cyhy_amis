# NCATS AWS AMIs :dvd: #

Build AMIs with:
```
ansible-galaxy install -r packer/ansible/requirements.yml
packer build packer/nmap.json
packer build packer/nessus.json
packer build packer/mongo.json
packer build packer/bastion.json
packer build packer/docker.json
packer build packer/commander.json
```

Build Terraform-based infrastructure with:
```
cd terraform
terraform workspace select <your_workspace>
terraform apply -vars-file=<your_workspace>.yml
```

Tear down Terraform-based infrastructure with:
```
cd terraform
terraform workspace select <your_workspace>
terraform destroy -vars-file=<your_workspace>.yml
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
