cyhy_reporter
=============

A role for installing cyhy-reports.

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

    - hosts: reporters
      become: yes
      become_method: sudo
      roles:
         - cyhy_reporter

License
-------

BSD

Author Information
------------------

Shane Frasier <jeremy.frasier@beta.dhs.gov>
