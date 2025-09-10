#!/usr/bin/python3
import boto3
from botocore.exceptions import ClientError, NoCredentialsError
from datetime import datetime, timedelta, timezone
import sys

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
        print(">> A critical Error occured: Stopping execution")
        sys.exit(0)
    
    except ClientError as e:
        if e.response['Error']['Code'] == 'AccessDenied':
            print(">> Error: Permission denied")
            print(">> Need IAM permission -> iam:ListUsers")
            print(">> A critical Error occured: Stopping execution")
            sys.exit(0)
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
                print(">> A critical Error occured: Stopping execution")
                sys.exit(0)

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
    print("\n\n********************* GET_USERS_ACCESS_KEY_INFO *********************")
    iam_client = boto3.client("iam")
    user_access_key_info = {}
    flagged_user = []

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
            #print("*"*50)
            #print(f" >> INFO : User - {user} hasnt logged in for the 100 days and no access keys have been created.\n\n")
            #delete_user_and_dependencies(user,iam_client)
            flagged_user.append({
                "UserName": user,
                "AccessKey": "NOT_CREATED",
                "Last_used":  "NO_ACCESS_KEY",
                "Status": "N/A",
                "Reason": "USER_INACTIVE_100_DAYS and NO_ACCESS_KEYS_CREATED"
                
                })

    
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
                    #print("*"*50)
                    #print(f">> INFO : {user} has not logged in for 100 days and access keys created have not been used. n\n")
                    flagged_user.append({
                        "UserName":user,
                        "AccessKey":key['AccessKeyId'],
                        "Last_used": "NEVER_USED",
                        "Status" : key['Status'],
                        "Reason": "ACCESS_KEY_NOT_USED, USER_INACTIVE_100_DAYS" })
                    #delete_user_and_dependencies(user,iam_client)
                    #print(f"{user} -- {key['AccessKeyId']} -- {None} \n\n")
                    

      
#if access key is used and 'LastUsedDate' is >=100 days delete the key, then the user. see below for the output when AccessKey is used -->
# {'LastUsedDate': datetime.datetime(2025, 9, 4, 21, 10, tzinfo=tzlocal()), 'ServiceName': 'sts', 'Region': 'us-east-2'} 
                

                else:
                    access_key_last_used_date=access_key_last_used['LastUsedDate']
                    #print("*"*50)
                    #print(f">> INFO : {user} has the below access keys created.\n\n")
                    #print(f"{user} -- {key['AccessKeyId']} -- {access_key_last_used_date.strftime('%b %d %Y %H:%M:%S')} service last used : {access_key_last_used['ServiceName']} --- Time since activity -> {(current_date-datetime.strptime(access_key_last_used_date, '%b %d %Y %H:%M:%S'))}\n")
                   
                    cutoff = datetime.now(timezone.utc) - timedelta(days=100)
                    
                    #if  access_key_last_used_date <= cutoff: 
                    #Uncomment above if condition and add indent to check for condition where Access_key was not used >=100 days.
                    flagged_user.append({
                        "UserName":user,
                        "AccessKey":key['AccessKeyId'],
                        "Last_used" : access_key_last_used_date.strftime('%b %d %Y %H:%M:%S'),
                        "Status" : key['Status'],
                        "Reason": "ACCESS_KEY_INACTIVE_100_DAYS, USER_INACTIVE_100_DAYS"
                            
                            
                            })
                        
    for user_details in flagged_user:
        print(f"\t\t\t\t\t\t\t {'*'*20} Fetching User Info {'*'*20}")
        print( f" >> INFO : Username: {user_details['UserName']} |  Access_Key: {user_details['AccessKey']} | Status : {user_details['Status']} | Last Used Date: {user_details['Last_used']} | Reason for Deletion: {user_details['Reason']}\n" )         

        if user_details['AccessKey'] == 'NOT_CREATED':
            print(f">> NOTICE : {user_details['UserName']} is inactive and has no Access Keys created. Preparing to delete user.\n ")
            delete_user_and_dependencies(user_details['UserName'], iam_client)
        else:
            if user_details['Status']  != 'Active' or user_details['Last_used'] == "NEVER_USED":
                print(f">> NOTICE : {user_details['UserName']} has been inactive and the Access keys are either Inactive or Never Used. Preparing to delete user Access Keys.\n ")
                delete_user_access_keys(user_details['UserName'], iam_client)
            else:
                print(f"NOTICE : {user_details['UserName']} has been inactive but Possess Active Keys which have not been used for 100 days. Preparing to delete user Acess Keys. \n")
                delete_user_access_keys(user_details['UserName'], iam_client)
                
                            

                
               
def get_access_key_last_used(AccessKey):
    iam_client=boto3.client("iam")
    return iam_client.get_access_key_last_used(AccessKeyId=AccessKey)['AccessKeyLastUsed']


def delete_user_access_keys(User,iam_client):
    
    print("\n\n*********** DELETE USER ACCESS KEYS ***********")
    try:
        
        keys = iam_client.list_access_keys(UserName=User)
        for key in keys['AccessKeyMetadata']:
            print("Deleting Access Key - {key['AcessKeyId']} for {User}")
            #iam_client.delete_access_key(UserName=User, AccessKeyId=key['AccessKeyId'])
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        if error_code == 'AccessDenied':
            print(">>ERROR: AWS roles are not configured. \n")
            print(">> Attach IAM role to instance to perform IAM action. Required Role: 'iam:ListAccessKeys' or 'iam:DeleteAccessKey'.\n ")
            print(">> A critical Error occured: Stopping execution")
            sys.exit(0)
            
        else:
            print("ERROR: Unexpected error for {User}: {error_code} - {error_message}.\n")



