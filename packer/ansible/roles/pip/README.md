pip
===

A role for installing pip on Debian and Amazon Linux.

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

    - hosts: pip
      become: yes
      become_method: sudo
      roles:
         - pip

License
-------

BSD

Author Information
------------------

Shane Frasier <jeremy.frasier@beta.dhs.gov>
