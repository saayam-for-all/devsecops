import boto3, os
import json
from botocore.exceptions import ClientError
import config

s3 = boto3.client("s3", region_name=CONFIG_REGION)
s3control = boto3.client("s3control", region_name=CONFIG_REGION)
sts = boto3.client("sts")
sns = boto3.client("sns", region_name=CONFIG_REGION)
SNS_TOPIC_ARN = CONFIG_SNS_TOPIC_ARN

try:
    access_analyzer = boto3.client("accessanalyzer")
except Exception:
    access_analyzer = None

ACCOUNT_ID = sts.get_caller_identity()["Account"]

#-------------- Desired Configurations for Compliance ---------------#

DESIRED_BPA = {
    "BlockPublicAcls": True,
    "IgnorePublicAcls": True,
    "BlockPublicPolicy": True,
    "RestrictPublicBuckets": True
}

# Define the encryption configuration for SSE-S3 - Use this instead of KMS for buckets that are non-compliant
DESIRED_ENCRYPTION = {
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }

# Setting for DRY-RUN, use DRY_RUN=true/false in CLI. TRUE -> no updates to the buckets will occur
DRY_RUN = os.getenv("DRY_RUN", "true").lower() == "true"

#---------------- Bucket List/Dicts for Reporting -----------------#
NON_COMPLIANT_BUCKETS = {}
ORIGINAL_COMPLIANT_BUCKETS = []
UPDATED_BUCKETS = []

#==================================================================#
#---------------- Helper Functions ----------------#
def enforce_bucket_pab(bucket_name):
    print(f"\n-----> ENFORCE BUCKET PAB")
    # Get the current public access block on the bucket
    try:
        response = s3.get_public_access_block(Bucket=bucket_name)
        current_policy = response["PublicAccessBlockConfiguration"]
    # Display error
    except ClientError as e:
        error_code = e.response["Error"]["Code"]
        if error_code == "NoSuchPublicAccessBlockConfiguration":
            print(f"❌ Public Access Block (PAB) Configuration Not Found")
            current_policy = None
        else:
            raise

    #print(f"Current Bucket Policy: {current_policy}")

    # If PBA retrieval is successful, check against desired BPA settings
    reasons = {}

    # If no policy exists
    if not current_policy:
        reasons["Policy"] = "No PublicAccessBlock configuration set"
    
    else:
        # Go through each desired BPA key and check against current policy on the bucket
        # This is done to gather all the reasons that the bucket is non-compliant
        for key, desired in DESIRED_BPA.items():
            if current_policy.get(key) != desired:
                reasons[key] = f"Current Settings is {current_policy.get(key)}"

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
                if bucket_name not in UPDATED_BUCKETS:
                    UPDATED_BUCKETS.append(bucket_name)
                print(f"Success")
            except ClientError as e:
                print(f"[-] Error occurred in updating Public Access Block on Bucket: {bucket_name}")
                print(f"Error: {e}\n")
                raise
    else:
        # Append to ORIGINAL_COMPLIANT_BUCKETS if the bucket was already compliant
        ORIGINAL_COMPLIANT_BUCKETS.append(bucket_name)
    
    print("Completed.")
    return
    
