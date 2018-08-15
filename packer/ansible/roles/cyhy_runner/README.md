cyhy_runner
===========

A role for installing and cyhy-runner.

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

    - hosts: cyhy_runner
      become: yes
      become_method: sudo
      roles:
         - cyhy_runner

License
-------

BSD

Author Information
------------------

Shane Frasier <jeremy.frasier@beta.dhs.gov>
