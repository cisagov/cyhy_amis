chown_cyhy_dirs
===============

An Ansible role for chowning the CyHy directories for cyhy-runner and
cyhy-commander hosts.

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

    - hosts: cyhy
      become: yes
      become_method: sudo
      roles:
        - chown_cyhy_dirs

License
-------

BSD

Author Information
------------------

Shane Frasier <jeremy.frasier@beta.dhs.gov>
