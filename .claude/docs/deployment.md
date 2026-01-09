# Deployment & CI/CD

## GitHub Actions

Automated CI/CD pipelines in `.github/workflows/`:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | PRs to develop/main, push to develop | Runs tests for backend, admin portal, and Flutter |
| `deploy-api.yml` | Push to main (backend changes) | Deploys API to Render |
| `deploy-admin.yml` | Push to main (admin-portal changes) | Deploys Admin Portal to Render |
| `release.yml` | Push to main, manual dispatch | Auto-bumps version, builds iOS/Android, deploys to TestFlight & Firebase |
| `deploy-ios.yml` | Manual dispatch | Manual iOS TestFlight deployment |
| `deploy-android.yml` | Manual dispatch | Manual Android Firebase deployment |

## Required GitHub Secrets

### Backend/Admin
- `RENDER_DEPLOY_HOOK_URL` - Render deploy hook URL for API service
- `RENDER_ADMIN_DEPLOY_HOOK_URL` - Render deploy hook URL for Admin Portal

### iOS Code Signing
- `IOS_CERTIFICATE_BASE64` - Base64-encoded .p12 distribution certificate
- `IOS_CERTIFICATE_PASSWORD` - Password for the .p12 certificate
- `IOS_PROVISIONING_PROFILE_BASE64` - Base64-encoded .mobileprovision file
- `KEYCHAIN_PASSWORD` - Password for temporary CI keychain
- `APP_STORE_CONNECT_API_KEY_KEY` - Base64-encoded App Store Connect API key (.p8)
- `APP_STORE_CONNECT_API_KEY_KEY_ID` - App Store Connect API key ID
- `APP_STORE_CONNECT_API_KEY_ISSUER_ID` - App Store Connect API issuer ID

### Android Code Signing
- `ANDROID_KEYSTORE_BASE64` - Base64-encoded .jks keystore
- `ANDROID_KEYSTORE_PASSWORD` - Keystore password
- `ANDROID_KEY_ALIAS` - Key alias
- `ANDROID_KEY_PASSWORD` - Key password
- `FIREBASE_SERVICE_ACCOUNT` - Firebase service account JSON for App Distribution

## Required GitHub Variables

- `API_URL` - Production API URL
- `ADMIN_URL` - Production Admin Portal URL
- `VITE_API_URL` - API URL for admin portal build

## Setting up Render Deploy Hooks

1. Go to your Render service dashboard
2. Navigate to Settings → Deploy Hook
3. Copy the hook URL
4. Add it as a secret in GitHub: Settings → Secrets and variables → Actions

## Setting up iOS Code Signing

1. Create Apple Distribution certificate in Apple Developer portal
2. Export as .p12 with password
3. Download App Store provisioning profile (.mobileprovision)
4. Base64 encode both:
   ```bash
   base64 -i certificate.p12
   base64 -i profile.mobileprovision
   ```
5. Create App Store Connect API key for Fastlane upload

## Docker

```bash
docker-compose up -d
```

Containers: MongoDB 7, NestJS API, React Admin

## Render.com

Configuration in `render.yaml`:
- Backend: Node runtime, health check at `/api/puzzles/today`
- Admin: Static site with SPA rewrite

## Environment Variables

### Backend
```
MONGODB_URI      # MongoDB connection string
JWT_SECRET       # JWT signing secret
CORS_ORIGINS     # Allowed origins (comma-separated)
FEEDBACK_EMAIL   # Email for feedback notifications
PORT             # Server port (default: 3000)
```

### Admin Portal
```
VITE_API_URL     # Backend API URL
```

### Flutter App
Update API URL in:
- `flutter_app/lib/config/environment.dart`
- `flutter_app/lib/services/api_service.dart`
