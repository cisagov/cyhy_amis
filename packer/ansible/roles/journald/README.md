journald
========

A role for configuring journald to persist logs across reboots.

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

    - hosts: all
      become: yes
      become_method: sudo
      roles:
         - journald

License
-------

BSD

Author Information
------------------

Shane Frasier <jeremy.frasier@beta.dhs.gov>
