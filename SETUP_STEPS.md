# NirmanApp - Setup Steps After Extracting Zip

## What's in this zip
- lib/ — complete Flutter source code (all screens, services, models)
- android/app/build.gradle.kts — Android build config
- android/app/src/main/AndroidManifest.xml — Android manifest
- android/key.properties — keystore config
- assets/images/ — SVG icon and splash (need converting to PNG)
- pubspec.yaml — all dependencies including launcher icons

---

## Step 1 — Copy files to your project

Copy EVERYTHING from this zip into your nirmanapp folder:
- lib/ → replace entire lib folder
- android/app/build.gradle.kts → replace existing
- android/app/src/main/AndroidManifest.xml → replace existing
- android/key.properties → place in android/ folder
- assets/ → replace entire assets folder
- pubspec.yaml → replace existing

---

## Step 2 — Convert SVG icons to PNG

Go to https://svgtopng.com and convert:
1. assets/images/nirmanapp_icon_c.svg → save as assets/images/icon.png (1024x1024)
2. assets/images/nirmanapp_splash.svg → save as assets/images/splash.png (1080x1920)

Place both PNG files in: nirmanapp/assets/images/

---

## Step 3 — Move MainActivity.kt to correct package

Run in PowerShell from nirmanapp folder:

```
New-Item -ItemType Directory -Force -Path "android\app\src\main\kotlin\com\vvis\nirmanapp"
Move-Item "android\app\src\main\kotlin\com\nirmanapp\nirmanapp\MainActivity.kt" "android\app\src\main\kotlin\com\vvis\nirmanapp\MainActivity.kt"
```

Then open MainActivity.kt and change first line to:
package com.vvis.nirmanapp

---

## Step 4 — Install dependencies

```
flutter pub get
```

---

## Step 5 — Generate icons and splash screen

```
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## Step 6 — Test locally

```
flutter run
```

---

## Step 7 — Push to GitHub

```
git add .
git commit -m "Add icon, splash screen, updated build config"
git push origin main
```

---

## Step 8 — Trigger CodeMagic build

Go to CodeMagic → nirmanapp → Start new build
Build will automatically publish to Play Store internal testing track.

---

## Notes
- Package name: com.vvis.nirmanapp
- Supabase URL: https://liiazqlsslggatfrrvdl.supabase.co
- Admin email: nirmanapphq@gmail.com
- keystore: C:/Users/bhanu/VVISTECH/upload-keystore.jks
