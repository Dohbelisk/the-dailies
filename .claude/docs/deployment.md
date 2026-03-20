# Deployment & CI/CD

## GitHub Actions

Automated CI/CD pipelines in `.github/workflows/`:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | PRs to develop/main, push to develop | Runs tests for backend, admin portal, and Flutter |
| `deploy-api.yml` | Push to main (backend changes) | Tests, builds, deploys API to AWS EC2 via SSH |
| `deploy-admin.yml` | Push to main (admin-portal changes) | Deploys Admin Portal to AWS S3 + CloudFront |
| `ec2-fix.yml` | Manual dispatch | SSH to EC2: restore .env, add swap, restart PM2 |
| `version-check.yml` | Manual dispatch | Query TestFlight and Google Play versions |
| `release.yml` | Push to main, manual dispatch | Auto-bumps version, builds iOS/Android, deploys to TestFlight & Firebase |
| `deploy-ios.yml` | Manual dispatch | Manual iOS TestFlight deployment |
| `deploy-android.yml` | Manual dispatch | Manual Android Firebase deployment |

## Required GitHub Secrets

### Backend/Admin (AWS)
- `EC2_SSH_PRIVATE_KEY` - SSH private key for EC2 instance
- `EC2_HOST` - EC2 instance hostname/IP
- `AWS_ACCESS_KEY_ID` - AWS access key for S3/CloudFront deployments
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `CLOUDFRONT_DISTRIBUTION_ID` - CloudFront distribution ID for admin portal

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

## AWS Infrastructure

### API (EC2)
- NestJS backend runs on EC2 behind nginx reverse proxy
- PM2 process manager (`the-dailies-api`)
- CloudFront CDN: `https://drpxrj21aeenv.cloudfront.net`
- `.env` stored at `/opt/the-dailies/.env` (copied to `backend/.env` on deploy)
- Deploy creates backup at `backend.backup/` before replacing

### Admin Portal (S3 + CloudFront)
- Static React build deployed to S3 bucket
- CloudFront CDN: `https://d32a0jpb36axzc.cloudfront.net`

### Deploy recovery
- If API is down after deploy, run `ec2-fix.yml` workflow manually
- It restores `.env`, adds swap if missing, and restarts PM2

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

## Docker (Local Development)

```bash
docker-compose up -d
```

Containers: MongoDB 7, NestJS API, React Admin

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
