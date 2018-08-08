#!/usr/bin/env python3
import boto3
from datetime import datetime

BUCKET_NAME = 's3-cdn.rules.ncats.cyber.dhs.gov'
DOMAIN = BUCKET_NAME
FILE_NAME = 'all.txt'
HEADER = '''###
# http://{domain}/{filename}
# {timestamp}
# DHS National Cybersecurity Assessments & Technical Services (NCATS)
# This file contains a consolidated list of all the IP addresses that NCATS is
# currently using for external scanning.
# Please contact ncats@hq.dhs.gov with any questions
###
64.69.57.0/24
'''

def main():
    global HEADER

    # collect all the public IP addresses for running instances
    ec2 = boto3.resource('ec2')
    instances = ec2.instances.filter(
        Filters=[{'Name': 'instance-state-name', 'Values': ['running']}])
    for instance in instances:
        print(instance.id, instance.instance_type, instance.public_ip_address)
        if instance.public_ip_address != None: 
            HEADER += instance.public_ip_address + '\n'

    # Fill in template
    now = '{0:%a %b %d %H:%M:%S UTC %Y}'.format(datetime.utcnow())
    HEADER = HEADER.format(domain=DOMAIN, filename=FILE_NAME, timestamp=now)

    s3 = boto3.resource('s3')
    # get the bucket
    bucket = s3.Bucket(BUCKET_NAME)

    # get the object within the bucket
    b_object = bucket.Object(FILE_NAME)

    # send the bytes header to the object in the bucket
    # prevent caching of this object
    b_object.put(Body=HEADER.encode('utf-8'),
                 CacheControl='no-cache',
                 ContentType='text/plain',
                 ContentEncoding='utf-8')

    # by default new objects cannot be read by public
    # allow public reads of this object
    b_object.Acl().put(ACL='public-read')

    # print for the user
    print(HEADER)
    #import IPython; IPython.embed() #<<< BREAKPOINT >>>

if __name__ == '__main__':
    main()
