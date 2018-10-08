orchestrator
============

An Ansible role for configuring a host to perform BOD 18-01 (HTTPS and
Trustworthy Email) scanning and reporting.

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

    - hosts: bod_docker
      become: yes
      become_method: sudo
      roles:
         - orchestrator

License
-------

BSD

Author Information
------------------

Shane Frasier <jeremy.frasier@beta.dhs.gov>
