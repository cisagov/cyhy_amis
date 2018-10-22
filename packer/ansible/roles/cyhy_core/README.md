cyhy_core
=========

A role for installing cyhy-core.

Requirements
------------

None

Role Variables
--------------

None

Dependencies
------------

- github_oauth

Example Playbook
----------------

Here's how to use it in a playbook:

    - hosts: reporters
      become: yes
      become_method: sudo
      roles:
        - github_oauth
        - cyhy_core

License
-------

BSD

Author Information
------------------

Shane Frasier <jeremy.frasier@beta.dhs.gov>
