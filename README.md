# Back Me App

A Flutter goal-tracking application with milestone completion, photo proof, and content moderation features.

## Features

- **Goal Creation & Management**: Create and track progress on personal goals
- **Milestone Tracking**: Break down goals into smaller, manageable milestones
- **Photo Proof**: Add photos as proof of milestone and goal completion
- **Content Moderation**: Automatic checking of uploaded photos for inappropriate content
- **Smart Progress**: Intelligent progress tracking and auto-completion
- **Pause/Resume**: Ability to pause and resume goals as needed
- **Firebase Integration**: Cloud storage and real-time synchronization

## Setup Instructions

### 1. Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable the following services:
   - **Authentication** (Email/Password, Google Sign-In)
   - **Firestore Database**
   - **Firebase Storage**
3. Add your platform-specific configuration files:
   - `android/app/google-services.json` (Android)
   - `ios/Runner/GoogleService-Info.plist` (iOS)

### 2. Firebase Storage Rules

The app will automatically deploy the following storage rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /goals/{goalId}/{type}/{fileName} {
      allow read, write: if request.auth != null
        && request.auth.uid != null
        && (type == 'milestone' || type == 'goal')
        && request.resource.size < 10 * 1024 * 1024;
    }
  }
}
```

### 3. Content Moderation Setup (Optional)

To enable photo content moderation using Google Cloud Vision API:

1. **Enable Cloud Vision API**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Navigate to your project (or create a new one)
   - Enable the **Cloud Vision API**

2. **Create API Key**:
   - Go to **APIs & Services** > **Credentials**
   - Click **Create Credentials** > **API Key**
   - Restrict the API key to **Cloud Vision API** for security
   - Copy the API key

3. **Configure the App**:
   - ✅ **API Key Configured**: Content moderation is ready to use!
   - Optionally adjust the content threshold settings in `lib/config/content_moderation_config.dart`

```dart
class ContentModerationConfig {
  static const String apiKey = 'AIzaSyBAW5DXDp1miQ6OxPYlXc3_qPhecIaXqBs';
  static const bool enableContentModeration = true;
  static const int contentThreshold = 4; // LIKELY or VERY_LIKELY
}
```

4. **Content Moderation Features**:
   - **Automatic Analysis**: Photos are analyzed for inappropriate content
   - **Real-time Feedback**: Users get immediate feedback on photo acceptance
   - **Configurable Thresholds**: Adjust sensitivity in the config file
   - **Graceful Fallback**: If the API is unavailable, photos are still accepted

### 4. Build and Run

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the App**:
   ```bash
   flutter run
   ```

3. **Build for Production**:
   ```bash
   # Android
   flutter build apk --release
   
   # iOS
   flutter build ios --release
   ```

## Content Moderation Details

The app uses Google Cloud Vision API's SafeSearch feature to detect:
- Adult content
- Violent content
- Racy content
- Medical content
- Spoof content

### Moderation Thresholds

- **1**: VERY_UNLIKELY
- **2**: UNLIKELY  
- **3**: POSSIBLE
- **4**: LIKELY (default threshold)
- **5**: VERY_LIKELY

Photos scoring 4 or higher in adult, violent, or racy content categories are rejected.

### Disabling Content Moderation

To disable content moderation entirely:
1. Open `lib/config/content_moderation_config.dart`
2. Set `enableContentModeration = false`

## Privacy & Security

- All photos are stored securely in Firebase Storage
- Content moderation is performed server-side without storing analysis results
- API keys should be properly restricted in Google Cloud Console
- Photos are automatically compressed and optimized before upload

## Support

For questions or issues:
1. Check the Firebase Console for any service outages
2. Verify API keys are correctly configured
3. Ensure all required permissions are granted on the device
