# How to Redeploy All Instances #

Except when otherwise indicated, all commands listed below assume that
the current working directory is `cyhy_amis/terraform`.

* Force install all `ansible` and `packer/ansible` requirements:
```bash
ansible-galaxy install --force -r ../ansible/requirements.yml
ansible-galaxy install --force -r ../packer/ansible/requirements.yml
```

* If any Nessus keys are being re-used, reset them via the
[Tenable Support Portal](https://support.tenable.com)

* Notify all affected parties that downtime is starting

* ssh to the `database1` instance and stop the `cyhy-commander` service:
```bash
sudo systemctl stop cyhy-commander.service
```

* Terminate all EC2 instances through the
[AWS Console](https://aws.amazon.com/console/)

* Select the appropriate Production workspace:
```bash
terraform workspace select <PRODUCTION-WORKSPACE-NAME>
```

* Configure the terraform environment:
```bash
./configure
```

* Fetch the latest version of the Production terraform variables file:
```bash
./scripts/fetch_production_tfvars.sh
```

* Review the Production terraform variables file to ensure it is correct

* Terraform the Production environment
```bash
terraform apply -var-file=<PRODUCTION-VARIABLES-FILE>
```

* Push the Production terraform variables file (only necessary if you
modified the file):
```bash
./scripts/push_production_tfvars.sh
```

* ssh to the `database1` instance and verify that the `cyhy-commander`
service started up and is running as expected:
```bash
systemctl status cyhy-commander.service
tail -f /var/log/cyhy/commander.log
```

* If code changes were deployed, verify that they are working as expected