def enforce_default_encryption(bucket_name):
    print(f"\n-----> ENFORCE DEFAULT ENCRYPTION")
    # If default encryption retrieval is successful, check encryption settings and put in sse-report
    sse_report = {}

    try:
        response = s3.get_bucket_encryption(Bucket=bucket_name)
        current_encryption = response['ServerSideEncryptionConfiguration']
    except ClientError as e:
        error_code = e.response["Error"]["Code"]
        if error_code == "ServerSideEncryptionConfiguration":
            print(f"❌ Server Side Encryption Not Found")
            current_encryption = None
        else:
            raise

    #print(f"Current Encryption: {current_encryption}")
    sse_report["Bucket"] = bucket_name
    # If no policy exists
    if not current_encryption:
        # If no encryption exists, it is a non-compliant bucket
        sse_report["Default Encryption"] = "No server side encryption settings found"
        NON_COMPLIANT_BUCKETS[bucket_name] = sse_report
    
    else:
        rules = current_encryption['Rules'][0]
        encryption = rules['ApplyServerSideEncryptionByDefault']
        BucketKeyEnabled = rules['BucketKeyEnabled']
        #print(f"encryption: {encryption}, BucketKeyEnabled: {BucketKeyEnabled}\n\n")

        # Check if SSEAlgorithm = AES256
        if encryption['SSEAlgorithm'] == 'AES256':
            # If SSE-S3 exists, it is a compliant S3 bucket
            sse_report['ServerSideEncryption'] = f"SSE-S3 ({encryption['SSEAlgorithm']}) enabled. (BucketKeyEnabled={BucketKeyEnabled})"
            if bucket_name not in ORIGINAL_COMPLIANT_BUCKETS:
                ORIGINAL_COMPLIANT_BUCKETS.append(bucket_name)
        elif encryption['SSEAlgorithm'] == 'aws:kms':
            # If SSE-KMS exists, it is a compliant S3 bucket
            kms_key = rules['ApplyServerSideEncryptionByDefault'].get('KMSMasterKeyID')
            sse_report['ServerSideEncryption'] = f"SSE-KMS (kms-key: {kms_key}) enabled. (BucketKeyEnabled={BucketKeyEnabled})"
            if bucket_name not in ORIGINAL_COMPLIANT_BUCKETS:
                ORIGINAL_COMPLIANT_BUCKETS.append(bucket_name)
        else:
            # If unknown SSE exists, assign it as non-compliant bucket ---- NEED TO KNOW HOW TO HANDLE?
            sse_report['ServerSideEncryption'] = f"Unexpected Server Side Encryption Enabled: {encryption}"


    # print(f"SSE REPORT:\n{sse_report}\n")
    if len(NON_COMPLIANT_BUCKETS) != 0 and not DRY_RUN:
        
        # If not DRY_RUN, then proceed to update the settings to ensure compliance
        if not DRY_RUN:
            print(f"[+] Updating Server Side Encryption on Bucket: {bucket_name}")
            try:
                # Update PBA settings
                s3.put_bucket_encryption(
                    Bucket=bucket_name, 
                    ServerSideEncryptionConfiguration=DESIRED_ENCRYPTION
                    )
                # Append to the UPDATED_BUCKETS list
                if bucket_name not in UPDATED_BUCKETS:
                    UPDATED_BUCKETS.append(bucket_name)
                    print(f"Success")
            except ClientError as e:
                print(f"[-] Error occurred in updating Server Side Encryption on Bucket: {bucket_name}")
                print(f"Error: {e}\n")
                raise
    print("Completed.")
    return sse_report


def lambda_handler(event, context):

    summary = {
        "account_bpa_changed": False,
        "buckets_checked": 0
    }

    encryption_report = []
    all_buckets = s3.list_buckets()

    for bucket in all_buckets.get("Buckets", []):
        bucket_name = bucket['Name']
        print(f"\n========================================================")
        print(f"*********** BUCKET NAME: {bucket_name} ***********")
        summary["buckets_checked"] += 1
        enforce_bucket_pab(bucket_name)
        encryption_report.append(enforce_default_encryption(bucket_name))


    print(f"\n\n\n==================================================")
    print(f"*********** REPORT ***********")
    print(f"Number of S3 Buckets Checked: {summary['buckets_checked']}\n")
    print(f"Original Compliant Buckets: \n{ORIGINAL_COMPLIANT_BUCKETS}\n")
    print(f"Non Compliant Buckets: \n{NON_COMPLIANT_BUCKETS}\n")
    print(f"Updated Compliant Buckets: \n{UPDATED_BUCKETS} \n")
    print(f"Encryption Report: \n{encryption_report}\n\n")

    # Send SNS Alert
    if NON_COMPLIANT_BUCKETS:
        message = "Non-Compliant Buckets:\n" + "\n".join(NON_COMPLIANT_BUCKETS)
        try:
            response = sns.publish(
                TopicArn=SNS_TOPIC_ARN, 
                Subject="S3 Compliance Alert", 
                Message=message
            )
            print(f"[+] SNS Message published successfully. Message ID: {response['MessageId']}\n")
        except Exception as e:
            print(f"[-] Error publishing message: {e}\n")


    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }


if __name__ == "__main__":
    result = lambda_handler(event={}, context=None)
    print(json.dumps(result, indent=2))