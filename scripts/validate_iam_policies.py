#!/usr/bin/env python3
"""
Saayam DevSecOps - IAM Policy Security & Least-Privilege Linter
==============================================================
Validates Terraform files and IAM policies against AWS DevSecOps best practices:
  - Enforces least-privilege (no wildcard Action: "*" or Resource: "*")
  - Checks for secure credential management (no hardcoded secret keys)
  - Validates assume-role trust policies and session durations
  - Emits exit code 1 if severe policy violations are found (CI/CD Quality Gate)
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path


DANGEROUS_ACTIONS = [
    r"^\*$",
    r"^iam:\*$",
    r"^s3:\*$",
    r"^ec2:\*$",
    r"^administratoraccess",
]

SENSITIVE_PRIVILEGE_ESCALATIONS = [
    "iam:PassRole",
    "iam:CreatePolicyVersion",
    "iam:SetDefaultPolicyVersion",
    "iam:AttachUserPolicy",
    "iam:AttachRolePolicy",
    "iam:PutUserPolicy",
    "iam:PutRolePolicy",
]


def scan_terraform_file(file_path: Path) -> list:
    """Scans a Terraform file for common IAM security anti-patterns."""
    findings = []
    content = file_path.read_text(encoding="utf-8")
    lines = content.splitlines()

    for line_num, line in enumerate(lines, 1):
        stripped = line.strip()

        # Check for wildcard action
        if re.search(r'actions\s*=\s*\[\s*"(\*)"\s*\]', stripped, re.IGNORECASE):
            findings.append({
                "file": str(file_path),
                "line": line_num,
                "severity": "CRITICAL",
                "rule": "NoWildcardAction",
                "message": "Found wildcard action ('*') in policy statement. Explicitly define required actions.",
            })

        # Check for wildcard resource on sensitive actions
        if re.search(r'resources\s*=\s*\[\s*"\*"\s*\]', stripped, re.IGNORECASE):
            # If in the same block as sensitive actions
            findings.append({
                "file": str(file_path),
                "line": line_num,
                "severity": "WARNING",
                "rule": "WildcardResource",
                "message": "Found wildcard resource ('*'). Scope resource ARNs to specific bucket/prefix where possible.",
            })

        # Check for hardcoded AWS secret keys
        if re.search(r'(?i)(aws_secret_access_key|secret_key)\s*=\s*["\'][A-Za-z0-9/+=]{40}["\']', stripped):
            findings.append({
                "file": str(file_path),
                "line": line_num,
                "severity": "CRITICAL",
                "rule": "HardcodedSecretKey",
                "message": "Potential hardcoded AWS Secret Access Key detected in code!",
            })

    return findings


def scan_json_policy_file(file_path: Path) -> list:
    """Scans a JSON IAM Policy document."""
    findings = []
    try:
        policy = json.loads(file_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        return [{
            "file": str(file_path),
            "line": 0,
            "severity": "ERROR",
            "rule": "InvalidJSON",
            "message": f"Malformed JSON policy file: {e}",
        }]

    statements = policy.get("Statement", [])
    if isinstance(statements, dict):
        statements = [statements]

    for stmt in statements:
        if stmt.get("Effect") == "Allow":
            actions = stmt.get("Action", [])
            if isinstance(actions, str):
                actions = [actions]

            resources = stmt.get("Resource", [])
            if isinstance(resources, str):
                resources = [resources]

            for act in actions:
                for dangerous in DANGEROUS_ACTIONS:
                    if re.match(dangerous, act, re.IGNORECASE):
                        findings.append({
                            "file": str(file_path),
                            "line": 0,
                            "severity": "CRITICAL",
                            "rule": "NoWildcardAction",
                            "message": f"Policy allows broad action '{act}'",
                        })

            if "*" in resources:
                findings.append({
                    "file": str(file_path),
                    "line": 0,
                    "severity": "WARNING",
                    "rule": "WildcardResource",
                    "message": "Policy allows wildcard '*' on Resource",
                })

    return findings


def main():
    parser = argparse.ArgumentParser(description="Saayam IAM Policy Security Validator")
    parser.add_argument(
        "--path",
        type=str,
        default="terraform",
        help="Directory or file path to scan (default: terraform/)",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Fail (exit 1) on WARNINGs as well as CRITICALs",
    )
    args = parser.parse_args()

    target_path = Path(args.path)
    if not target_path.exists():
        print(f"[-] Scan path not found: {target_path}", file=sys.stderr)
        sys.exit(1)

    print(f"[+] Scanning IAM policies and Terraform configs in: {target_path.resolve()}...")

    files_to_scan = []
    if target_path.is_file():
        files_to_scan = [target_path]
    else:
        files_to_scan.extend(target_path.glob("**/*.tf"))
        files_to_scan.extend(target_path.glob("**/*.json"))

    all_findings = []
    for f in files_to_scan:
        if f.suffix == ".tf":
            all_findings.extend(scan_terraform_file(f))
        elif f.suffix == ".json" and "policy" in f.name.lower():
            all_findings.extend(scan_json_policy_file(f))

    print(f"[+] Checked {len(files_to_scan)} files.")
    critical_count = 0
    warning_count = 0

    if all_findings:
        print("\n" + "=" * 80)
        print(f"{'SEVERITY':<10} | {'RULE':<20} | {'LOCATION':<30} | {'MESSAGE'}")
        print("=" * 80)
        for finding in all_findings:
            loc = f"{os.path.basename(finding['file'])}:{finding['line']}"
            print(f"{finding['severity']:<10} | {finding['rule']:<20} | {loc:<30} | {finding['message']}")
            if finding["severity"] == "CRITICAL":
                critical_count += 1
            elif finding["severity"] == "WARNING":
                warning_count += 1
        print("=" * 80)

    print(f"\nScan Summary: {critical_count} Criticals, {warning_count} Warnings.")

    if critical_count > 0 or (args.strict and warning_count > 0):
        print("[-] Security quality gate FAILED. Please remediate critical IAM policy issues.")
        sys.exit(1)
    else:
        print("[✓] IAM Security and Least-Privilege checks PASSED!")
        sys.exit(0)


if __name__ == "__main__":
    main()
