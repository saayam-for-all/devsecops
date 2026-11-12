import csv
import json
import os
import requests
from threading import Lock

from locust import HttpUser, task, between

DEFAULT_HOST = "https://api.help-for-everyone.org"

# Sensitive values come from environment variables (GitHub Actions secrets)
AUTH_URL = os.environ["AUTH_URL"]
CLIENT_ID = os.environ["CLIENT_ID"]
USERNAME = os.environ["USERNAME"]
PASSWORD = os.environ["PASSWORD"]

token_lock = Lock()

with open("api.csv", newline="", encoding="utf-8") as f:
    apis = list(csv.DictReader(f))


def resolve_url(url):
    url = url.strip()
    if url.lower().startswith(("http://", "https://")):
        return url
    return DEFAULT_HOST.rstrip("/") + "/" + url.lstrip("/")


def get_token():

    payload = {
        "AuthFlow": "USER_PASSWORD_AUTH",
        "ClientId": CLIENT_ID,
        "AuthParameters": {
            "USERNAME": USERNAME,
            "PASSWORD": PASSWORD
        }
    }

    headers = {
        "Content-Type": "application/x-amz-json-1.1",
        "X-Amz-Target": "AWSCognitoIdentityProviderService.InitiateAuth"
    }

    r = requests.post(
        AUTH_URL,
        data=json.dumps(payload),
        headers=headers
    )

    print("AUTH STATUS:", r.status_code)

    if r.status_code != 200:
        raise Exception(r.text)

    return r.json()["AuthenticationResult"]["IdToken"]


class SaayamUser(HttpUser):

    wait_time = between(1, 2)

    token = None

    def on_start(self):

        if SaayamUser.token is None:
            with token_lock:
                if SaayamUser.token is None:
                    SaayamUser.token = get_token()

        self.jwt_headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {SaayamUser.token}"
        }

        self.basic_headers = {
            "Content-Type": "application/json"
        }

    @task
    def run_api_tests(self):

        for api in apis:

            method = api["method"].upper()
            url = resolve_url(api["url"])

            payload = None

            if api.get("payload") and api["payload"].strip():
                payload = api["payload"]

            response = self.client.request(
                method,
                url,
                headers=self.jwt_headers,
                data=payload,
                name=api["api_name"]
            )

            print(
                f"{api['api_name']} -> "
                f"{response.status_code} | "
                f"{response.elapsed.total_seconds()*1000:.2f} ms"
            )

            if response.status_code >= 400:
                print(response.text)
