# Google Play Store Deployment Setup

This repository uses GitHub Actions to automatically deploy to Google Play Store when version tags are pushed.

## Required GitHub Secrets

Add these secrets in your GitHub repository settings (Settings → Secrets and variables → Actions):

### 1. Android Signing Secrets
- `KEYSTORE_BASE64`: Base64 encoded keystore file
- `KEYSTORE_PASSWORD`: Password for the keystore
- `KEY_ALIAS`: Key alias name
- `KEY_PASSWORD`: Password for the key

### 2. Google Play Console Secrets
- `GOOGLE_SERVICES_JSON`: Service account JSON (as plain text, not base64)

## Setup Instructions

### Android Keystore
1. Generate a keystore if you don't have one:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Convert keystore to base64:
   ```bash
   # Windows PowerShell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks"))
   
   # Linux/Mac
   base64 upload-keystore.jks
   ```

3. Add the base64 string to `KEYSTORE_BASE64` secret

### Google Play Console Service Account
1. Go to Google Play Console → Setup → API access
2. Create a new service account or use existing one
3. Download the JSON key file
4. Copy the entire JSON content (not base64) to `GOOGLE_SERVICES_JSON` secret
5. Grant necessary permissions to the service account:
   - Release Manager (to upload APK/AAB)
   - View app information and download bulk reports

### Release Process
1. Update version in `pubspec.yaml`
2. Commit and push changes
3. Create and push a version tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
4. The workflow will automatically:
   - Build the AAB
   - Upload to Play Store internal track
   - You can then promote to alpha/beta/production from Play Console

### Manual Trigger
You can also trigger the workflow manually from GitHub Actions tab.

## Tracks
- `internal`: Internal testing (up to 100 testers)
- `alpha`: Closed testing
- `beta`: Open testing  
- `production`: Live on Play Store

Edit the `track` value in the workflow file to change the deployment target.

## What's New Files
Create release notes in `distribution/whatsnew/` directory:
- `whatsnew-en-US` (English)
- `whatsnew-es-ES` (Spanish)
- etc.

These will be automatically uploaded as release notes.