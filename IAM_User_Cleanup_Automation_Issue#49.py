#!/usr/bin/python3
import boto3
from botocore.exceptions import ClientError, NoCredentialsError
from datetime import datetime, timedelta, timezone

current_date = datetime.now()

def get_inactive_users():
    print("********************* GET_INACTIVE_USERS *********************")
    try:
        # Conenct to IAM
        iam_client = boto3.client('iam')
        # Define inactivity cutoff time (100 days for example)
        cutoff = datetime.now(timezone.utc) - timedelta(days=100)
        # These are the inactive users to act upon
        flagged_users = [] # This will be a list of dicts of inactive users, containing username, userID, reason
        flagged_usernames = [] # This will be a list of inactive users and contain only their username for easy use


        # Use Pagination for > 100 users. list_users method only returns 100 users per call
        paginator = iam_client.get_paginator('list_users')
        # Paginate through all the pages of IAM users
        for page in paginator.paginate():
            # Loop through all the users in each "Page"
            for user in page['Users']:
                # Identify password last used
                pw_last_used = user.get('PasswordLastUsed') # can be None

                # Flag if password last used is NEVER or used more than 100 days ago (cutoff)
                if pw_last_used is None or pw_last_used <= cutoff:
                    # Append to the list of flagged users.
                    flagged_users.append({
                        "UserName": user['UserName'],
                        "UserId": user["UserId"],
                        "Reason": "NEVER_USED" if pw_last_used is None else "INACTIVE_100_DAYS"
                    })
                    flagged_usernames.append(user['UserName'])

        # Print details
        print(f"The following number of users have been flagged: {len(flagged_usernames)}")
        print(f"----Details:")
        count = 1
        for user_details in flagged_users:
            print(f"{count}. Username: {user_details['UserName']}, Reason for inactivity: {user_details['Reason']}")
            count = count + 1
        return flagged_usernames
    
    except NoCredentialsError:
        print(">> AWS credentials are not configured")
        print(">> Attach IAM role to instance to fetch IAM information")
        return None
    
    except ClientError as e:
        if e.response['Error']['Code'] == 'AccessDenied':
            print(">> Error: Permission denied")
            print(">> Need IAM permission -> iam:ListUsers")
            return None
        else:
            print(f">> AWS Error: {e.response['Error']['Message']}")
            return None

    except Exception as e:
        print(f">> Unexpected error: {str(e)}")
        return None  
    
def get_user_with_console_access(users_100):
    print("\n\n********************* GET_USERS_WITH_CONSOLE_ACCESS *********************")
    # Conenct to IAM
    iam_client = boto3.client('iam')
    # List of users with console access (LoginProfile)
    console_users = []
    # List of users with NO console access
    no_console_users = []

    # Loop through the inactive users
    for user in users_100:
        
        try:
            # If get_login_profile method for the user exists, they have console access
            iam_client.get_login_profile(UserName=user)
            console_users.append(user)
        
        # If an error occurs, there is a possibility the user does not have console access
        except ClientError as e:
            # If error is NoSuchEntity -> Login profile does not exist
            # No Console Password
            if e.response['Error']['Code'] == 'NoSuchEntity':
                no_console_users.append(user)
                continue
            
            # If caller does not have the appropriate access
            elif e.response['Error']['Code'] == 'AccessDenied':
                print(f"sds")
                print(">> Error: Permission denied. Need IAM Permission 'iam:Get-login-profile'")
                continue

            # If there is any other AWS exception
            else:
                print(f">> AWS Error for {user}: {e.response['Error']['Message']}")
                continue

        except Exception as e:
            print(f">> Unexpected Excetion Error: {str(e)}")
            continue  
    
    print(f"Users with console access: {console_users}")
    print(f"Users with NO console access: {no_console_users}")
    return console_users, no_console_users


def get_user_access_keys(console_users):
    print("\n\n********************* GET_USERS_ACCESS_KEYS *********************")
    iam_client = boto3.client("iam")
    user_access_key_info = {}

    for user in console_users:
        response = iam_client.list_access_keys(UserName=user)
        access_keys = response.get("AccessKeyMetadata", [])

        if access_keys:
            # Collects all access keys
            user_access_key_info[user] = [
                {
                    "AccessKeyId": key["AccessKeyId"],
                    "Status": key["Status"]
                }
                for key in access_keys
            ]
            
        else:
            user_access_key_info[user] = None  # No access keys for the user
    #print(user_access_key_info,"\n\n")
    
    for user,access_key_info in user_access_key_info.items():
#check if user has access keys and if the user does not have one, then delete the user only.
#Logic in the below if condition to filter users who have no access keys.        
        if access_key_info is None:
            print(user,"--",access_key_info,"\n")
            #Logic to delete the user to be written
  
#If user has access keys, disable or delete the keys -> user and the resources.    
#The logic below is to check the LastUsedDate for the access keys and delete them based on 2 conditions. 1 -> AccessKey wasn't used , 2 -> AccessKey was used.        
        else:
            for key in access_key_info:
                access_key_last_used=get_access_key_last_used(key['AccessKeyId'])
                #print(user,"\t access key last used",access_key_last_used,"\t",key['AccessKeyId'],"\n")
                

 #if Acess key is never used, delete the accesskey and then the user. see below for the output when Accesskey is not used--->
 #{'ServiceName': 'N/A', 'Region': 'N/A'}
                #Logic for above functionality - to be written
                if access_key_last_used.get('LastUsedDate') is None:
                    print(f"{user} -- {key['AccessKeyId']} -- {None} \n\n")
      
#if access key is used and 'LastUsedDate' is >=100 days delete the key, then the user. see below for the output when AccessKey is used -->
# {'LastUsedDate': datetime.datetime(2025, 9, 4, 21, 10, tzinfo=tzlocal()), 'ServiceName': 'sts', 'Region': 'us-east-2'} 
                
                else:
                    access_key_last_used_date=access_key_last_used['LastUsedDate'].strftime("%b %d %Y %H:%M:%S")
                    print(f"{user} -- {key['AccessKeyId']} -- {access_key_last_used_date} service last used : {access_key_last_used['ServiceName']} --- Time since activity -> {(current_date-datetime.strptime(access_key_last_used_date, '%b %d %Y %H:%M:%S'))}\n")
                
               
def get_access_key_last_used(AccessKey):
    iam_client=boto3.client("iam")
    return iam_client.get_access_key_last_used(AccessKeyId=AccessKey)['AccessKeyLastUsed']
    
    
    
if __name__=="__main__":

    # Identify all users who have been inactive for 100 days
    users_last_logged_100days = get_inactive_users()
    
    # Identify all users who have console access and those that do not
    console_users, no_console_users = get_user_with_console_access(users_last_logged_100days)
    
    # Identify all users who have programmatic access
    get_user_access_keys(console_users)
