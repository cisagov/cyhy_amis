#!/usr/bin/env python3

"""
This script will configure the terraform environment based on the active
workspace.

Due to a terraform limitation, modules can not be scaled with the "count"
keyword the same way resource can.  This leads to a great deal of copying and
pasting in order to get provisioners and other modules to execute correctly.

This script can be retired once this limitation is removed from Terraform.
See: https://github.com/hashicorp/terraform/issues/10462
See: https://github.com/hashicorp/terraform/issues/17519

To create a unique configuration for your own workspace edit the
WORKSPACE_CONFIGS constant below.
"""

import glob
import os
import subprocess
from string import Template
import sys

# This script uses a subprocess feature added in python 3.7
assert sys.version_info >= (3, 7), "This script requires Python version 3.7 or newer"

# for each workspace, set the number of instances to create for each template
# NOTE: mgmt_bastion should only be set to 0 or 1
WORKSPACE_CONFIGS = {
    "production": {
        "nmap": 80,
        "nessus": 3,
        "mongo": 1,
        "mgmt_bastion": 0,
        "mgmt_nessus": 0,
    },
    "prod-a": {
        "nmap": 80,
        "nessus": 3,
        "mongo": 1,
        "mgmt_bastion": 0,
        "mgmt_nessus": 0,
    },
    "prod-b": {
        "nmap": 80,
        "nessus": 3,
        "mongo": 1,
        "mgmt_bastion": 0,
        "mgmt_nessus": 0,
    },
    "daver": {"nmap": 0, "nessus": 0, "mongo": 1, "mgmt_bastion": 0, "mgmt_nessus": 0},
    "felddy": {"nmap": 4, "nessus": 1, "mongo": 1, "mgmt_bastion": 0, "mgmt_nessus": 0},
    "hillary": {
        "nmap": 0,
        "nessus": 0,
        "mongo": 1,
        "mgmt_bastion": 0,
        "mgmt_nessus": 0,
    },
    "jsf9k": {"nmap": 0, "nessus": 0, "mongo": 1, "mgmt_bastion": 0, "mgmt_nessus": 0},
    "mcdonnnj": {
        "nmap": 0,
        "nessus": 0,
        "mongo": 1,
        "mgmt_bastion": 0,
        "mgmt_nessus": 0,
    },
}

# the default configuration if a workspace is not defined above
DEFAULT_CONFIG = {
    "nmap": 1,
    "nessus": 1,
    "mongo": 1,
    "mgmt_bastion": 0,
    "mgmt_nessus": 0,
}

# variables to be defined in a dynamic locals file
LOCAL_DEFS = {
    "nmap": "nmap_instance_count",
    "nessus": "nessus_instance_count",
    "mongo": "mongo_instance_count",
    "mgmt_bastion": "mgmt_bastion_instance_count",
    "mgmt_nessus": "mgmt_nessus_instance_count",
}

# filename constant definitions
TEMPLATE_EXTENSION = ".template"
DYNAMIC_EXTENSION = ".dyn.tf"
DELETE_GLOB = "**/*" + DYNAMIC_EXTENSION
LOCALS_FILE = "locals" + DYNAMIC_EXTENSION

# the command to read the current terraform workspace
TERRAFORM_WORKSPACE_CMD = "terraform workspace show"


def get_terraform_workspace():
    """returns the current workspace"""
    completed_process = subprocess.run(
        TERRAFORM_WORKSPACE_CMD, capture_output=True, shell=True
    )
    return completed_process.stdout.decode().strip()


def find_templates():
    return glob.iglob("**/*" + TEMPLATE_EXTENSION, recursive=True)


def read_template(filename):
    """read in the template, returns a Template object"""
    # read in the template
    with open(filename) as f:
        template = f.readlines()
    # convert from a list to a single string and return
    return Template("".join(template))


def remove_dynamic_files():
    """delete all the previously created dynamic files"""
    for filename in glob.iglob(DELETE_GLOB, recursive=True):
        os.unlink(filename)


def create_dynamic_files(template, path, name, count):
    """create count number files using the template"""
    for i in range(count):
        filename = ".".join([name, str(i), DYNAMIC_EXTENSION[1:]])
        full_path = os.path.join(path, filename)
        rendered_template = template.substitute(index=i)
        with open(full_path, mode="wb") as f:
            f.write(rendered_template.encode("utf-8"))


def create_dynamic_locals(config):
    """create a dynamic locals file from configuration"""
    with open(LOCALS_FILE, mode="wb") as f:
        f.write("locals {\n".encode("utf-8"))
        for key, variable_name in LOCAL_DEFS.items():
            value = config.get(key)
            f.write(f"    {variable_name} = {value}\n".encode("utf-8"))
        f.write("}\n".encode("utf-8"))


def main():
    # get workspace
    workspace = get_terraform_workspace()
    print("Current Terraform workspace = ", workspace)

    # lookup the workspace config based on the current terraform workspace
    config = WORKSPACE_CONFIGS.get(workspace, DEFAULT_CONFIG)
    print("Configuration for workspace = ", config)

    # remove the previously generate files
    print("Removing previously generated files")
    remove_dynamic_files()

    print("Searching for templates to render...")
    # find templates and render them
    for template_file in find_templates():
        # calculate working directory and config keys from template name
        template_dir, filename = os.path.split(template_file)
        template_key, unused = os.path.splitext(filename)
        # lookup the count for this template
        count = config[template_key]
        print(
            f"Creating {count} instantiation{'' if count == 1 else 's'} of template {template_file}"
        )
        # read in the template
        template = read_template(template_file)
        for i in range(count):
            # render the template and create files
            create_dynamic_files(template, template_dir, template_key, count)

    # create a locals file that defines the counts for each template type
    print("Create dynamic locals file")
    create_dynamic_locals(config)

    # import IPython; IPython.embed() #<<< BREAKPOINT >>>


if __name__ == "__main__":
    main()
