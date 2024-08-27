# cyhy_dashboard #

A role for configuring cyhy-dashboard hosts.

## Requirements ##

None

## Role Variables ##

None

## Dependencies ##

None

## Example Playbook ##

Here's how to use it in a playbook:

```yaml
- hosts: dashboards
  become: true
  become_method: ansible.builtin.sudo
  roles:
     - cyhy_dashboard
```

## License ##

BSD

## Author Information ##

Kyle Evers <kyle.evers@gwe.cisa.dhs.gov>
