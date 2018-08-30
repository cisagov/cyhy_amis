#!/usr/bin/env python

import copy
import datetime
import glob
import json
import logging
import os
import requests
import ssl
import sys
import time

USER = ''
PASSWORD = ''
URL = 'https://localhost:8834'
BASE_POLICY_FILE_NAME = '/tmp/cyhy-base-nessus-policy.xml'

DEBUG = False
LOGIN = '/session'
POLICY_BASE = '/policies'
FILE_UPLOAD = '/file/upload'
POLICY_IMPORT = '/policies/import'
OK_STATUS = 200
NOT_FOUND_STATUS = 404
INVALID_CREDS_STATUS = 401

LOGGER_FORMAT = '%(asctime)-15s %(levelname)s %(message)s'
LOGGER_LEVEL = logging.INFO
LOGGER = None # initialized in setup_logging()

WAIT_TIME_SEC = 10                  # Seconds between polling requests to see if a running scan has finished
VERIFY_SSL = False                  # Would be nice to get this working
FAILED_REQUEST_MAX_RETRIES = 3      # Number of times to retry a failed request before giving up
FAILED_REQUEST_RETRY_WAIT_SEC = 30  # Seconds to wait between failed request retries

if DEBUG:
    import httplib as http_client
    http_client.HTTPConnection.debuglevel = 1
    logging.basicConfig()
    logging.getLogger().setLevel(logging.DEBUG)
    requests_log = logging.getLogger("requests.packages.urllib3")
    requests_log.setLevel(logging.DEBUG)
    requests_log.propagate = True

def setup_logging():
    global LOGGER
    logging.captureWarnings(True)                    # Added to capture InsecureRequestWarnings
    LOGGER = logging.getLogger(__name__)
    LOGGER.setLevel(LOGGER_LEVEL)
    handler = logging.StreamHandler(sys.stderr)
    LOGGER.addHandler(handler)
    formatter = logging.Formatter(LOGGER_FORMAT)
    handler.setFormatter(formatter)

class NessusController(object):
    def __init__(self, nessus_url):
        self.url = nessus_url
        self.token = None

    def __make_request(self, target, method, payload=None, files=None):
        num_retries = 0
        if payload:
            payload = json.dumps(payload)

        while num_retries < FAILED_REQUEST_MAX_RETRIES:
            if num_retries > 0:
                LOGGER.warning('Waiting {!r} seconds...'.format(FAILED_REQUEST_RETRY_WAIT_SEC))
                time.sleep(FAILED_REQUEST_RETRY_WAIT_SEC)

            headers = {'Content-Type':'application/json; charset=UTF-8'}    # Send everything as json content

            # If we aren't logged in (don't have a session token) and we aren't already attempting to login, then try to login
            if self.token == None and target != LOGIN:
                LOGGER.info('Attempting to login to Nessus server')
                self.__make_request(LOGIN, 'POST', {'username':USER, 'password':PASSWORD})

            # If we are already logged in, add the token to the headers
            if self.token:
                headers['X-Cookie'] = 'token={!s}'.format(self.token)

            if method == 'GET':
                response = requests.get(self.url + target, headers=headers, params=payload, verify=VERIFY_SSL)
            elif method == 'POST':
                if files:
                    # This reassigning of headers is to remove the content type assignment
                    headers = {'X-Cookie':'token={!s}'.format(self.token)}
                    response = requests.post(self.url + target, headers=headers, files=files, verify=VERIFY_SSL)
                else:
                    response = requests.post(self.url + target, headers=headers, data=payload, verify=VERIFY_SSL)
            elif method == 'PUT':
                response = requests.put(self.url + target, headers=headers, data=payload, verify=VERIFY_SSL)
            elif method == 'DELETE':
                response = requests.delete(self.url + target, headers=headers, verify=VERIFY_SSL)

            if response.status_code == OK_STATUS:
                if target == LOGIN and method == 'POST':
                    LOGGER.info('Successfully logged into Nessus server')
                    self.token = response.json().get('token')   # Store the token if we just logged in
                return response

            LOGGER.warning('Request failed ({!r} {!r}, attempt #{!r}); response={!r}'.format(method, self.url + target, num_retries+1, response.text))
            if self.token and response.status_code == INVALID_CREDS_STATUS:
                LOGGER.warning('Invalid credentials error; Nessus session probably expired.')
                LOGGER.warning('Attempting to establish new Nessus session (username: {!r})'.format(USER))
                self.token = None       # Clear token to force re-login on next loop
                # Don't increment num_retries here; upcoming re-login request will have it's own num_retries counter
            else:
                num_retries += 1
        else:   # while loop has reached FAILED_REQUEST_MAX_RETRIES
            LOGGER.critical('Maximum retry attempts reached without success.')
            sys.exit(num_retries)

    def find_policy(self, policy_name):
        '''Attempts to grab the policy ID for a name'''
        policies = self.policy_list()
        if policies.get('policies'):
            for p in policies['policies']:
                if p['name'] == policy_name:
                    return p
            # If no matching policy name is found, return None
            return None
        else:
            return None

    def import_policy(self, filename):
        response = self.__make_request(POLICY_IMPORT, 'POST', payload={'file':filename})
        if response.status_code == OK_STATUS:
            return response.json()
        else:
            raise Warning('Policy import failed; response={!r}'.format(response.text))

    def upload_file(self, files):
        response = self.__make_request(FILE_UPLOAD, 'POST', files=files)
        if response.status_code == OK_STATUS:
            return response.json()
        else:
            raise Warning('File upload failed; response={!r}'.format(response.text))

    def policy_list(self):
        response = self.__make_request(POLICY_BASE, 'GET')
        if response.status_code == OK_STATUS:
            return response.json()
        else:
            raise Warning('Policy list failed; response={!r}'.format(response.text))

    def destroy_session(self):
        response = self.__make_request(LOGIN, 'DELETE')
        if response.status_code == OK_STATUS:
            return response
        else:
            raise Warning('Session destruction failed; response={!r}'.format(response.text))

def main():
    setup_logging()
    LOGGER.info('Nessus job starting')

    LOGGER.info('Instantiating Nessus controller at: {!s}'.format(URL))
    controller = NessusController(URL)

    # create new policy
    LOGGER.info('Creating new policy based on base policy')
    if not controller.find_policy('cyhy-base'):
        files = {'Filedata': (BASE_POLICY_FILE_NAME, open(BASE_POLICY_FILE_NAME, 'rb'), 'text/xml')}
        upload_response = controller.upload_file(files)
        assert upload_response, 'Response empty, upload failed'
        LOGGER.info('Policy Uploaded to Nessus Server')
        import_response = controller.import_policy(upload_response['fileuploaded'])
        assert import_response, 'Response empty, policy upload failed'
        LOGGER.info('Base Policy Imported to Nessus Server Policies')
    else:
        LOGGER.info('Policy already exists')

    # destroy session
    LOGGER.info('Destroying session')
    result = controller.destroy_session()
    assert result, 'Session not properly destroyed'
    LOGGER.info('Session destroyed successfully')

    # great success!
    LOGGER.info('Policy Created. (GREAT SUCCESS!)')
    sys.exit(0)

if __name__=='__main__':
    main()
