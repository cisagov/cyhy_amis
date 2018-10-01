nvme
====

A role for installing tools to deal with NVMe (Non-volatile memory
express) devices.

Requirements
------------

None

Role Variables
--------------

None

Dependencies
------------

None

Example Playbook
----------------

Here's how to use it in a playbook:

    - hosts: nvme-hosts
      become: yes
      become_method: sudo
      roles:
         - nvme

License
-------

BSD

Author Information
------------------

Shane Frasier <jeremy.frasier@beta.dhs.gov>
