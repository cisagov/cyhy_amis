# nessus #

A role for configuring Nessus hosts.

## Requirements ##

None

## Role Variables ##

None

## Dependencies ##

None

## Example Playbook ##

Here's how to use it in a playbook:

```yaml
- hosts: nessus
  become: true
  become_method: ansible.builtin.sudo
  roles:
     - nessus
```

## License ##

BSD

## Author Information ##

Shane Frasier <jeremy.frasier@gwe.cisa.dhs.gov>
