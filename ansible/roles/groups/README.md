# groups #

An Ansible role for adding users to groups after now that cloud-init
has run.

## Requirements ##

None

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
     - groups
```

## License ##

BSD

## Author Information ##

Shane Frasier <jeremy.frasier@beta.dhs.gov>
