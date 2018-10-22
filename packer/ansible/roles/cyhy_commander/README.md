Role Name
=========

A role for install cyhy_commander

Requirements
------------

None

Role Variables
--------------

None

Dependencies
------------

- github_oauth
- cyhy_core

Example Playbook
----------------

Here's how to use it in a playbook:

     - hosts: cyhy_commander
       become: yes
       become_method: sudo
       roles:
         - github_oauth
         - cyhy_core
         - cyhy_commander
License
-------

BSD

Author Information
------------------

Kyle Evers <kyle.evers@beta.dhs.gov>
