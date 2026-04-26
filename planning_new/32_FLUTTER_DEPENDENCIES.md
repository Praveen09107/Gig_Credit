# ================================================================================
# GIGCREDIT — FLUTTER DEPENDENCIES AND PACKAGE LIST
# Document 32 | planning_new
# Owner: Dev B
# ================================================================================

## 1. PUBSPEC.YAML DEPENDENCIES

```yaml
name: gigcredit
description: Privacy-First Credit Scoring for Gig Workers
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # Navigation
  go_router: ^13.0.0
  
  # UI/Design
  google_fonts: ^6.1.0
  flutter_animate: ^4.3.0
  shimmer: ^3.0.0
  confetti_widget: ^0.4.0
  fl_chart: ^0.66.0           # For pillar bar charts
  animated_text_kit: ^4.2.2   # Typewriter text effect
  
  # Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.0.0
  
  # Network
  http: ^1.1.0
  
  # Crypto (HMAC)
  crypto: ^3.0.3
  
  # File Handling
  image_picker: ^1.0.4        # Camera + gallery
  file_picker: ^6.1.1         # PDF picker
  path_provider: ^2.1.1
  
  # PDF Generation
  pdf: ^3.10.0
  printing: ^5.11.0
  
  # PDF Reading (bank statements)
  pdfx: ^2.6.0                # PDF text extraction
  
  # Utils
  intl: ^0.19.0               # Date/number formatting
  uuid: ^4.2.0                # Unique identifiers
  
  # Icons
  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0

flutter:
  uses-material-design: true
  
  assets:
    - assets/config/
    - assets/fonts/
    - assets/images/
  
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

---

## 2. PACKAGE PURPOSE MAP

| Package              | Purpose                                    | Used By           |
|---------------------|--------------------------------------------|--------------------|
| flutter_riverpod     | App-wide reactive state management         | All screens        |
| go_router            | Declarative navigation with deep linking   | app.dart           |
| google_fonts         | Premium typography (Inter font)            | Theme              |
| flutter_animate      | Micro-animations (fade, slide, scale)      | All widgets        |
| shimmer              | Loading shimmer effect on cards            | Upload cards       |
| confetti_widget      | Score reveal celebration                   | ScoreResultScreen  |
| fl_chart             | Pillar breakdown bar chart                 | ReportScreen       |
| animated_text_kit    | Typewriter effect for LLM text             | ReportScreen       |
| hive                 | Fast key-value local storage               | Session persistence|
| flutter_secure_storage| Encrypted small secrets (API key)         | Security           |
| http                 | HTTP client for API calls                  | ApiClient          |
| crypto               | HMAC-SHA256 signing                        | HmacSigner         |
| image_picker         | Camera/gallery for document upload         | Upload cards       |
| file_picker          | PDF file selection                         | Bank statement     |
| pdf                  | Generate PDF report                        | PDF export         |
| pdfx                 | Extract text from bank statement PDFs      | Bank parser        |
| intl                 | Format ₹ amounts and dates                 | Formatters         |

---

## 3. ANDROID CONFIGURATION

### android/app/build.gradle
```groovy
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.gigcredit.app"
        minSdkVersion 24      // Android 7.0 (for crypto support)
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
    
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt')
        }
    }
}
```

### Permissions (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```
