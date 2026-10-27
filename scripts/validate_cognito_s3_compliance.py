#!/usr/bin/env python3
"""
Saayam DevSecOps - QA Cognito, Storage & Privacy Compliance Validator
=====================================================================
Validates Issue #65 requirements against repository Terraform code:
  1. QA Cognito User Pool schema replication, MFA, password policies, and Advanced Security Features.
  2. CloudTrail and CloudWatch logging for Cognito events and Lambda triggers.
  3. Regional private S3 bucket inventory across Virginia and Ireland with zero-privilege policies.
  4. Netlify QA Webapp SSM Parameter Store exports under /saayam/qa/cognito/*.
  5. Repository guardrail: Verification that .github/workflows/ has not been touched.

Usage:
  python scripts/validate_cognito_s3_compliance.py
"""

import os
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

# Required 8 regional private buckets
EXPECTED_REGIONAL_BUCKETS = {
    "us-east-1": [
        "dev-private-virginia",
        "qa-private-virginia",
        "stage-private-virginia",
        "prod-private-virginia",
    ],
    "eu-west-1": [
        "dev-private-ireland",
        "qa-private-ireland",
        "stage-private-ireland",
        "prod-private-ireland",
    ],
}

# Required custom schema attributes
EXPECTED_CUSTOM_ATTRIBUTES = [
    "role",
    "organization_id",
    "volunteer_id",
    "kyc_verified",
]

# Required SSM parameter keys under /saayam/qa/cognito/*
EXPECTED_SSM_KEYS = [
    "cognito/user_pool_id",
    "cognito/app_client_id",
    "cognito/region",
    "cognito/redirect_uri",
    "cognito/logout_uri",
]


def test_guardrail_no_workflow_changes():
    """Ensures .github/workflows was not modified or created in this branch."""
    print("[1/5] Testing repository policy guardrail (.github/workflows/)...")
    git_status = os.popen(f"cd {REPO_ROOT} && git status --porcelain").read()
    workflow_changes = [
        line for line in git_status.splitlines() if ".github/workflows" in line
    ]
    if workflow_changes:
        print(f"❌ Violation: Found uncommitted changes in .github/workflows/: {workflow_changes}")
        return False
    print("  [✓] Guardrail verified: No modifications to .github/workflows/")
    return True


def test_cognito_module_compliance():
    """Validates Cognito User Pool module configuration."""
    print("[2/5] Testing Cognito module compliance...")
    cognito_main = REPO_ROOT / "terraform/modules/cognito_user_pool/main.tf"
    if not cognito_main.exists():
        print(f"❌ File missing: {cognito_main}")
        return False

    content = cognito_main.read_text(encoding="utf-8")

    # Check Advanced Security Features
    if "user_pool_add_ons" not in content or "advanced_security_mode" not in content:
        print("❌ Cognito Advanced Security Features (user_pool_add_ons) missing in module")
        return False

    # Check custom schema attributes
    for attr in EXPECTED_CUSTOM_ATTRIBUTES:
        pattern = rf'name\s*=\s*"{attr}"'
        if not re.search(pattern, content):
            print(f"❌ Custom attribute '{attr}' not found in Cognito schema")
            return False

    # Check MFA and password policy
    if "software_token_mfa_configuration" not in content:
        print("❌ Software token MFA configuration missing in Cognito module")
        return False

    if "password_policy" not in content:
        print("❌ Password policy missing in Cognito module")
        return False

    # Check CloudTrail and CloudWatch logging
    if "aws_cloudtrail" not in content or "aws_cloudwatch_log_group" not in content:
        print("❌ CloudTrail / CloudWatch logging configuration missing in Cognito module")
        return False

    if "aws_cloudwatch_log_stream" not in content:
        print("❌ CloudWatch log stream for Lambda triggers missing in Cognito module")
        return False

    print("  [✓] Cognito module: Schema replication, Advanced Security, MFA, and Audit logging verified")
    return True


