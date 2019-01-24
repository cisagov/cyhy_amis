nmap
=========

A role for installing and configuring Nessus servers.

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

    - hosts: nessus
      become: yes
      become_method: sudo
      roles:
         - nessus

License
-------

BSD

Author Information
------------------

David Redmin <david.redmin@trio.dhs.gov>
