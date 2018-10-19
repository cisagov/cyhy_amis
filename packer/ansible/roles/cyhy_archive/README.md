cyhy_archive
============

A role for installing cyhy-archive.

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

    - hosts: archivers
      become: yes
      become_method: sudo
      roles:
        - github_oauth
        - cyhy_archive

License
-------

BSD

Author Information
------------------

David Redmin <david.redmin@beta.dhs.gov>
