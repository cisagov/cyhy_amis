#!/usr/bin/env python3

"""Gather and publish the list of IPs of EC2 instances tagged for publication."""

# Standard Python Libraries
from datetime import datetime
from ipaddress import collapse_addresses, ip_network
import re

# Third-Party Libraries
import boto3

# name of the bucket to publish into
BUCKET_NAME = "s3-cdn.rules.ncats.cyber.dhs.gov"

# the domain where the published files are located
DOMAIN = "rules.ncats.cyber.dhs.gov"

# an AWS-style filter definition to limit the queried regions
REGION_FILTERS = [{"Name": "endpoint", "Values": ["*.us-*"]}]

# the instance tag used to designate that a public ip should be published
PUBLISH_EGRESS_TAG = "Publish Egress"

# the instance tag that will contain the application associated with
# an instance
APPLICATION_TAG = "Application"

# the header template for each file
HEADER = """###
# https://{domain}/{filename}
# {timestamp}
# CISA Vulnerability Management (VM)
# {description}
# Please contact vulnerability@cisa.dhs.gov with any questions
###
"""

# A list of dictionaries that define the files to be created and
# published.  When an ip is to be published, its associated
# application is compared to the app_regex field.  If it matches it
# will be included in the associated filename.

# The following CIDR blocks are where our Cyber Hygiene scans
# originate from:
cyhy_ips = (
    "52.6.133.213/32",  # CyHy "manual scan" instance (env2)
    "64.69.57.0/24",
    "100.27.42.128/25",
)
# The following CIDR blocks are where our Qualys web application scans
# originate from:
qualys_was_ips = (
    "64.39.99.19/32",
    "64.39.99.20/30",
    "64.39.99.24/31",
    "64.39.99.98/31",
    "64.39.99.100/32",
    "64.39.99.131/32",
    "64.39.99.132/30",
    "64.39.99.136/29",
    "64.39.99.144/31",
    "64.39.108.103/32",
    "64.39.108.104/29",
    "64.39.108.112/28",
)
FILE_CONFIGS = [
    {
        "filename": "all.txt",
        "app_regex": re.compile(".*"),
        "static_ips": cyhy_ips + qualys_was_ips,
        "description": "This file contains a consolidated list of all the IP addresses that VM is currently using for external scanning.",
    },
    {
        "filename": "cyhy.txt",
        "app_regex": re.compile("(Manual )?Cyber Hygiene$"),
        "static_ips": cyhy_ips,
        "description": "This file contains a list of all IPs used for Cyber Hygiene scanning.",
    },
    {
        "filename": "pca.txt",
        "app_regex": re.compile("Phishing Campaign Assessment$"),
        "static_ips": (),
        "description": "This file contains a list of all IPs used for Phishing Campaign Assessments.",
    },
    {
        "filename": "was.txt",
        "app_regex": re.compile("Web Application Scanning$"),
        "static_ips": qualys_was_ips,
        "description": "This file contains a list of all IPs used for Web Application Scanning.",
    },
]


def get_ec2_regions(filter=None):
    """Get a filtered list of all the regions with EC2 support."""
    ec2 = boto3.client("ec2")
    response = ec2.describe_regions(Filters=filter)
    result = [x["RegionName"] for x in response["Regions"]]
    return result


def get_ec2_ips(region):
    """Create a set of public IPs for the given region.

    yields (application tag value, public_ip) tuples
    """
    ec2 = boto3.resource("ec2", region_name=region)
    instances = ec2.instances.filter(
        Filters=[{"Name": "instance-state-name", "Values": ["running"]}]
    )
    vpc_addresses = ec2.vpc_addresses.all()  # the list of elastic IPs

    for instance in instances:
        # if the instance doesn't have a public ip we can skip
        if instance.public_ip_address is None:
            continue
        # convert tags from aws dict into a real dictionary
        tags = {x["Key"]: x["Value"] for x in instance.tags}
        # if the publish egress tag isn't set to True we can skip
        if tags.get(PUBLISH_EGRESS_TAG, str(False)) != str(True):
            continue
        # send back a tuple associating the public ip to an
        # application if application is unset use '', because we still
        # want it in our "all" list
        yield (tags.get(APPLICATION_TAG, ""), instance.public_ip_address)

    for vpc_address in vpc_addresses:
        # convert tags from aws dict into a real dictionary
        try:
            tags = {x["Key"]: x["Value"] for x in vpc_address.tags}
        except TypeError:
            # This happens if there are no tags associated with the elastic IPs
            tags = {}
        # if the publish egress tag isn't set to True we can skip
        if tags.get(PUBLISH_EGRESS_TAG, str(False)) != str(True):
            continue
        # send back a tuple associating the public ip to an
        # application if application is unset use '', because we still
        # want it in our "all" list
        yield (tags.get(APPLICATION_TAG, ""), vpc_address.public_ip)


def update_bucket(bucket_name, filename, bucket_contents):
    """Update the s3 bucket with the new contents."""
    s3 = boto3.resource("s3")

    # get the bucket
    bucket = s3.Bucket(bucket_name)

    # get the object within the bucket
    b_object = bucket.Object(filename)

    # send the bytes contents to the object in the bucket
    # prevent caching of this object
    b_object.put(
        Body=bucket_contents.encode("utf-8"),
        CacheControl="no-cache",
        ContentType="text/plain",
        ContentEncoding="utf-8",
    )

    # by default new objects cannot be read by public
    # allow public reads of this object
    b_object.Acl().put(ACL="public-read")


def main():
    """Get the list of IPs to publish and upload them to the S3 bucket."""
    # get a list of all the regions
    regions = get_ec2_regions(REGION_FILTERS)

    # start up message
    print("gathering public ips from %d regions" % len(regions))

    # initialize a set to accumulate ips for each file
    for config in FILE_CONFIGS:
        config["ip_set"] = {ip_network(i) for i in config["static_ips"]}

    # loop through the region list and fetch the public ec2 ips
    for region in regions:
        print("querying region: %s" % region)
        # get the public ips of instances that are tagged to be published
        for application_tag, public_ip in get_ec2_ips(region):
            # loop through all regexs and add ip to set if matched
            for config in FILE_CONFIGS:
                if config["app_regex"].match(application_tag):
                    config["ip_set"].add(ip_network(public_ip))

    # use a single timestamp for all files
    now = "{:%a %b %d %H:%M:%S UTC %Y}".format(datetime.utcnow())

    # update each file in the bucket
    for config in FILE_CONFIGS:
        # initialize bucket contents
        bucket_contents = HEADER
        for net in collapse_addresses(config["ip_set"]):
            bucket_contents += str(net) + "\n"

        # fill in template
        bucket_contents = bucket_contents.format(
            domain=DOMAIN,
            filename=config["filename"],
            timestamp=now,
            description=config["description"],
        )

        # send the contents to the s3 bucket
        update_bucket(BUCKET_NAME, config["filename"], bucket_contents)

        # print the contents for the user
        print()
        print("-" * 40)
        print(bucket_contents)
        print("-" * 40)
        print()
    print("complete")

    # import IPython; IPython.embed() #<<< BREAKPOINT >>>


if __name__ == "__main__":
    main()
