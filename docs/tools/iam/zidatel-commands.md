# README

```bash
# https://zitadel.com/docs/apis/resources/mgmt/management-service-import-human-user
export ZITADEL_URL=zitadel.javiersant.com
export ZITADEL_PAT=Jf6MOx9h9UaWEfPuWZzCbho13KQSnbwNHNhJaVfpAXz2IxsFVfe7DI9Rqo5lurEI24ryiHM

# Create a User
curl -L -k -X POST "https://$ZITADEL_URL/management/v1/users/human/_import" \
-H 'Content-Type: application/json' \
-H 'Accept: application/json' \
-H "Authorization: Bearer $ZITADEL_PAT" \
--data-raw '{
  "userName": "minnie-mouse",
  "profile": {
    "firstName": "Minnie",
    "lastName": "Mouse",
    "nickName": "Mini",
    "displayName": "Minnie Mouse",
    "preferredLanguage": "en",
    "gender": "GENDER_FEMALE"
  },
  "email": {
    "email": "minnie@mouse.com",
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

curl -k "https://$ZITADEL_URL/api/public"

curl -k "https://$ZITADEL_URL/api/private-scoped" \
-H "Authorization: Bearer $ZITADEL_PAT"

# Create an user an associate it with a Identity provider (IDP)
curl -L -k -X POST "https://$ZITADEL_URL/management/v1/users/human/_import" \
-H 'Content-Type: application/json' \
-H 'Accept: application/json' \
-H "Authorization: Bearer $ZITADEL_PAT" \
--data-raw '{
  "userName": "minnie-mouse",
  "profile": {
    "firstName": "Minnie",
    "lastName": "Mouse",
    "nickName": "Mini",
    "displayName": "Minnie Mouse",
    "preferredLanguage": "en",
    "gender": "GENDER_FEMALE"
  },
  "email": {
    "email": "minnie@mouse.com",
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
  "requestPasswordlessRegistration": true,
  "otpCode": "string",
  "idps": [
    {
      "configId": "idp-config-id",
      "externalUserId": "idp-config-id",
      "displayName": "minnie.mouse@gmail.com"
    }
  ]
}' \
| jq .
```
