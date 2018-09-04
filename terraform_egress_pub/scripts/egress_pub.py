#!/usr/bin/env python3
import boto3
from datetime import datetime

BUCKET_NAME = 's3-cdn.rules.ncats.cyber.dhs.gov'
DOMAIN = 'rules.ncats.cyber.dhs.gov'
HEADER = '''###
# https://{domain}/{filename}
# {timestamp}
# DHS National Cybersecurity Assessments & Technical Services (NCATS)
# {description}
# Please contact ncats@hq.dhs.gov with any questions
###
'''
REGION_FILTERS = [{'Name':'endpoint', 'Values':['*.us-*']}]

FILE_CONFIGS = \
    {   'all.txt': {
            'static_ips':   ('64.69.57.0/24',),
            'filters':      [{'Name': 'instance-state-name', 'Values': ['running']}],
            'description':  'This file contains a consolidated list of all the IP addresses that NCATS is currently using for external scanning.'
            },
        'cyhy.txt':
            {
            'static_ips':   (),
            'filters':  [   {'Name': 'instance-state-name', 'Values': ['running']},
                            {'Name': 'tag:Application', 'Values': ['Cyber Hygiene','Manual Cyber Hygiene']},
                        ],
            'description':  'This file contains a list of all IPs used for Cyber Hygiene scanning.'
            },
        'pca.txt':  {
            'static_ips':   (),
            'filters':  [
                            {'Name': 'instance-state-name', 'Values': ['running']},
                            {'Name': 'tag:Application', 'Values': ['Phishing Campaign Assessment']},
                        ],
            'description':  'This file contains a list of all IPs used for Phishing Campaign Assessments'
            },
        }

def get_ec2_regions():
    '''get a filtered list of all the regions with ec2 support'''

    ec2 = boto3.client('ec2')
    response = ec2.describe_regions(Filters=REGION_FILTERS)
    result = [x['RegionName'] for x in response['Regions']]
    return result

def get_ec2_ips(region, filters):
    '''create a set of public IPs for the given region'''

    ec2 = boto3.resource('ec2', region_name=region)
    instances = ec2.instances.filter(Filters=filters)

    ips = set()
    for instance in instances:
        if instance.public_ip_address == None:
            continue
        #print('\t', instance.id, instance.instance_type, instance.public_ip_address)
        ips.add(instance.public_ip_address)
    return ips

def update_bucket(bucket_name, filename, bucket_contents):
    '''update the s3 bucket with the new contents'''

    s3 = boto3.resource('s3')

    # get the bucket
    bucket = s3.Bucket(bucket_name)

    # get the object within the bucket
    b_object = bucket.Object(filename)

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
    # get a list of all the regions
    all_regions = get_ec2_regions()

    # start up message
    print('gathering public ips from %d regions' % len(all_regions))

    # initialize a set for each publication in a dictionary
    ip_sets = {k:set((FILE_CONFIGS[k]['static_ips'])) for k in FILE_CONFIGS.keys()}

    # loop through the region list and fetch the public ec2 ips
    for region in all_regions:
        print('querying region: %s' % region)
        for (filename, config) in FILE_CONFIGS.items():
            # get the public ips that match the filter for this configuration
            public_ips = get_ec2_ips(region, config['filters'])
            print('\t', filename, ':\t', len(public_ips))
            # add the matching ips to the ip set for this file
            ip_sets[filename].update(public_ips)

    # use a single timestamp for all files
    now = '{0:%a %b %d %H:%M:%S UTC %Y}'.format(datetime.utcnow())

    # update each file in the bucket
    for (filename, config) in FILE_CONFIGS.items():
        # initialize bucket contents
        bucket_contents = HEADER
        for ip in sorted(ip_sets[filename]):
            bucket_contents += ip + '\n'

        # fill in template
        bucket_contents = bucket_contents.format(domain=DOMAIN,
                                                 filename=filename,
                                                 timestamp=now,
                                                 description=config['description'])

        # send the contents to the s3 bucket
        update_bucket(BUCKET_NAME, filename, bucket_contents)

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
