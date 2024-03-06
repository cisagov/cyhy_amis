#!/usr/bin/env python3

"""Append the necessary DHCP options to the Netplan configuration.

The Netplan configuration is created by cloud-init, but it needs to be
slightly modified and reapplied.  This script takes care of the
modification.
See these issues for more details:
- cisagov/skeleton-packer#300
- canonical/cloud-init#4764
This file is a template.  It should be processed by Terraform.
"""

# Third-Party Libraries
import yaml

# Inputs from Terraform
NETPLAN_CONFIG = "${netplan_config}"

with open(NETPLAN_CONFIG) as f:
    # Load the current Netplan configuration
    config = yaml.safe_load(f)
    # Add a dhcp4-overrides section to each network
    config["network"]["ethernets"] = {
        k: v | {"dhcp4-overrides": {"use-domains": True}}
        for (k, v) in config["network"]["ethernets"].items()
    }

# Write the results back out to the Netplan configuration file
with open(NETPLAN_CONFIG, "w") as f:
    f.write(yaml.dump(config))
