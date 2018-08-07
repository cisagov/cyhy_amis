xfs
=========

Role for installing xfsprogs.

Requirements
------------

None.

Role Variables
--------------

None.

Dependencies
------------

None.

Example Playbook
----------------

Here's how to use it in a playbook:

    - hosts: xfs
      become: yes
      become_method: sudo
      roles:
         - xfs

License
-------

BSD

Author Information
------------------

Shane Frasier <jeremy.frasier@beta.dhs.gov>
