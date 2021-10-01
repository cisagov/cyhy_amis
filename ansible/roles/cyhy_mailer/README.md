# cyhy_mailer #

An Ansible role for configuring a host to perform emailing of Cyber
Hygiene or BOD 18-01 reports.

## Requirements ##

None

## Role Variables ##

None

## Dependencies ##

None

## Example Playbook ##

Here's how to use it in a playbook:

```yaml
- hosts: bod_docker
  become: yes
  become_method: sudo
  roles:
     - cyhy_mailer
```

## License ##

BSD

## Author Information ##

Shane Frasier <jeremy.frasier@beta.dhs.gov>
