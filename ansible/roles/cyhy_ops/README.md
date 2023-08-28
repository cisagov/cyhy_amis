# cyhy_ops #

A role for adding the cyhy_ops user.

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
     - cyhy_ops
```

## License ##

BSD

## Author Information ##

Shane Frasier <jeremy.frasier@gwe.cisa.dhs.gov>
