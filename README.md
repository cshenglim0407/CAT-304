# CAT-304

Refer to [mobile/assets/env/.env.example](mobile/assets/env/.env.example), create 4 files:
- [mobile/assets/env/.env.](mobile/assets/env/.env)
- [mobile/assets/env/.env.local](mobile/assets/env/.env.local)
- [mobile/assets/env/.env.development](mobile/assets/env/.env.development)
- [mobile/assets/env/.env.production](mobile/assets/env/.env.production)

Append this to [mobile/android/local.properties](mobile/android/local.properties):
```
# Facebook OAuth
FACEBOOK_APP_ID=xxx
FACEBOOK_CLIENT_TOKEN=xxx
FACEBOOK_DISPLAY_NAME=Cashlytics
```

Create [mobile/ios/Flutter/Secrets.xcconfig](mobile/ios/Flutter/Secrets.xcconfig) and paste this:
```
# Google Client ID
GOOGLE_CLIENT_ID=com.googleusercontent.apps.xxx

# Facebook OAuth
FACEBOOK_APP_ID=xxx
FACEBOOK_CLIENT_TOKEN=xxx
FACEBOOK_DISPLAY_NAME=Cashlytics
```