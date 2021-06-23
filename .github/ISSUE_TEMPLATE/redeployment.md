---
name: Quarterly CyHy Environment Redeployment
about: Quarterly redeployment of the CyHy Environment
title: 202X-XX CyHy Environment Redeployment
labels: ''
assignees: mcdonnnj
---

## Procedure ##

Add the following to the [redeployments tracker](https://github.com/cisagov/cyhy_amis/issues/272):

```markdown
- [ ] [202X-XX](https://github.com/cisagov/cyhy_amis/issues/###)
```

Follow the [build and deploy instructions](https://github.com/cisagov/cyhy_amis#building-the-amis).

Check off each instance type as it is redeployed to track the overall status.
Once all instances have been redeployed and functionality has been confirmed,
close this issue and check off the entry on the [redeployments tracker](https://github.com/cisagov/cyhy_amis/issues/272).

## Status ##

- [ ] BOD
  - [ ] Bastion
  - [ ] Docker
- [ ] CyHy
  - [ ] Bastion
  - [ ] Dashboard
  - [ ] Database
  - [ ] Reporter
  - [ ] Scanners
    - [ ] Portscanners (nmap)
    - [ ] Vulnscanners (Nessus)
