# Call a Secured API Using JSON Web Token (JWT) Profile

## Prerequisites to Run the Samples

- Clone this repository.
- Have python3 and pip3 installed in your machine.
- Install required dependencies by running `pip3 install -r requirements.txt` on your terminal.
- Deploy ZITADEL instance into kubernetes cluster. This will create a default **Machine** with `IAM_OWNER` role.
- Make sure that you replace the values in the .env file in each project with the values you obtain from ZITADEL.

## Generate the Token

Execute the following command to get the `client-key-file` in json format created automatically by ZIDATEL.

```bash
kubectl get -n iam secrets zitadel-admin-sa -o=jsonpath='{.data.zitadel-admin-sa\.json}' | base64 --decode | jq . > docs/iam/service-user-jwt/client-key-file.json
```

### 1. The downloaded key will be of the following format

```json
{
    "type":"serviceaccount",
    "keyId":"<YOUR_KEY_ID>",
    "key":"-----BEGIN RSA PRIVATE KEY-----\n<YOUR_KEY>\n-----END RSA PRIVATE KEY-----\n",
    "userId":"<YOUR_USER_ID>"
}
```

Set the environment variables in `.env` file

```bash
CLIENT_PRIVATE_KEY_FILE_PATH = "client-key-file.json"
PROJECT_ID="zitadel"
ZITADEL_DOMAIN = "https://zitadel.javstudio.org"
ZITADEL_TOKEN_URL = "https://zitadel.javstudio.org/oauth/v2/token"
```

### 2. Generate the token

This process will generate a token using the private key from `client-key-file`.

1. cd to this directory: `cd service-user-jwt/`
2. Copy the content in your downloaded key file to `client-key-file.json`.
3. Replace the values of PROJECT_ID, ZITADEL_DOMAIN and ZITADEL_TOKEN_URL in the `.env file` with your values you obtained earlier.
4. Run the script to generate a token by running `python3 jwt-profile-token-generator.py` in the terminal.
5. Copy the printed access token and set the value to a shell variable called `TOKEN` as shown below.

```bash
# Execute following command
cd docs/iam/service-user-jwt/
python3 jwt-profile-token-generator.py

# Get only the token
python3 jwt-profile-token-generator.py | grep "Access token:" | awk '{print $3}'
```

Because conflicting python jwt libraries, you could have the following error `jwt.encode`.

```bash
pip3 uninstall jwt
pip3 uninstall PyJWT
pip3 install PyJWT
```

### 3. Invoke the API with Token

Create a random user

```bash
# https://zitadel.com/docs/apis/resources/mgmt/management-service-import-human-user
export ZITADEL_URL=zitadel.javstudio.org
export ZITADEL_PAT=$(python3 jwt-profile-token-generator.py | grep "Access token:" | awk '{print $3}')

# Create a User
curl -L -k -X POST "https://$ZITADEL_URL/management/v1/users/human/_import" \
-H 'Content-Type: application/json' \
-H 'Accept: application/json' \
-H "Authorization: Bearer $ZITADEL_PAT" \
--data-raw '{
  "userName": "admin",
  "profile": {
    "firstName": "admin",
    "lastName": "admin",
    "nickName": "admin",
    "displayName": "Admin",
    "preferredLanguage": "en",
    "gender": "GENDER_MALE"
  },
  "email": {
    "email": "admin@zitadel.com",
    "isEmailVerified": true
  },
  "phone": {
    "phone": "+41 71 000 00 00",
    "isPhoneVerified": true
  },
  "password": "RootPassword1!",
  "hashedPassword": {
    "value": "$2a$12$8p.NrnjLvA/lMC.5kS.LLeja7vc8W.oQt.3d.vwWsAfiJs8juUMiy"
  },
  "passwordChangeRequired": false,
  "requestPasswordlessRegistration": false
}' \
| jq .
```

List Member roles

```bash

curl -L -k -X POST "https://$ZITADEL_URL/management/v1/orgs/members/roles/_search" \
-H 'Accept: application/json' \
-H "Authorization: Bearer $ZITADEL_PAT" \
| jq .
```

Add Role To User

```bash
export ZITADEL_USER_ID=257116669862740269
export ZITADEL_USER_ROLE=ORG_OWNER
curl -L -k -X POST "https://$ZITADEL_URL/management/v1/orgs/me/members" \
-H 'Content-Type: application/json' \
-H 'Accept: application/json' \
-H "Authorization: Bearer $ZITADEL_PAT" \
--data-raw "{
  \"userId\": \"$ZITADEL_USER_ID\",
  \"roles\": [
    \"$ZITADEL_USER_ROLE\"
  ]
}" \
| jq .
```

Get all members of the organization

```bash
curl -L -k -X POST "https://$ZITADEL_URL/management/v1/orgs/me/members/_search" \
-H 'Content-Type: application/json' \
-H 'Accept: application/json' \
-H "Authorization: Bearer $ZITADEL_PAT" \
--data-raw '{
  "query": {
    "offset": "0",
    "limit": 100,
    "asc": true
  },
  "queries": []
}' \
| jq .
```
