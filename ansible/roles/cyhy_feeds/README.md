# cyhy_feeds #

A role for installing and configuring cyhy_feeds instance.

## Requirements ##

None

## Role Variables ##

None

## Dependencies ##

None

## Example Playbook ##

Here's how to use it in a playbook:

```yaml
- hosts: cyhy_feeds
  become: yes
  become_method: ansible.builtin.sudo
  roles:
     - cyhy_feeds
```

## License ##

BSD

## Author Information ##

Kyle Evers <kyle.evers@gwe.cisa.dhs.gov>
