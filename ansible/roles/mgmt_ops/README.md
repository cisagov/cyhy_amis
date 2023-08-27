# mgmt_ops #

A role for adding the mgmt_ops user.

## Requirements ##

None

## Role Variables ##

None

## Dependencies ##

None

## Example Playbook ##

Here's how to use it in a playbook:

```yaml
- hosts: db
  become: yes
  become_method: ansible.builtin.sudo
  roles:
     - mgmt_ops
```

## License ##

BSD

## Author Information ##

David Redmin <david.redmin@gwe.cisa.dhs.gov>
