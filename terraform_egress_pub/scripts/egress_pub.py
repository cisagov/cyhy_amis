#!/usr/bin/env python3
import boto3
from datetime import datetime

BUCKET_NAME = 's3-cdn.rules.ncats.cyber.dhs.gov'
DOMAIN = 'rules.ncats.cyber.dhs.gov'
STATIC_IPS = ('64.69.57.0/24',)
FILE_NAME = 'all.txt'
HEADER = '''###
# https://{domain}/{filename}
# {timestamp}
# DHS National Cybersecurity Assessments & Technical Services (NCATS)
# This file contains a consolidated list of all the IP addresses that NCATS is
# currently using for external scanning.
# Please contact ncats@hq.dhs.gov with any questions
###
'''

def all_ec2_regions():
    '''get a list of all the regions with ec2 support'''

    ec2 = boto3.client('ec2')
    response = ec2.describe_regions()
    result = [x['RegionName'] for x in response['Regions']]
    return result

def get_ec2_ips(region):
    '''create a set of public IPs for the given region'''

    ec2 = boto3.resource('ec2', region_name=region)
    instances = ec2.instances.filter(
        Filters=[{'Name': 'instance-state-name', 'Values': ['running']}])

    ips = set()
    for instance in instances:
        if instance.public_ip_address == None:
            continue
        print('\t', instance.id, instance.instance_type, instance.public_ip_address)
        ips.add(instance.public_ip_address)
    return ips

def update_bucket(bucket_name, bucket_contents):
    '''update the s3 bucket with the new contents'''

    s3 = boto3.resource('s3')

    # get the bucket
    bucket = s3.Bucket(bucket_name)

    # get the object within the bucket
    b_object = bucket.Object(FILE_NAME)

    # send the bytes contents to the object in the bucket
    # prevent caching of this object
    b_object.put(Body=bucket_contents.encode('utf-8'),
                 CacheControl='no-cache',
                 ContentType='text/plain',
                 ContentEncoding='utf-8')

    # by default new objects cannot be read by public
    # allow public reads of this object
    b_object.Acl().put(ACL='public-read')


def main():
    # initialize the ip set with the static ips
    ips = set(STATIC_IPS)

    # get a list of all the regions
    all_regions = all_ec2_regions()

    # start up message
    print('gathering public ips from %d regions' % len(all_regions))

    # loop through the region list and fetch the public ec2 ips
    for region in all_regions:
        print('querying region: %s' % region)
        ips.update(get_ec2_ips(region))

    # initialize bucket contents
    bucket_contents = HEADER
    for ip in sorted(ips):
        bucket_contents += ip + '\n'

    # fill in template
    now = '{0:%a %b %d %H:%M:%S UTC %Y}'.format(datetime.utcnow())
    bucket_contents = bucket_contents.format(domain=DOMAIN, filename=FILE_NAME, timestamp=now)

    # send the contents to the s3 bucket
    update_bucket(BUCKET_NAME, bucket_contents)

    # print the contents for the user
    print()
    print('-' * 40)
    print(bucket_contents)
    print('-' * 40)
    print()
    print('complete')

    #import IPython; IPython.embed() #<<< BREAKPOINT >>>

if __name__ == '__main__':
    main()
