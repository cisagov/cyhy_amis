# vdp_scanner #

An Ansible role for configuring a host to perform BOD 20-01 (Vulnerability
Disclosure Policy) scanning.

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
  become: true
  become_method: ansible.builtin.sudo
  roles:
     - vdp_scanner
```

## License ##

BSD

## Author Information ##

Nicholas McDonnell <nicholas.mcdonnell@gwe.cisa.dhs.gov>
