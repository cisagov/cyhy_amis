cyhy_ops
========

A role for adding the cyhy_ops user.

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

    - hosts: db
      become: yes
      become_method: sudo
      roles:
         - cyhy_ops

License
-------

BSD

Author Information
------------------

Shane Frasier <jeremy.frasier@beta.dhs.gov>
