#!/usr/bin/python3
import boto3
from botocore.exceptions import ClientError, NoCredentialsError
from datetime import datetime, timedelta

current_date = datetime.now()


def get_users():
    
    try:
        iam_client=boto3.client('iam')
        users_info= iam_client.list_users()
        #print(users_info)
        
        #today = datetime.now()

        filtered_users = []
        for user in users_info["Users"]:
            username = user["UserName"]
            user_id = user["UserId"]
            password_last_used = user.get("PasswordLastUsed")  # can be None

           #logic to check users who last logged in 100 days ago goes here. None for never logged in.(Currently using not None to check funtionality).
            if password_last_used is None or password_last_used is not None: #or password_last_used <= today:
                filtered_users.append({
                    "UserName": username,
                    "UserId": user_id,
                    "PasswordLastUsed": password_last_used.date().strftime("%b %d %Y %H:%M:%S") if password_last_used else None
                })
        usernames=[]
        for i in filtered_users:
            usernames.append(i['UserName'])
        print(usernames)
        return usernames
    
    except NoCredentialsError:
      print(" AWS credentials are not configured")
      print("Attach IAM role to instance to fetch IAM information")
      return None
    
      
    except ClientError as e:
       if e.response['Error']['Code'] == 'AccessDenied':
          print(" Error: Permission denied")
          print("Need IAM permission -> iam:ListUsers")
          return None
       else:
          print(f"AWS Error: {e.response['Error']['Message']}")
          return None
    except Exception as e:
      print(f" Unexpected error: {str(e)}")
      return None  
    
  
    
def get_user_with_console_access(users_100):
    iam_client = boto3.client('iam')
    console_user_info=[]
    for user in users_100:
        
        try:
            console_user_info.append(iam_client.get_login_profile(UserName=user)['LoginProfile']['UserName'])
            print(f"User {user} has console access","\n")
           
            
        except ClientError as e:
            if e.response['Error']['Code'] == 'NoSuchEntity':
                print(f"User {user} has NO console access")
            if e.response['Error']['Code'] == 'AccessDenied':
               print(" Error: Permission denied")
               print("Need IAM permission: iam:Get-login-Profile")
               return None
            else:
                print(f"AWS Error: {e.response['Error']['Message']}")
                return None
    print(console_user_info,"\n\n")
    
    return console_user_info



def get_user_access_keys(console_users):
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
    users_last_logged_100days=get_users()
    
    console_users=get_user_with_console_access(users_last_logged_100days)
    
    get_user_access_keys(console_users)
    
    
    
