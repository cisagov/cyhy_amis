# cyhy_commander #

A role for configuring cyhy-commander hosts.

## Requirements ##

None

## Role Variables ##

None

## Dependencies ##

None

## Example Playbook ##

Here's how to use it in a playbook:

```yaml
- hosts: commanders
  become: yes
  become_method: ansible.builtin.sudo
  roles:
     - cyhy_commander
```

## License ##

BSD

## Author Information ##

Kyle Evers <kyle.evers@beta.dhs.gov>
