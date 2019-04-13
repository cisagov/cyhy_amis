client_cert_update
==================

An Ansible role for configuring a host to generate a list of the BOD
18-01 web hosts that require authentication via client certificates
and email it out.

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
         - client_cert_update

License
-------

BSD

Author Information
------------------

Shane Frasier <jeremy.frasier@trio.dhs.gov>
