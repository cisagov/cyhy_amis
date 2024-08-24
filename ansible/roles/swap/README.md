# swap #

Enables swap on a machine.

## Requirements ##

None

## Role Variables ##

- `swapfile_size` [default: `2GiB`]: the swapfile size specified for `fallocate`
- `swapfile_location` [default: `/swapfile`]: the location of of the swap file

## Dependencies ##

None

## Example Playbook ##

```yaml
- hosts: nmap
  name: Configure nmap scanning hosts
  become: true
  become_method: ansible.builtin.sudo
  roles:
    - { role: swap, swapfile_size: 2GiB}
```
