---
name: Monthly CyHy Environment Redeploy
about: Monthly redeploy of the CyHy Environment
title: 202X-XX Redeploy CyHy Environment
labels: ''
assignees: mcdonnnj

---

## Procedure ##

Add the following to the [`Redeployments` tracker](https://github.com/cisagov/cyhy_amis/issues/272)

```
- [ ] [202X-XX](https://github.com/cisagov/cyhy_amis/issues/###)
```

Follow the [build and deploy instructions](https://github.com/cisagov/cyhy_amis#building-the-amis).

Check off each service as it is redeployed to track the overall status. Once all services have been redeployed and functionality confirmed, close this issue and check off the month on the [`Redeployments` tracker](https://github.com/cisagov/cyhy_amis/issues/272).

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
