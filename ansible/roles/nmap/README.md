nmap
=========

A role for installing and configuring NMAP servers.

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

    - hosts: nmap
      become: yes
      become_method: sudo
      roles:
         - nmap

License
-------

BSD

Author Information
------------------

Shane Frasier <jeremy.frasier@beta.dhs.gov>
