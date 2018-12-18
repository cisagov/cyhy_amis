Role Name
=========

A role for install cyhy_dashboard

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

     - hosts: cyhy_dashboard
       become: yes
       become_method: sudo
       roles:
        - cyhy_dashboard
License
-------

BSD

Author Information
------------------

Kyle Evers <kyle.evers@beta.dhs.gov>
