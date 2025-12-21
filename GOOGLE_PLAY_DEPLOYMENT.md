# 🚀 Google Play Store Deployment Guide - FocusFlow

## ⚠️ Important: Google Play AAB Requirement

**Google Play Store no longer accepts APK files.** You must upload an **Android App Bundle (AAB)** for store distribution.

---

## 🔐 Step 1: Create Signing Key

### Method 1: Android Studio (Recommended)

1. **Open FocusFlow project** in Android Studio
2. Go to **Build → Generate Signed Bundle / APK**
3. Select **Android App Bundle**
4. Click **Create new** keystore
5. **Fill keystore details:**
   ```
   Keystore path: C:\Users\[YOUR_USERNAME]\focusflow-release-key.jks
   Password: [CREATE_SECURE_PASSWORD]
   Key alias: focusflow-key
   Key password: [SAME_OR_DIFFERENT_PASSWORD]
   Validity (years): 25
   First and Last Name: FocusFlow
   Organizational Unit: Mobile App
   Organization: FocusFlow
   City: [Your City]
   State: [Your State]
   Country Code: [Your Country]
   ```
6. Click **OK** to generate keystore

### Method 2: Command Line

```bash
# Navigate to project root
cd C:\Users\DELL.COM\Desktop\Darey\focusflow_flutter

# Create keystore
keytool -genkey -v -keystore focusflow-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias focusflow-key

# You'll be prompted for:
# - Keystore password
# - Key password
# - Name and organization details
```

---

## ⚙️ Step 2: Configure Build Signing

### Create key.properties file

Create `android/key.properties`:
```properties
storePassword=[YOUR_KEYSTORE_PASSWORD]
keyPassword=[YOUR_KEY_PASSWORD]
keyAlias=focusflow-key
storeFile=C:\\Users\\[USERNAME]\\focusflow-release-key.jks
```

### Update android/app/build.gradle

Add **before** the `android {` block:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Update the `android` block to include:
```gradle
android {
    // ... existing configuration
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

## 📦 Step 3: Build Android App Bundle

### Using Flutter Command Line
```bash
# Navigate to project root
cd C:\Users\DELL.COM\Desktop\Darey\focusflow_flutter

# Clean previous builds
flutter clean
flutter pub get

# Build signed AAB for release
flutter build appbundle --release
```

### Using Android Studio
1. **Build → Generate Signed Bundle / APK**
2. Select **Android App Bundle**
3. Choose **Use existing keystore**
4. Browse to your `focusflow-release-key.jks`
5. Enter passwords
6. Select **release** build variant
7. Click **Create**

### Find Your AAB File
The signed AAB will be located at:
```
build/app/outputs/bundle/release/app-release.aab
```

---

## 📱 Step 4: Upload to Google Play Console

1. **Go to** [Google Play Console](https://play.google.com/console)
2. **Create new app** or select existing FocusFlow app
3. **Navigate to** Release → Production
4. **Click** "Create new release"
5. **Upload** your `app-release.aab` file
6. **Fill out** app details:
   - App name: FocusFlow
   - Description: [Your app description]
   - Screenshots: [Add screenshots]
   - Privacy Policy: [Required URL]
7. **Submit for review**

---

## 🛡️ Security & Backup

### Secure Your Keystore
- **Backup keystore file** to multiple secure locations
- **Store passwords** in a password manager
- **Never commit** keystore or `key.properties` to Git

### Update .gitignore
Add these lines to your `.gitignore`:
```gitignore
# Keystore and signing
android/key.properties
*.jks
*.keystore
```

---

## ⚠️ Critical Warnings

### Keystore Loss = Cannot Update App
If you **lose your keystore**, you **CANNOT update your app** on Google Play Store. You would need to:
- Publish as a completely new app
- Change package name
- Lose all existing users and reviews

### Backup Checklist
- [ ] Keystore file backed up to cloud storage
- [ ] Keystore file backed up to external drive
- [ ] Passwords saved in password manager
- [ ] Keystore details documented securely

---

## 🔄 Future Updates

For app updates, use the same process:
```bash
# Update version in pubspec.yaml first
# version: 1.0.1+2

flutter build appbundle --release
```

Upload the new AAB to Google Play Console as a new release.

---

## 🆘 Troubleshooting

### Common Issues

**"Key was created with errors"**
- Ensure all keystore details are filled
- Use valid country code (US, UK, etc.)

**"Keystore not found"**
- Check file path in `key.properties`
- Use forward slashes or double backslashes in Windows paths

**"Upload failed"**
- Ensure version code is incremented
- Check package name matches Google Play listing

### Getting Help
- Google Play Console Help Center
- Flutter Documentation: App Signing
- Stack Overflow: flutter-app-bundle

---

**✅ Success!** Your FocusFlow app is now ready for the Google Play Store with proper AAB format and signing! 🎉