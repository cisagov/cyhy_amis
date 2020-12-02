# Standard Python Libraries
import json
import logging
import sys
import time

# Third-Party Libraries
import requests

USER = ""
PASSWORD = ""
URL = "https://localhost:8834"
BASE_POLICY_NAME = "cyhy-base"
BASE_POLICY_FILE_NAME = "/tmp/cyhy-base-nessus8-policy.xml"

DEBUG = False
LOGIN = "/session"
POLICY_BASE = "/policies"
FILE_UPLOAD = "/file/upload"
POLICY_IMPORT = "/policies/import"
OK_STATUS = 200
NOT_FOUND_STATUS = 404
INVALID_CREDS_STATUS = 401

LOGGER_FORMAT = "%(asctime)-15s %(levelname)s %(message)s"
LOGGER_LEVEL = logging.INFO
LOGGER = None  # initialized in setup_logging()

# Seconds between polling requests to see if a running scan has
# finished
WAIT_TIME_SEC = 10
# Would be nice to get this working
VERIFY_SSL = False
# Number of times to retry a failed request before giving up
FAILED_REQUEST_MAX_RETRIES = 30
# Seconds to wait between failed request retries
FAILED_REQUEST_RETRY_WAIT_SEC = 10

# Note that we disable LGTM's unreachable statement warning for this
# particular bit of code
if DEBUG:
    # Standard Python Libraries
    import http.client as http_client  # lgtm[py/unreachable-statement]

    http_client.HTTPConnection.debuglevel = 1
    logging.basicConfig()
    logging.getLogger().setLevel(logging.DEBUG)
    requests_log = logging.getLogger("requests.packages.urllib3")
    requests_log.setLevel(logging.DEBUG)
    requests_log.propagate = True


def setup_logging():
    global LOGGER
    # Added to capture InsecureRequestWarnings
    logging.captureWarnings(True)
    LOGGER = logging.getLogger(__name__)
    LOGGER.setLevel(LOGGER_LEVEL)
    handler = logging.StreamHandler(sys.stderr)
    LOGGER.addHandler(handler)
    formatter = logging.Formatter(LOGGER_FORMAT)
    handler.setFormatter(formatter)


class NessusController:
    def __init__(self, nessus_url):
        self.url = nessus_url
        self.token = None

    def __make_request(self, target, method, payload=None, files=None):
        num_retries = 0
        if payload:
            payload = json.dumps(payload)

        while num_retries < FAILED_REQUEST_MAX_RETRIES:
            if num_retries > 0:
                LOGGER.warning("Waiting %d seconds...", FAILED_REQUEST_RETRY_WAIT_SEC)
                time.sleep(FAILED_REQUEST_RETRY_WAIT_SEC)

            # Send everything as json content
            headers = {"Content-Type": "application/json; charset=UTF-8"}

            # If we aren't logged in (don't have a session token) and
            # we aren't already attempting to login, then try to login
            if self.token is None and target != LOGIN:
                LOGGER.info("Attempting to login to Nessus server")
                self.__make_request(
                    LOGIN, "POST", {"username": USER, "password": PASSWORD}
                )

            # If we are already logged in, add the token to the
            # headers
            if self.token:
                headers["X-Cookie"] = f"token={self.token}"

            if method == "GET":
                response = requests.get(
                    self.url + target,
                    headers=headers,
                    params=payload,
                    verify=VERIFY_SSL,
                )
            elif method == "POST":
                if files:
                    # This reassigning of headers is to remove the
                    # content type assignment
                    headers = {"X-Cookie": f"token={self.token}"}
                    response = requests.post(
                        self.url + target,
                        headers=headers,
                        files=files,
                        verify=VERIFY_SSL,
                    )
                else:
                    response = requests.post(
                        self.url + target,
                        headers=headers,
                        data=payload,
                        verify=VERIFY_SSL,
                    )
            elif method == "PUT":
                response = requests.put(
                    self.url + target, headers=headers, data=payload, verify=VERIFY_SSL
                )
            elif method == "DELETE":
                response = requests.delete(
                    self.url + target, headers=headers, verify=VERIFY_SSL
                )

            if response.status_code == OK_STATUS:
                if target == LOGIN and method == "POST":
                    LOGGER.info("Successfully logged into Nessus server")
                    # Store the token if we just logged in
                    self.token = response.json().get("token")
                return response

            LOGGER.warning(
                "Request failed (%s %s, attempt #%d); response=%s",
                method,
                self.url + target,
                num_retries + 1,
                response.text,
            )
            if self.token and response.status_code == INVALID_CREDS_STATUS:
                LOGGER.warning(
                    "Invalid credentials error; Nessus session probably expired."
                )
                LOGGER.warning(
                    "Attempting to establish new Nessus session (username: %s)", USER
                )
                # Clear token to force re-login on next loop
                self.token = None
                # Don't increment num_retries here; upcoming re-login
                # request will have it's own num_retries counter
            else:
                num_retries += 1

        # The while loop has reached FAILED_REQUEST_MAX_RETRIES
        LOGGER.critical("Maximum retry attempts reached without success.")
        sys.exit(num_retries)

    def find_policy(self, policy_name):
        """Attempt to grab the policy ID for a name."""
        policies = self.policy_list()
        if policies.get("policies"):
            for policy in policies["policies"]:
                if policy["name"] == policy_name:
                    return policy
            # If no matching policy name is found, return None
            return None
        return None

    def import_policy(self, filename):
        response = self.__make_request(
            POLICY_IMPORT, "POST", payload={"file": filename}
        )
        if response.status_code == OK_STATUS:
            return response.json()
        raise Warning(f"Policy import failed; response={response.text}")

    def upload_file(self, files):
        response = self.__make_request(FILE_UPLOAD, "POST", files=files)
        if response.status_code == OK_STATUS:
            return response.json()
        raise Warning(f"File upload failed; response={response.text}")

    def policy_list(self):
        response = self.__make_request(POLICY_BASE, "GET")
        if response.status_code == OK_STATUS:
            return response.json()
        raise Warning(f"Policy list failed; response={response.text}")

    def destroy_session(self):
        response = self.__make_request(LOGIN, "DELETE")
        if response.status_code == OK_STATUS:
            return response
        raise Warning(
            f"Session destruction failed; response={response.text}"
        )


def main():
    setup_logging()
    LOGGER.info("Nessus job starting")

    LOGGER.info("Instantiating Nessus controller at: %s", URL)
    controller = NessusController(URL)

    # create new policy
    LOGGER.info("Creating new policy based on base policy")
    if not controller.find_policy(BASE_POLICY_NAME):
        files = {
            "Filedata": (
                BASE_POLICY_FILE_NAME,
                open(BASE_POLICY_FILE_NAME, "rb"),
                "text/xml",
            )
        }
        upload_response = controller.upload_file(files)
        if not upload_response:
            LOGGER.error("Response empty, upload failed")
            return -1
        LOGGER.info("Policy Uploaded to Nessus Server")
        import_response = controller.import_policy(upload_response["fileuploaded"])
        if not import_response:
            LOGGER.error("Response empty, policy upload failed")
            return -1
        LOGGER.info("Base Policy Imported to Nessus Server Policies")
    else:
        LOGGER.info("Policy already exists")

    # destroy session
    LOGGER.info("Destroying session")
    result = controller.destroy_session()
    if not result:
        LOGGER.error("Session not properly destroyed")
        return -1
    LOGGER.info("Session destroyed successfully")

    # great success!
    LOGGER.info("Policy Created. (GREAT SUCCESS!)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
