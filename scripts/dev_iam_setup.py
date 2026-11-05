#!/usr/bin/env python3
"""
Saayam DevSecOps - Developer IAM & Role Setup CLI
=================================================
Automates the local setup and validation of developer AWS credentials and project-specific
role assumption for Saayam microservices (e.g. Volunteer Microservice S3 upload).

Usage:
  python scripts/dev_iam_setup.py --username volunteer-dev --configure-aws-cli --test-access
  python scripts/dev_iam_setup.py --secret-name saayam/dev/users/volunteer-dev/credentials
"""

import argparse
import configparser
import json
import sys
from pathlib import Path
import boto3
from botocore.exceptions import ClientError


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Setup and verify local AWS credentials and assume-role profiles for Saayam development."
    )
    parser.add_argument(
        "--username",
        type=str,
        default="volunteer-dev",
        help="Developer username (used to derive default Secrets Manager secret name)",
    )
    parser.add_argument(
        "--environment",
        type=str,
        default="dev",
        help="Target environment (dev, qa, staging)",
    )
    parser.add_argument(
        "--secret-name",
        type=str,
        default=None,
        help="Explicit AWS Secrets Manager secret name storing credentials",
    )
    parser.add_argument(
        "--region",
        type=str,
        default="us-east-1",
        help="AWS Region (default: us-east-1)",
    )
    parser.add_argument(
        "--configure-aws-cli",
        action="store_true",
        help="Automatically write/update ~/.aws/credentials and ~/.aws/config profiles",
    )
    parser.add_argument(
        "--test-access",
        action="store_true",
        help="Perform a live STS assume-role verification and check S3 permissions",
    )
    parser.add_argument(
        "--test-s3-bucket",
        type=str,
        default=None,
        help="S3 bucket name to test access against with the assumed role",
    )
    parser.add_argument(
        "--output-json",
        action="store_true",
        help="Output retrieved configuration in JSON format (excluding secret key)",
    )
    return parser.parse_args()


def fetch_credentials_from_secrets_manager(secret_name: str, region: str) -> dict:
    """Fetches developer credentials payload from AWS Secrets Manager."""
    print(f"[+] Retrieving credentials from Secrets Manager: {secret_name} (Region: {region})...")
    client = boto3.client("secretsmanager", region_name=region)
    try:
        response = client.get_secret_value(SecretId=secret_name)
        if "SecretString" in response:
            return json.loads(response["SecretString"])
        else:
            raise ValueError("Secret does not contain a valid SecretString payload.")
    except ClientError as e:
        error_code = e.response.get("Error", {}).get("Code", "Unknown")
        error_msg = e.response.get("Error", {}).get("Message", str(e))
        print(f"[-] Error fetching secret ({error_code}): {error_msg}", file=sys.stderr)
        raise


def update_aws_credentials_file(profile_name: str, access_key_id: str, secret_access_key: str):
    """Updates ~/.aws/credentials with the source base profile."""
    aws_dir = Path.home() / ".aws"
    aws_dir.mkdir(mode=0o700, exist_ok=True)
    credentials_path = aws_dir / "credentials"

    config = configparser.ConfigParser()
    if credentials_path.exists():
        config.read(credentials_path)

    if not config.has_section(profile_name):
        config.add_section(profile_name)

    config.set(profile_name, "aws_access_key_id", access_key_id)
    config.set(profile_name, "aws_secret_access_key", secret_access_key)

    with open(credentials_path, "w") as f:
        config.write(f)
    credentials_path.chmod(0o600)
    print(f"[+] Updated base credentials in: {credentials_path} [profile: {profile_name}]")


def update_aws_config_file(assumed_profile_name: str, role_arn: str, source_profile: str, region: str):
    """Updates ~/.aws/config with the assumed role profile."""
    aws_dir = Path.home() / ".aws"
    aws_dir.mkdir(mode=0o700, exist_ok=True)
    config_path = aws_dir / "config"

    config = configparser.ConfigParser()
    if config_path.exists():
        config.read(config_path)

    section_name = f"profile {assumed_profile_name}"
    if not config.has_section(section_name):
        config.add_section(section_name)

    config.set(section_name, "role_arn", role_arn)
    config.set(section_name, "source_profile", source_profile)
    config.set(section_name, "region", region)
    config.set(section_name, "output", "json")

    with open(config_path, "w") as f:
        config.write(f)
    config_path.chmod(0o600)
    print(f"[+] Updated assumed-role configuration in: {config_path} [{section_name}]")


