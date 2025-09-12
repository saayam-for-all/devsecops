import boto3, os
import json
from botocore.exceptions import ClientError

s3 = boto3.client("s3", region_name="ca-central-1")
s3control = boto3.client("s3control", region_name="ca-central-1")
sts = boto3.client("sts")

try:
    access_analyzer = boto3.client("accessanalyzer")
except Exception:
    access_analyzer = None

ACCOUNT_ID = sts.get_caller_identity()["Account"]

DESIRED_BPA = {
    "BlockPublicAcls": True,
    "IgnorePublicAcls": True,
    "BlockPublicPolicy": True,
    "RestrictPublicBuckets": True
}
DRY_RUN = os.getenv("DRY_RUN", "true").lower() == "true"
NON_COMPLIANT_BUCKETS = {}
ORIGINAL_COMPLIANT_BUCKETS = []
UPDATED_BUCKETS = []

def check_bucket_bpa(bucket_name):
    # Get the current public access block on the bucket
    try:
        response = s3.get_public_access_block(Bucket=bucket_name)
        current_policy = response["PublicAccessBlockConfiguration"]
        bpa_policy_exists = True
    # Display error
    except ClientError as e:
        error_code = e.response["Error"]["Code"]
        if error_code == "NoSuchPublicAccessBlockConfiguration":
            current_policy = {}
        else:
            raise

    print(f"Current Bucket Policy: {current_policy}")

    # If PBA retrieval is successful, check against desired BPA settings
    reasons = {}

    # If no policy exists
    if not current_policy:
        reasons["Policy"] = "No PublicAccessBlock configuration set"
    
    # Go through each desired BPA key and check against current policy on the bucket
    # This is done to gather all the reasons that the bucket is non-compliant
    for key, desired in DESIRED_BPA.items():
        if current_policy.get(key) != desired:
            reasons[key] = f"Set to {current_policy.get(key)}"

    # If non-compliant reasons exist
    if reasons:
        # Update the NON_COMPLIANT_BUCKETS with the bucket and its reasons
        NON_COMPLIANT_BUCKETS[bucket_name] = reasons

        # If not DRY_RUN, then proceed to update the settings to ensure compliance
        if not DRY_RUN:
            print(f"[+] Updating Public Access Block on Bucket: {bucket_name}")
            try:
                # Update PBA settings
                s3.put_public_access_block(
                    Bucket=bucket_name, 
                    PublicAccessBlockConfiguration=DESIRED_BPA
                    )
                # Append to the UPDATED_BUCKETS list
                UPDATED_BUCKETS.append(bucket_name)
                print(f"Success")
            except ClientError as e:
                print(f"[-] Error occurred in updating Public Access Block on Bucket: {bucket_name}")
                print(f"Error: {e}\n")
    else:
        # Append to ORIGINAL_COMPLIANT_BUCKETS if the bucket was already compliant
        ORIGINAL_COMPLIANT_BUCKETS.append(bucket_name)
    

def lambda_handler(event, context):
    summary = {
        "account_bpa_changed": False,
        "buckets_checked": 0
    }

    all_buckets = s3.list_buckets()

    for bucket in all_buckets.get("Buckets", []):
        bucket_name = bucket['Name']
        print(f"\nBucket name: {bucket_name}")
        summary["buckets_checked"] += 1
        check_bucket_bpa(bucket_name)

    print(f"\n\n---- REPORT ----")
    print(f"Original Compliant Buckets: \n{ORIGINAL_COMPLIANT_BUCKETS}\n")
    print(f"Non Compliant Buckets: \n{NON_COMPLIANT_BUCKETS}\n")
    print(f"Updated Compliant Buckets: \n{UPDATED_BUCKETS} \n\n")

    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }


if __name__ == "__main__":
    result = lambda_handler(event={}, context=None)
    print(json.dumps(result, indent=2))