"""Configure the local Nessus server with a base policy."""

# Standard Python Libraries
import json
import logging
import sys
import time

# Third-Party Libraries
import requests
import yaml

NESSUS_API_CONFIGURATION_FILE = "/etc/cyhy/nessus_api.yml"

DEBUG = False

ADVANCED_SETTINGS = "/settings/advanced"
ADVANCED_SETTINGS_DICT = {
    "orphaned_scan_cleanup_days": "7",
    "report_cleanup_threshold_days": "7",
    "scan_history_expiration_days": "7",
}

FILE_UPLOAD = "/file/upload"
LOGIN = "/session"
POLICY_BASE = "/policies"
POLICY_IMPORT = "/policies/import"

INVALID_CREDS_STATUS = 401
NOT_FOUND_STATUS = 404
OK_STATUS = 200

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

if DEBUG:
    # Standard Python Libraries
    import http.client as http_client

    # This leverages an unofficial means to set the debug level for HTTPConnection
    # objects. The official way is to use <HTTPConnection object>.set_debuglevel()
    # but since we are using the requests library we do not have access to use the
    # correct method. We must use this hack to get debugging information but it
    # fails mypy because there are no type stubs to support this method. As a
    # result we must disable typechecking for this line.
    http_client.HTTPConnection.debuglevel = 1  # type: ignore
    logging.basicConfig()
    logging.getLogger().setLevel(logging.DEBUG)
    requests_log = logging.getLogger("requests.packages.urllib3")
    requests_log.setLevel(logging.DEBUG)
    requests_log.propagate = True


def setup_logging():
    """Configure logging for the script."""
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
    """Manage interactions with the running Nessus web interface."""

    def __init__(self, nessus_url, nessus_username, nessus_password):
        """Initialize a NessusController object."""
        self.url = nessus_url
        self.username = nessus_username
        self.password = nessus_password
        self.token = None

    def __make_request(self, target, method, payload=None, files=None):
        """Make a request to the Nessus web interface."""
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
                    LOGIN,
                    "POST",
                    {"username": self.username, "password": self.password},
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
                    "Attempting to establish new Nessus session (username: %s)",
                    self.username,
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

    def configure_advanced_settings(self, advanced_settings):
        """Configure Nessus advanced settings."""
        for setting_name, setting_value in advanced_settings.items():
            LOGGER.info("Configuring advanced setting: %s", setting_name)
            response = self.__make_request(
                ADVANCED_SETTINGS,
                "PUT",
                payload={
                    "setting.0.action": "edit",
                    "setting.0.name": setting_name,
                    "setting.0.value": setting_value,
                },
            )

            if response.status_code == OK_STATUS:
                LOGGER.info("Successfully set %s to %s", setting_name, setting_value)
            else:
                LOGGER.error(
                    "Failed to configure advanced setting: %s; response=%s",
                    setting_name,
                    response.text,
                )
                return None
        return response

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
        """Attempt to import a policy from the given filename."""
        response = self.__make_request(
            POLICY_IMPORT, "POST", payload={"file": filename}
        )
        if response.status_code == OK_STATUS:
            return response.json()
        raise Warning(f"Policy import failed; response={response.text}")

    def upload_file(self, files):
        """Upload a file."""
        response = self.__make_request(FILE_UPLOAD, "POST", files=files)
        if response.status_code == OK_STATUS:
            return response.json()
        raise Warning(f"File upload failed; response={response.text}")

    def policy_list(self):
        """Get a list of policies."""
        response = self.__make_request(POLICY_BASE, "GET")
        if response.status_code == OK_STATUS:
            return response.json()
        raise Warning(f"Policy list failed; response={response.text}")

    def destroy_session(self):
        """Destroy the HTTP session."""
        response = self.__make_request(LOGIN, "DELETE")
        if response.status_code == OK_STATUS:
            return response
        raise Warning(f"Session destruction failed; response={response.text}")


def main():
    """Configure settings and create a base policy via the Nessus API."""
    setup_logging()
    LOGGER.info("Nessus job starting")

    LOGGER.info(
        "Getting Nessus configuration information from %s",
        NESSUS_API_CONFIGURATION_FILE,
    )
    with open(NESSUS_API_CONFIGURATION_FILE) as configuration_file:
        api_configuration = yaml.load(configuration_file, Loader=yaml.SafeLoader)

    try:
        LOGGER.info("Instantiating Nessus controller at: %s", api_configuration["url"])
        controller = NessusController(
            api_configuration["url"],
            api_configuration["credentials"]["username"],
            api_configuration["credentials"]["password"],
        )

        # configure advanced settings
        LOGGER.info("Configuring advanced settings")
        if not controller.configure_advanced_settings(ADVANCED_SETTINGS_DICT):
            LOGGER.error("Advanced settings configuration failed")
            return -1
        LOGGER.info("Advanced settings successfully configured")

        # create new policy
        LOGGER.info("Creating new policy based on base policy")
        if not controller.find_policy(api_configuration["policy"]["name"]):
            files = {
                "Filedata": (
                    api_configuration["policy"]["source"],
                    open(api_configuration["policy"]["source"], "rb"),
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
    except KeyError:
        LOGGER.exception("Missing required key from Nessus API configuration file")
        return -1

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
