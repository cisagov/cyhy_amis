cyhy_logrotate
==============

A role for configuring logrotate for cyhy logs.

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

    - hosts: cyhy
      become: yes
      become_method: sudo
      roles:
         - cyhy_logrotate

License
-------

BSD

Author Information
------------------

Shane Frasier <jeremy.frasier@beta.dhs.gov>