def delete_user_and_dependencies(User,iam_client):
    
    print("\n\n*********** DELETE USER AND DEPENDENCIES ***********")
    
    print(f">> NOTICE : Proceeding to delete user dependencies before deleting {User}\n ")
    
    
    #The current logic is written in one large try block, but once all the resources are identified and checks are written for each resource/service for deletion-->
    #The below code has be broken down into multuple try/except blocks to ensure the whole logic doesn't break when an exception at one API call.
    
    try:
        print("Checking if user is part of any user groups.....\n\n")
        user_groups=iam_client.list_groups_for_user(UserName=User)
        if user_groups['Groups']:
    
            for group in user_groups['Groups']:
                print(f">> INFO : {User} found in {group['GroupName']}, removing {User} from the Group : {group['GroupName']}\n\n")
           # iam_client.remove_user_from_group(GroupName = group['GroupName'],UserName=User)
        else:
            print(f">> INFO : {User} doesnt belong to any Groups\n")
    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        if error_code == 'AccessDenied':
            print(">> ERROR: AWS roles are not configured")
            print(">> Attach IAM role to instance to perform IAM action. Required Role: 'iam:GetGroupsForUser' or 'iam:RemoveUserFromGroup' \n")
            raise
        else:
            print(f"ERROR: Unexpected error for {User}: {error_code} - {error_message}\n")
            
            
    try:
            
        print("Checking if user has any MFA devices setup....\n\n")
        mfa_devices=iam_client.list_mfa_devices(UserName=User)
        if mfa_devices['MFADevices']:
            for device in mfa_devices['MFADevices']:
                print(f">> INFO : Device with Serial Number: {device['SerialNumber']} found for {User}, removing MFA device.\n\n")
                iam_client.deactivate_mfa_device(UserName=User,SerialNumber=device['SerialNumber'])
                
        else:
            print(f">> INFO : No devices found for {User}.\n\n")
    except ClientError as e:
        error_code= e.response['Error']['Code']
        error_message =e.response['Error']['Message']
        if error_code=='AccessDenied':
            print(">>ERROR: AWS roles are not configured")
            print(">> Attach IAM role to instance to perform IAM action. Required Role: 'iam:ListMFADevices' or 'iam:DeactivateMFADevice'. \n")
            print(">> A critical Error occured: Stopping execution")
            sys.exit(0)
        elif error_code == 'DeleteConflict' or error_code == 'EntityTemporarilyUnmodifiable':
            print(">> ERROR: MFA device is still active/being used.\n")
            raise
        else:
            print("ERROR: Unexpected error for {User}: {error_code} - {error_message}\n")
            raise
            
            
            
      
    try:        
            
        print("Checking if user has Inline Policies Configured ....\n\n")
        policies = iam_client.list_user_policies(UserName=User)
        if policies['PolicyNames']:
            for policy in policies['PolicyNames']:
                iam_client.delete_user_policy(UserName=User,PolicyArn=policy['PolicyArn'])
        else:
            print(f">> INFO : No User Policies present for {User}.\n\n")
    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        
        if error_code=='AccessDenied':
            print(">>ERROR: AWS roles are not configured.\n")
            print(">> Attach IAM role to instance to perform IAM action. Required Role: 'iam:ListUserPolicies' or 'iam:DeleteUserPolicy'. \n")
            print(">> A critical Error occured: Stopping execution")
            sys.exit(0)
        elif error_code == 'DeleteConflict':
            print(f"ERROR: Policy is still in use. Cannot delete Policy for user {User}.\n")
        else:
            print("ERROR: Unexpected error for {User}: {error_code} - {error_message}.\n")
            
            
            
    try:
        
        print("Checking if User has any SSH Keys enabled. \n")
        ssh_keys = iam_client.list_ssh_public_keys(UserName=User)
        if ssh_keys['SSHPublicKeys']:
            for key in ssh_keys['SSHPublicKeys']:
                print("SSH public key - {key['SSHPublicKeyId']} found for {User}, removing SSH keys.\n ")
                iam_client.delete_ssh_public_key(UserName=User,SSHPublicKeyId=key['SSHPublicKeyId'])
        else:
            print(f">>INFO: No SSH keys found for {User}")
    except ClientError as e:
        error_code= e.response['Error']['Code']
        error_message =e.response['Error']['Message']
        if error_code == 'AccessDenied':
            print(">>ERROR: AWS roles are not configured. \n")
            print(">> Attach IAM role to instance to perform IAM action. Required Role: 'iam:ListSSHPublicKeys' or 'iam:DeleteSSHPublicKey' .\n")
            print(">> A critical Error occured: Stopping execution")
            sys.exit(0)
        elif error_code =='DeleteConflict':
            print(">> ERROR: SSHKey still in use. Cannot delete SSH key for user {User}.\n")
            
        
        

    
    print(f"\n Proceeding to delete the user - {User}.\n\n")
    # Logic to Delete User to be written

    



    
if __name__=="__main__":

    # Identify all users who have been inactive for 100 days
    users_last_logged_100days = get_inactive_users()
    
    # Identify all users who have console access and those that do not
    console_users, no_console_users = get_user_with_console_access(users_last_logged_100days)
    
    # Identify all users who have programmatic access
    get_user_access_keys(console_users)
