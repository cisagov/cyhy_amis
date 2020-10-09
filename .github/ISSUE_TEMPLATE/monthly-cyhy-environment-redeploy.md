---
name: Monthly CyHy Environment Redeploy
about: Monthly redeploy of the CyHy .nvironment
title: 2020-XX Redeploy CyHy Environment
labels: ''
assignees: hillaryj, mcdonnnj

---

## Procedure ##

Add the following to the [`Redeployments` list](https://github.com/cisagov/cyhy_amis/issues/272)

```
- [ ] [202X-XX](link to comment for that month)
```

Follow the [build and deploy instructions](https://github.com/cisagov/cyhy_amis#building-the-amis).

Check off each service as it is redeployed to track the overall status. Once all services have been redeployed and functionality confirms, close this issue and check off the month on the [`Redeployments` list](https://github.com/cisagov/cyhy_amis/issues/272).

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
