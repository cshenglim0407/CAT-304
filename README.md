# CAT-304

Create `mobile/assets/.env.local` and `mobile/assets/.env.production` in `mobile/assets/.env` folder based on `mobile/assets/.env.example` scheme

Append this to `mobile/android/local.properties`:
```
# Facebook OAuth Redirect URI
FACEBOOK_APP_ID=xxx
FACEBOOK_CLIENT_TOKEN=xxx
FACEBOOK_DISPLAY_NAME=Cashlytics
```

Create `mobile/ios/Flutter/Secrets.xcconfig` and paste this:
```
FACEBOOK_APP_ID=xxx
FACEBOOK_CLIENT_TOKEN=xxx
FACEBOOK_DISPLAY_NAME=Cashlytics
```