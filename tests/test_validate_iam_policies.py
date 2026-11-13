
import json
import tempfile
import unittest
from pathlib import Path

from scripts.validate_iam_policies import (
    scan_json_policy_file,
)


class TestIAMPolicyValidator(unittest.TestCase):

    def test_detects_wildcard_action(self):
        policy = {
            "Version": "2012-10-17",
            "Statement": {
                "Effect": "Allow",
                "Action": "*",
                "Resource": "*",
            },
        }

        with tempfile.TemporaryDirectory() as temp_dir:
            policy_file = Path(temp_dir) / "policy.json"
            policy_file.write_text(json.dumps(policy), encoding="utf-8")

            findings = scan_json_policy_file(policy_file)

        self.assertTrue(
            any(finding["rule"] == "NoWildcardAction"
                for finding in findings)
        )

    def test_detects_wildcard_resource(self):
        policy = {
            "Version": "2012-10-17",
            "Statement": {
                "Effect": "Allow",
                "Action": "s3:GetObject",
                "Resource": "*",
            },
        }

        with tempfile.TemporaryDirectory() as temp_dir:
            policy_file = Path(temp_dir) / "policy.json"
            policy_file.write_text(json.dumps(policy), encoding="utf-8")

            findings = scan_json_policy_file(policy_file)

        self.assertTrue(
            any(finding["rule"] == "WildcardResource"
                for finding in findings)
        )

    def test_reports_invalid_json(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            policy_file = Path(temp_dir) / "policy.json"
            policy_file.write_text("{invalid json", encoding="utf-8")

            findings = scan_json_policy_file(policy_file)

        self.assertTrue(
            any(finding["rule"] == "InvalidJSON"
                for finding in findings)
        )


if __name__ == "__main__":
    unittest.main()
