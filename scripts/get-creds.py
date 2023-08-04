import requests
import os
import argparse

parser = argparse.ArgumentParser(
                    prog="get-creds",
                    description="CLI tool to get credentials from Vault LDAP Secrets Engine",
                    formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("-r", "--role", help="The vault role to request credentials from")
parser.add_argument("-t", "--type", help="The type of credentials to request: static, dynamic, or service-account", required=True, choices=['static', 'dynamic', 'service-account'])
parser.add_argument("-a", "--action", help="The action to perform on the service-account: check-out or check-in", choices=['check-out', 'check-in'])
parser.add_argument("-l", "--list", help="List roles available in the secrets engine", action="store_true")
args = parser.parse_args()
args = vars(parser.parse_args())


vault_url = os.environ.get("VAULT_ADDR")
vault_token = os.environ.get("VAULT_TOKEN")
role = args["role"]
type = args["type"]
action = args["action"]


def get_dynamic_creds(role):
    "Get dynamic creds from a role"
    response = requests.get(f'{vault_url}/v1/vault-lab-ad/creds/{role}', headers={'Content-Type':'application/vnd.api+json', 'Authorization': 'Bearer {}'.format(vault_token)})
    return print("username: {0}\npassword: {1}".format(response.json()['data']['username'], 
                                                                 response.json()['data']['password']));


def get_static_creds(role):
    response = requests.get(f'{vault_url}/v1/vault-lab-ad/static-cred/{role}', headers={'Content-Type':'application/vnd.api+json', 'Authorization': 'Bearer {}'.format(vault_token)})
    return print("username: {0}\npassword: {1}\nlast password: {2}\nTTL: {3}s".format(response.json()['data']['username'], 
                                                                           response.json()['data']['password'], 
                                                                           response.json()['data']['last_password'], 
                                                                           response.json()['data']['ttl']));

def check_out_service_account(role):
    response = requests.post(f'{vault_url}/v1/vault-lab-ad/library/{role}/check-out', headers={'Content-Type':'application/vnd.api+json', 'Authorization': 'Bearer {}'.format(vault_token)})
    return print("username: {0}\npassword: {1}\nlease duration: {2}s".format(response.json()['data']['service_account_name'], 
                                                                           response.json()['data']['password'], 
                                                                           response.json()['lease_duration']));

def check_in_service_account(role):
    response = requests.post(f'{vault_url}/v1/vault-lab-ad/library/{role}/check-in', headers={'Content-Type':'application/vnd.api+json', 'Authorization': 'Bearer {}'.format(vault_token)})
    return print("checked_in: {0}".format(response.json()['data']['check_ins']));

def list_static_roles():
    response = requests.request('LIST',f'{vault_url}/v1/vault-lab-ad/static-role', headers={'Content-Type':'application/vnd.api+json', 'Authorization': 'Bearer {}'.format(vault_token)})
    return print(response.json()['data']['keys']);
    
def list_dynamic_roles():
    response = requests.request('LIST',f'{vault_url}/v1/vault-lab-ad/role', headers={'Content-Type':'application/vnd.api+json', 'Authorization': 'Bearer {}'.format(vault_token)})
    return print(response.json()['data']['keys']);
    
def list_service_account_libraries():
    response = requests.request('LIST',f'{vault_url}/v1/vault-lab-ad/library', headers={'Content-Type':'application/vnd.api+json', 'Authorization': 'Bearer {}'.format(vault_token)})
    return print(response.json()['data']['keys']);

if args["list"] :
    match type:
        case "static":
            list_static_roles()
        case "dynamic":
            list_dynamic_roles()
        case "service-account":
            list_service_account_libraries()
else :
    match type:
        case "static":
            get_static_creds(role)
        case "dynamic":
            get_dynamic_creds(role)
        case "service-account":
            if action == "check-out":
                check_out_service_account(role)
            elif action == "check-in":
                check_in_service_account(role)
# if type == "dynamic" :
#     get_dynamic_creds(role)

# if type == "static" :
#     get_static_creds(role)

# if type == "service-account" :
#     if action == "check-out" :
#         check_out_service_account(role)
#     if action == "check-in" :
#         check_in_service_account(role)