cyhy_feeds
=====

A role for installing and configuring cyhy_feeds servers.

Requirements
------------

None

Role Variables
--------------

None

Dependencies
------------

- github_oauth
- cyhy_core

Example Playbook
----------------

Here's how to use it in a playbook:

    - hosts: cyhy_feeds
      become: yes
      become_method: sudo
      roles:
        - github_oauth
        - cyhy_core
        - cyhy_feeds

License
-------

BSD

Author Information
------------------

Kyle Evers <kyle.evers@beta.dhs.gov>