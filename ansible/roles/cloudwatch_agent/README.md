# cloudwatch_agent #

An Ansible role for creating (or replacing) the AWS CloudWatch Agent
configuration file.

## Requirements ##

This role assumes that the AWS CloudWatch Agent is already installed on the target
instance. In this environment that would typically have been done at Amazon Machine
Image (AMI) build time with the [cisagov/ansible-role-cloudwatch-agent](https://github.com/cisagov/ansible-role-cloudwatch-agent)
role.

## Role Variables ##

None

## Dependencies ##

None

## Example Playbook ##

Here's how to use it in a playbook:

```yaml
- hosts: all
  become: yes
  become_method: sudo
  roles:
     - cloudwatch_agent
```

## License ##

BSD

## Author Information ##

Nicholas McDonnell <nicholas.mcdonnell@gwe.cisa.dhs.gov>
