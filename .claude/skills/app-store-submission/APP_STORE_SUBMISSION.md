# Mindfulness — App Store submission (worked values)

```
App name:        Mindfulness
App ID (ASC):    <PENDING — create the app record, then put numeric id in .env ASC_APP_ID>
Bundle ID:       com.alfredang.mindfulnesspractice   (registered via API)
iCloud container: none
Team ID:         GU9WTSTX9M
Platform:        iOS, SwiftUI, iPhone-only (TARGETED_DEVICE_FAMILY=1)
Category:        Health & Fitness  (alt: Lifestyle)
Price:           Free
Version / Build: 1.0 / 1
Backend:         none (fully offline; bundled audio)
Privacy:         Data Not Collected
```

- Build system: XcodeGen (`project.yml` → scheme/target `MindfulnessPractice`).
- Signing: identity **Apple Distribution: Alfred Ang (GU9WTSTX9M)** + profile **"Mindfulness App Store"**
  (created via API, cert `JU3U329V25`). `ExportOptions.plist` uses manual signing.
- Signed IPA ready at `/tmp/export/MindfulnessPractice.ipa` (1.9 MB).
- Screenshot ready: `/tmp/appstore_shots/01_home.png` (1320×2868, APP_IPHONE_67).
- No login/account → `demoAccountRequired=false`; account-deletion guideline N/A.
- App Privacy: declare **Data Not Collected** in the web UI (one-time, no API).

## Marketing copy

```
Subtitle:    Guided breathing meditation
Keywords:    mindfulness,meditation,breathing,calm,relax,breath,zen,sleep,anxiety,focus
Promo text:  Take a few quiet minutes for yourself with a gently guided breathing meditation.
Description:
Mindfulness is a simple, beautiful space to pause and breathe.

Follow a gently guided "Awareness of the Breath" meditation — a calm, soothing voice walks
you through settling into your body, softening your gaze, and resting your attention on the
breath at the tip of your nose. When your mind wanders, you're kindly invited to come back,
as many times as you need.

• One guided breathing session, about 8.5 minutes
• A soothing, natural voice with unhurried pacing and quiet space to simply breathe
• Calming full-screen zen garden scene
• Simple Start, Pause, and Stop controls with a progress scrubber
• Works completely offline — no account, no sign-up, no data collected

Find a comfortable seat, press Start, and give yourself a few mindful minutes.
```

## Finish steps (run once the app record exists)
1. Put the numeric App ID in `.env` as `ASC_APP_ID`, then `set -a; source .env; set +a`.
2. `xcrun altool --validate-app -f /tmp/export/MindfulnessPractice.ipa -t ios --apiKey $ASC_KEY_ID --apiIssuer $ASC_ISSUER_ID`
3. `xcrun altool --upload-app -f /tmp/export/MindfulnessPractice.ipa -t ios --apiKey $ASC_KEY_ID --apiIssuer $ASC_ISSUER_ID`
4. Wait for build `processingState == VALID` (~5–15 min).
5. `python3 scripts/asc_submit.py set-metadata` ; `review-contact` ; set name/subtitle/description/keywords on the version localization.
6. `python3 scripts/asc_submit.py attach-build --build 1`
7. `python3 scripts/asc_submit.py screenshots --type APP_IPHONE_67 /tmp/appstore_shots/01_home.png`
8. Publish **App Privacy: Data Not Collected** + set **Age Rating** in the web UI.
9. `python3 scripts/asc_submit.py submit`
