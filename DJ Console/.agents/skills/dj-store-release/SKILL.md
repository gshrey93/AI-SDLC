---
name: dj-store-release
description: App Store and Google Play Store submission procedures, audio background modes, media service configurations, and Fastlane release lanes.
---

# DJ Store Release & Compliance Skill

Use this skill when preparing builds, updating store metadata, verifying permissions compliance, or deploying through Fastlane.

## Mandatory Store Permissions
* **Android:**
  * Foreground Service: `android:foregroundServiceType="mediaPlayback"`
  * Hardware Audio: `android.hardware.audio.low_latency` required.
  * Audio access: `READ_MEDIA_AUDIO` / `ACTION_OPEN_DOCUMENT`. Never use `MANAGE_EXTERNAL_STORAGE`.
* **iOS:**
  * Background Modes: Add `audio` to `UIBackgroundModes` in `Info.plist`.
  * Audio Session: Set `AVAudioSessionCategoryPlayback`.

## Fastlane Command Reference
```bash
# Verify DSP math & curves
fastlane android test

# Deploy App Bundle to Google Play Internal track
fastlane android deploy_internal

# Promote to Production (10% rollout)
fastlane android deploy_production

# Deploy iOS to Apple TestFlight
fastlane ios deploy_testflight
```
