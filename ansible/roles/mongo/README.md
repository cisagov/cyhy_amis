# mongo #

A role for installing and configuring MongoDB servers.

## Requirements ##

None

## Role Variables ##

None

## Dependencies ##

None

## Example Playbook ##

Here's how to use it in a playbook:

```yaml
- hosts: mongo
  become: true
  become_method: ansible.builtin.sudo
  roles:
     - mongo
```

## License ##

BSD

## Author Information ##

Shane Frasier <jeremy.frasier@gwe.cisa.dhs.gov>
