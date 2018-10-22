cyhy_runner
===========

A role for installing cyhy-runner.

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

    - hosts: runners
      become: yes
      become_method: sudo
      roles:
        - github_oauth
        - cyhy_runner

License
-------

BSD

Author Information
------------------

Shane Frasier <jeremy.frasier@beta.dhs.gov>