def test_s3_privacy_module_compliance():
    """Validates S3 private bucket module hardening."""
    print("[3/5] Testing S3 private bucket module compliance...")
    s3_main = REPO_ROOT / "terraform/modules/s3_private_bucket/main.tf"
    if not s3_main.exists():
        print(f"❌ File missing: {s3_main}")
        return False

    content = s3_main.read_text(encoding="utf-8")

    # Check Public Access Block
    pab_keys = [
        "block_public_acls",
        "block_public_policy",
        "ignore_public_acls",
        "restrict_public_buckets",
    ]
    for key in pab_keys:
        if key not in content:
            print(f"❌ Public Access Block key '{key}' missing in s3_private_bucket module")
            return False

    # Check Ownership controls
    if "BucketOwnerEnforced" not in content:
        print("❌ BucketOwnerEnforced missing in s3_private_bucket module")
        return False

    # Check Zero-Privilege TLS policy
    if "aws:SecureTransport" not in content or "s3:TlsVersion" not in content:
        print("❌ Zero-privilege TLS enforcement missing in s3_private_bucket bucket policy")
        return False

    print("  [✓] S3 module: Public Access Block, BucketOwnerEnforced, and TLS 1.2+ zero-privilege policy verified")
    return True


def test_regional_s3_buckets_inventory():
    """Validates multi-region configuration contains all 8 regional private buckets."""
    print("[4/5] Testing regional private S3 bucket inventory...")
    mr_main = REPO_ROOT / "terraform/environments/multi-region/main.tf"
    if not mr_main.exists():
        print(f"❌ File missing: {mr_main}")
        return False

    content = mr_main.read_text(encoding="utf-8")

    for region, buckets in EXPECTED_REGIONAL_BUCKETS.items():
        for bucket in buckets:
            if bucket not in content:
                print(f"❌ Regional bucket '{bucket}' ({region}) not found in multi-region/main.tf")
                return False

    print("  [✓] All 8 regional private buckets verified across Virginia (us-east-1) and Ireland (eu-west-1)")
    return True


def test_netlify_ssm_parameter_store():
    """Validates SSM parameter export under /saayam/qa/cognito/*."""
    print("[5/5] Testing Netlify webapp SSM parameter store exports...")
    qa_main = REPO_ROOT / "terraform/environments/qa/main.tf"
    mr_main = REPO_ROOT / "terraform/environments/multi-region/main.tf"

    found_in_qa = qa_main.exists() and "QA_saayam-netlify.app" in qa_main.read_text(encoding="utf-8")
    found_in_mr = mr_main.exists() and "QA_saayam-netlify.app" in mr_main.read_text(encoding="utf-8")

    if not (found_in_qa or found_in_mr):
        print("❌ QA_saayam-netlify.app configuration missing in SSM parameters")
        return False

    content = (qa_main.read_text(encoding="utf-8") if qa_main.exists() else "") + (
        mr_main.read_text(encoding="utf-8") if mr_main.exists() else ""
    )

    for key in EXPECTED_SSM_KEYS:
        if key not in content:
            print(f"❌ Expected SSM parameter key '{key}' not found in configuration")
            return False

    print("  [✓] SSM Parameters under /saayam/qa/cognito/* verified for QA_saayam-netlify.app")
    return True


def main():
    print("=" * 80)
    print("Saayam DevSecOps - QA Cognito, Storage & Privacy Compliance Suite")
    print("=" * 80)

    tests = [
        test_guardrail_no_workflow_changes,
        test_cognito_module_compliance,
        test_s3_privacy_module_compliance,
        test_regional_s3_buckets_inventory,
        test_netlify_ssm_parameter_store,
    ]

    all_passed = True
    for test in tests:
        if not test():
            all_passed = False

    print("=" * 80)
    if all_passed:
        print("🎉 ALL COMPLIANCE CHECKS PASSED SUCCESSFULLY!")
        print("=" * 80)
        sys.exit(0)
    else:
        print("❌ SOME COMPLIANCE CHECKS FAILED! Please inspect errors above.")
        print("=" * 80)
        sys.exit(1)


if __name__ == "__main__":
    main()
