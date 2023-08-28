# code_gov_update #

An Ansible role for configuring a host to generate updated code.gov
JSON files and email them.

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
  become_method: ansible.builtin.sudo
  roles:
     - code_gov_update
```

## License ##

BSD

## Author Information ##

Shane Frasier <jeremy.frasier@gwe.cisa.dhs.gov>
