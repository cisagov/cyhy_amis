github_oauth
============

A role for retrieving the GitHub OAuth token and making it available
to ansible as the variable github_oauth_token.  This token is needed
to check out some repositories that are currently private.

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
         - github_oauth

License
-------

BSD

Author Information
------------------

Shane Frasier <jeremy.frasier@beta.dhs.gov>
