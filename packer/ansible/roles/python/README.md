python
=========

A role for installing python.

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

    - hosts: python
      become: yes
      become_method: sudo
      roles:
         - python

License
-------

BSD

Author Information
------------------

Shane Frasier <jeremy.frasier@beta.dhs.gov>
