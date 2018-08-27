htop
====

A role for installing htop.

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

    - hosts: htop
      become: yes
      become_method: sudo
      roles:
         - htop

License
-------

BSD

Author Information
------------------

Shane Frasier <jeremy.frasier@beta.dhs.gov>
