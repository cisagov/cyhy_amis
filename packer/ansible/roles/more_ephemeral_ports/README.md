more_ephemeral_ports
====================

A role for setting the ephemeral port range to 1024-65535.

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

    - hosts: scanners
      become: yes
      become_method: sudo
      roles:
         - more_ephemeral_ports

License
-------

BSD

Author Information
------------------

Shane Frasier <jeremy.frasier@beta.dhs.gov>
