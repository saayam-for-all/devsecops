# S3 Daily Compliance & Security Automation #31
## Desired Outcome:
Ensure all S3 buckets stay compliant with AWS security best practices daily, without manual effort. Implement a Python-based AWS Lambda function triggered by Amazon EventBridge to:

- Block public access
- Enable default encryption
- Enable versioning
- Validate bucket policies
- Log actions to CloudWatch
- Send alerts via SNS on non-compliance

## Current Status:
The script can be run using EC2 SSH via VSCode. See **How to test** section to run this script in your own EC2 environment to test.

### Public Access Block
Checks all buckets for PAB policies - see function`check_bucket_bpa(bucket_name)` in the `lambda_handler` function. The **DESIRED_BPA** dict shows the desired Block Public Access to ensure security and compliance. When each bucket's PAB setting is checked, it is checked against the **DESIRED_BPA** and if it does not have the same values it is added to the **NON_COMPLIANT_BUCKETS**. Otherwise a PAB bucket is added to the **ORIGINAL_COMPLIANT_BUCKETS**. This is done for easy reporting at the end. 

Once a bucket's PAB settings is updated, it is added to **UDPATED_BUCKETS**. Again, this is to visualize the report at the end which can help us understand how many buckets were originally compliant, how many were non-compliant and how many were updated.

### Report
Prints a report for all original compliant buckets, non-compliant buckets and updated compliant buckets. Currently the report only display BPA checks.

## To-Dos:
- Still need to update the other settings in the script.
- Create the IAM Roles in Saayam AWS environment
- Create the Lambda functions with the script zipped file in Saayam AWS environment
- Run testing on Saayam AWS environment

## How to test in local test account:
1. In your **own AWS test account**, create an IAM role for EC2 instance with the following permissions:
    ```json
   {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets",
                "s3:GetBucketLocation",
                "s3:GetBucketPolicy",
                "s3:GetBucketPolicyStatus",
                "s3:GetBucketPublicAccessBlock",
                "s3:GetBucketVersioning",
                "s3:GetEncryptionConfiguration",
                "s3:PutBucketVersioning",
                "s3:PutBucketPolicy",
                "s3:PutBucketPublicAccessBlock"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Statement2",
            "Effect": "Allow",
            "Action": [
                "s3:GetAccountPublicAccessBlock",
                "s3:PutAccountPublicAccessBlock"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Statement3",
            "Effect": "Allow",
            "Action": [
                "access-analyzer:ValidatePolicy",
                "sns:Publish"
            ],
            "Resource": [
                "*",
                "arn:aws:sns:ca-central-1:304906330544:s3-sns-topic"
            ]
        }
    ]
  }

3. Spin up an EC2 instance and attach the IAM policy
4. Access your EC2 instance via the VSCode SSH
5. Create dummy buckets with different permissions for testing
6. Install the necessary python libraries (e.g. boto3)
7. Create a new file in the directory (e.g. `s3security.py`)
8. Run the following command for testing: `DRY_RUN=true python3 s3security.py`. **Ensure DRY_RUN is set to TRUE otherwise the code will actually update the bucket policies.**
9. To test if the script actually updates the bucket policies run the folowing command for testing: `DRY_RUN=false python3 s3security.py`