def test_sts_role_assumption(source_access_key: str, source_secret_key: str, role_arn: str, region: str):
    """Verifies that the developer user can successfully assume the target project role."""
    print(f"\n[+] Testing STS role assumption against: {role_arn}...")
    sts_client = boto3.client(
        "sts",
        region_name=region,
        aws_access_key_id=source_access_key,
        aws_secret_access_key=source_secret_key,
    )

    try:
        caller = sts_client.get_caller_identity()
        print(f"    Base Identity: {caller['Arn']} (Account: {caller['Account']})")

        response = sts_client.assume_role(
            RoleArn=role_arn,
            RoleSessionName="SaayamDevValidationSession",
            DurationSeconds=3600,
        )
        assumed_creds = response["Credentials"]
        print("    [✓] Role assumed successfully!")
        print(f"    Assumed Role User ID: {response['AssumedRoleUser']['Arn']}")
        print(f"    Session Expiration:   {assumed_creds['Expiration']}")
        return assumed_creds
    except ClientError as e:
        print(f"    [X] Failed to assume role: {e}", file=sys.stderr)
        return None


def test_scoped_s3_access(assumed_creds: dict, bucket_name: str, region: str):
    """Tests S3 operations using temporary assumed-role credentials."""
    print(f"\n[+] Testing scoped S3 access on bucket: {bucket_name}...")
    s3_client = boto3.client(
        "s3",
        region_name=region,
        aws_access_key_id=assumed_creds["AccessKeyId"],
        aws_secret_access_key=assumed_creds["SecretAccessKey"],
        aws_session_token=assumed_creds["SessionToken"],
    )

    test_key = "profile-pics/dev-onboarding-test.txt"
    test_content = b"Saayam DevSecOps IAM Validation Successful"

    try:
        # Test PutObject
        print(f"    Attempting PutObject to '{test_key}'...")
        s3_client.put_object(Bucket=bucket_name, Key=test_key, Body=test_content)
        print("    [✓] PutObject succeeded!")

        # Test GetObject
        print(f"    Attempting GetObject from '{test_key}'...")
        obj = s3_client.get_object(Bucket=bucket_name, Key=test_key)
        content = obj["Body"].read()
        print(f"    [✓] GetObject succeeded! Read {len(content)} bytes.")

        # Test DeleteObject
        print(f"    Cleaning up test object '{test_key}'...")
        s3_client.delete_object(Bucket=bucket_name, Key=test_key)
        print("    [✓] DeleteObject succeeded!")
        print("\n[🎉] All scoped S3 permissions validated successfully!")
    except ClientError as e:
        print(f"    [X] S3 operation failed: {e}", file=sys.stderr)


def main():
    args = parse_arguments()
    secret_name = args.secret_name or f"saayam/{args.environment}/users/{args.username}/credentials"
    source_profile = f"saayam-{args.environment}-{args.username}-base"
    assumed_profile = f"saayam-{args.environment}-{args.username}"

    print("==================================================================")
    print("      Saayam DevSecOps - Developer IAM Setup & Verification       ")
    print("==================================================================")

    # 1. Fetch credentials
    try:
        creds_data = fetch_credentials_from_secrets_manager(secret_name, args.region)
    except Exception as e:
        print(
            f"\n[-] Unable to fetch secret '{secret_name}'. "
            "Ensure you have permission to read Secrets Manager.",
            file=sys.stderr,
        )
        print(f"    Details: {e}", file=sys.stderr)
        sys.exit(1)

    access_key_id = creds_data["aws_access_key_id"]
    secret_access_key = creds_data["aws_secret_access_key"]
    role_to_assume = creds_data["role_to_assume_arn"]
    project = creds_data.get("project", "volunteer")

    if args.output_json:
        safe_output = {
            "username": creds_data.get("username"),
            "developer_email": creds_data.get("developer_email"),
            "aws_access_key_id": access_key_id,
            "role_to_assume_arn": role_to_assume,
            "environment": args.environment,
            "project": project,
            "region": args.region,
        }
        print(json.dumps(safe_output, indent=2))

    # 2. Configure AWS CLI
    if args.configure_aws_cli:
        print("\n[+] Configuring local AWS CLI profiles...")
        update_aws_credentials_file(source_profile, access_key_id, secret_access_key)
        update_aws_config_file(assumed_profile, role_to_assume, source_profile, args.region)
        print("\n[✓] AWS CLI is configured! You can now run:")
        print(f"    export AWS_PROFILE={assumed_profile}")
        print("    aws sts get-caller-identity")

    # 3. Test Access
    if args.test_access:
        assumed_creds = test_sts_role_assumption(
            source_access_key=access_key_id,
            source_secret_key=secret_access_key,
            role_arn=role_to_assume,
            region=args.region,
        )
        if assumed_creds and args.test_s3_bucket:
            test_scoped_s3_access(assumed_creds, args.test_s3_bucket, args.region)

    print("\n[✓] Developer IAM setup workflow completed successfully.")


if __name__ == "__main__":
    main()
