# How to Redeploy All Instances #

Except when otherwise indicated, all commands listed below assume that
the current working directory is `cyhy_amis/terraform`.

- Force install all `ansible` and `packer/ansible` requirements:

  ```console
  ansible-galaxy install --force --role-file ../ansible/requirements.yml
  ansible-galaxy install --force --role-file ../packer/ansible/requirements.yml
  ```

- If any Nessus keys are being re-used, reset them via the
  [Tenable Support Portal](https://support.tenable.com)

- Notify all affected parties that downtime is starting

- ssh to the `database1` instance and stop the `cyhy-commander` service:

  ```console
  sudo systemctl stop cyhy-commander.service
  ```

- Terminate all EC2 instances through the
  [AWS Console](https://aws.amazon.com/console/)

- Select the appropriate Production workspace:

  ```console
  terraform workspace select <PRODUCTION-WORKSPACE-NAME>
  ```

- Make sure you have the latest version of the Production Terraform variables
  file

- Review the Production Terraform variables file to ensure it is correct

- Terraform the Production environment

  ```console
  terraform apply -var-file=<PRODUCTION-WORKSPACE-NAME>.tfvars
  ```

- Update the stored Production Terraform variables file (only necessary if you
  modified the file)

- ssh to the `database1` instance and verify that the `cyhy-commander`
  service started up and is running as expected:

  ```console
  systemctl status cyhy-commander.service
  tail -f /var/log/cyhy/commander.log
  ```

- If code changes were deployed, verify that they are working as expected
