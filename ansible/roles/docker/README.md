docker
=========

A role for installing Docker.

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

    - hosts: docker
      become: yes
      become_method: sudo
      roles:
         - docker

License
-------

BSD

Author Information
------------------

Shane Frasier <jeremy.frasier@beta.dhs.gov>
