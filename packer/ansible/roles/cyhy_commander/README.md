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

None

Example Playbook
----------------

Here's how to use it in a playbook:

     - hosts: cyhy_commander
      become: yes
      become_method: sudo
      roles:
         - cyhy_commander
License
-------

BSD

Author Information
------------------

Kyle Evers <kyle.evers@beta.dhs.gov>
