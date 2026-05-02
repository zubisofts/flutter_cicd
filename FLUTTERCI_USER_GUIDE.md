# FlutterCI — User Guide

FlutterCI is a macOS desktop app that builds and distributes your Flutter mobile apps without any external CI server. Everything runs on your Mac — signing, artifact generation, and distribution to Firebase, TestFlight, or the Play Store.

> **Why this app exists:** We don't have a stable CI/CD pipeline for mobile in the org at the moment. FlutterCI is meant to fill that gap, leveraging your local machine to run builds, until a proper CI infrastructure is in place. Because builds run on your Mac, all the tools (Flutter, Xcode, Fastlane, Firebase CLI, etc.) must be correctly installed and configured on the machine running the app.

---

## Table of Contents

1. [System Requirements](#1-system-requirements)
2. [How It Works (Overview)](#2-how-it-works-overview)
3. [First-Time Setup](#3-first-time-setup)
4. [Config File Reference](#4-config-file-reference)
   - [app.yaml — Project Definition](#appyaml--project-definition)
   - [envs/dev.yaml — Environment Config](#envsdevyaml--environment-config)
   - [pipelines/mobile.yaml — Pipeline Definition](#pipelinesmobileyaml--pipeline-definition)
5. [Credentials & Settings](#5-credentials--settings)
   - [Android Signing](#android-signing)
   - [Apple / TestFlight (App Store Connect API Key)](#apple--testflight-app-store-connect-api-key)
   - [Firebase App Distribution](#firebase-app-distribution)
   - [Play Store](#play-store)
   - [Slack Notifications](#slack-notifications)
6. [Running a Build](#6-running-a-build)
7. [Execution Screen](#7-execution-screen)
8. [Build History](#8-build-history)
9. [Retrying and Resuming Builds](#9-retrying-and-resuming-builds)
10. [Build Artifacts](#10-build-artifacts)
11. [Menu Bar Status Icon](#11-menu-bar-status-icon)
12. [Pipeline Step Types Reference](#12-pipeline-step-types-reference)
13. [Troubleshooting](#13-troubleshooting)

---

## 1. System Requirements

| Requirement | Minimum |
|---|---|
| macOS | 13 Ventura or later |
| Flutter SDK | 3.10+ (must be on PATH) |
| Xcode | 14+ (for iOS builds) |
| Android Studio / SDK | Required for Android builds |
| Fastlane | Required for TestFlight / Play Store distribution |
| Firebase CLI | Required for Firebase App Distribution |
| Git | Must be on PATH |

Verify your tools are reachable before adding a project:

```bash
which flutter   # should print a path
which git
which fastlane
which firebase
```

---

## 2. How It Works (Overview)

```
┌─────────────────────────────────────────────────┐
│                 FlutterCI (macOS app)           │
│                                                 │
│  Setup Screen  →  Execution Screen  →  History  │
│      ↑                   ↑                      │
│  ~/.cicd/projects/    pipeline runs on your Mac │
└─────────────────────────────────────────────────┘
```

All project configuration lives in `~/.cicd/projects/<project-id>/`. FlutterCI reads these YAML files, clones your repository into a temporary workspace, runs the pipeline steps, and saves results to a local SQLite database.

**Nothing is sent to an external server.** Signing keys stay in macOS Keychain. Builds run entirely on the machine running FlutterCI.

---

## 3. First-Time Setup

### Step 1 — Create the project config directory

```
~/.cicd/
└── projects/
    └── my-app/              ← your project ID (no spaces)
        ├── app.yaml         ← project definition
        ├── envs/
        │   ├── dev.yaml
        │   ├── staging.yaml
        │   └── prod.yaml
        └── pipelines/
            └── mobile.yaml  ← pipeline steps
```

Create it with:

```bash
mkdir -p ~/.cicd/projects/my-app/envs
mkdir -p ~/.cicd/projects/my-app/pipelines
```

### Step 2 — Write the config files

See [Section 4](#4-config-file-reference) for full YAML schemas with examples.

### Step 3 — Open FlutterCI and add credentials

Go to **Settings** (gear icon in the sidebar) to enter:
- Android keystore path and passwords
- App Store Connect API Key (Key ID, Issuer ID, and `.p8` private key file) for TestFlight
- Firebase service account JSON file for Firebase App Distribution
- Play Store service account JSON file for Play Store uploads
- Slack webhook URL (optional)

### Step 4 — Run your first build

Select your project and environment from the **Setup** screen, choose platforms and distribution targets, then click **Start Pipeline**.

---

## 4. Config File Reference

### `app.yaml` — Project Definition

Defines the project once. Does not change per-environment.

```yaml
id: my-app
name: My App
repository: git@github.com:your-org/your-repo.git

android:
  base_package: com.yourcompany.myapp

ios:
  base_bundle_id: com.yourcompany.myapp

versioning:
  strategy: semver
  suffix_per_env:
    dev: -dev
    staging: -staging
    prod: ""         # no suffix on prod
```

| Field | Description |
|---|---|
| `id` | Unique identifier. Must match the folder name under `~/.cicd/projects/`. |
| `name` | Display name shown in the UI. |
| `repository` | Git remote URL (SSH or HTTPS). |
| `android.base_package` | Base Android package name. |
| `ios.base_bundle_id` | Base iOS bundle identifier. |
| `versioning.strategy` | Currently `semver`. |
| `versioning.suffix_per_env` | String appended to the version name per environment. |

---

### `envs/dev.yaml` — Environment Config

One file per environment (`dev.yaml`, `staging.yaml`, `prod.yaml`).

```yaml
name: dev
display_name: Development
color: "0xFF1F6FEB"   # blue — shown as a badge in the UI

android:
  package_name: com.yourcompany.myapp.dev
  firebase_app_id: "1:123456789:android:abcdef"
  flavor: dev
  signing:
    keystore: ~/keys/my-app.keystore
    key_alias: my-key
    keystore_password_env: KEYSTORE_PASSWORD
    key_password_env: KEY_PASSWORD

ios:
  bundle_id: com.yourcompany.myapp.dev
  firebase_app_id: "1:123456789:ios:abcdef"
  team_id: ABCDE12345
  provisioning_profile: My App Dev Profile
  flavor: dev
  export_method: development

distribution:
  firebase:
    enabled: true
    tester_groups:
      - internal-qa
      - developers
  testflight: false
  play_store:
    enabled: false
    track: internal
    rollout_percentage: 100

safety:
  require_confirmation: false
  require_clean_branch: false
  allowed_branches:
    - main
    - develop
    - feature/*

dart_define_from_file: ""   # optional path to a .json config file
```

**Environment colors** (used for the badge in the Setup screen):

| Color | Hex value |
|---|---|
| Blue | `0xFF1F6FEB` |
| Green | `0xFF3FB950` |
| Orange | `0xFFF0883E` |
| Red | `0xFFF85149` |
| Purple | `0xFF8957E5` |

**`export_method` values for iOS:**

| Value | Use for |
|---|---|
| `development` | Dev/debug builds, internal testing |
| `ad-hoc` | Distribution to specific devices |
| `app-store` | TestFlight and App Store |
| `enterprise` | In-house enterprise distribution |

---

### `pipelines/mobile.yaml` — Pipeline Definition

Defines the ordered list of steps that run during a build. A default pipeline is created automatically when you scaffold a new project. The key ordering rule is: **all distribution steps run after both Android and iOS builds are complete** — if you select both platforms, distribution won't start until all artifacts are ready.

```yaml
name: mobile_build
description: "Full mobile build and distribution pipeline"

steps:
  - id: preflight
    type: preflight_check
    name: "Pre-flight Checks"
    abort_on_failure: true

  - id: checkout
    type: git_checkout
    name: "Checkout Repository"
    abort_on_failure: true

  - id: set_version
    type: set_version
    name: "Apply Version"
    abort_on_failure: true

  - id: install_deps
    type: flutter_pub_get
    name: "Install Dependencies"
    retry:
      max_attempts: 2
      delay_seconds: 5

  - id: build_android
    type: flutter_build
    name: "Build Android"
    condition: "android"
    params:
      platform: android
      artifact: apk
    abort_on_failure: true

  - id: build_ios
    type: flutter_build
    name: "Build iOS"
    condition: "ios"
    params:
      platform: ios
      artifact: ipa
    abort_on_failure: true

  - id: archive_ios
    type: ios_archive
    name: "Archive & Sign iOS"
    condition: "ios"
    depends_on: [build_ios]
    abort_on_failure: true

  - id: distribute_firebase_android
    type: firebase_distribute
    name: "Firebase (Android)"
    condition: "firebase_android"
    depends_on: [build_android, archive_ios]   # waits for iOS too
    params:
      platform: android

  - id: distribute_firebase_ios
    type: firebase_distribute
    name: "Firebase (iOS)"
    condition: "firebase_ios"
    depends_on: [archive_ios]
    params:
      platform: ios

  - id: distribute_testflight
    type: fastlane_lane
    name: "TestFlight Upload"
    condition: "testflight"
    depends_on: [archive_ios]
    params:
      lane: upload_testflight

  - id: distribute_playstore
    type: fastlane_lane
    name: "Play Store Upload"
    condition: "playstore"
    depends_on: [build_android, archive_ios]   # waits for iOS too
    params:
      lane: upload_playstore
```

#### Step fields

| Field | Required | Description |
|---|---|---|
| `id` | Yes | Unique identifier within the pipeline. Used in `depends_on`. |
| `type` | Yes | Step type — see [Section 12](#12-pipeline-step-types-reference). |
| `name` | No | Display name shown in the UI step list. |
| `condition` | No | If set, step is skipped when the condition isn't met. See below. |
| `abort_on_failure` | No | Default `true`. If `false`, failure is logged but the pipeline continues. |
| `depends_on` | No | List of step IDs that must succeed (or be skipped) before this step runs. |
| `params` | No | Step-specific parameters. |
| `retry` | No | Retry policy (see below). |

#### `condition` values

| Condition | When the step runs |
|---|---|
| *(none)* | Always |
| `android` | Android platform selected |
| `ios` | iOS platform selected |
| `firebase_android` | Android selected AND Firebase Android target chosen |
| `firebase_ios` | iOS selected AND Firebase iOS target chosen |
| `testflight` | iOS selected AND TestFlight target chosen |
| `playstore` | Android selected AND Play Store target chosen |

#### Retry policy

```yaml
retry:
  max_attempts: 3
  delay_seconds: 10
```

---

## 5. Credentials & Settings

Navigate to **Settings** by clicking the project name in the Setup screen, or using the gear icon in the sidebar.

All credentials are stored in **macOS Keychain**, never written to disk as plain text. Use the environment selector at the top of Settings to switch between dev / staging / prod — credentials are stored per project + environment.

### Android Signing

1. Go to **Settings → Android Signing**
2. Click **Browse** to select your `.keystore` or `.jks` file
3. Enter the key alias and both passwords
4. Click **Save to Keychain**

The keystore file is copied into `~/.cicd/projects/<id>/files/` so the pipeline can find it even when building in a temporary workspace.

---

### Apple / TestFlight (App Store Connect API Key)

FlutterCI uses **App Store Connect API Keys** for TestFlight uploads. This approach does not require 2FA prompts and never expires, unlike the old Apple ID + app-specific password method.

**How to create an API key:**

1. Go to [App Store Connect](https://appstoreconnect.apple.com) → Users and Access → Integrations → App Store Connect API
2. Click the `+` button to create a new key
3. Give it a name (e.g. "FlutterCI"), set the role to **App Manager** or **Developer**
4. Download the `.p8` private key file — **you can only download it once**
5. Note the **Key ID** and **Issuer ID** shown on that page

**In FlutterCI Settings → Apple / TestFlight:**

1. Enter the **Key ID** (e.g. `ABCDE12345`)
2. Enter the **Issuer ID** (the UUID shown under the key list)
3. Click **Browse** to select the `.p8` private key file, or paste its contents directly
4. Click **Save to Keychain**

---

### Firebase App Distribution

FlutterCI uses a **Google Service Account** for Firebase App Distribution. This replaces the old `firebase login:ci` token approach, which is deprecated by Google.

**How to create a service account:**

1. Open [Google Cloud Console](https://console.cloud.google.com) → IAM & Admin → Service Accounts
2. Select the project linked to your Firebase app
3. Click **Create Service Account** → give it a name (e.g. `flutterci-firebase`)
4. Grant the role: **Firebase App Distribution Admin**
5. Open the service account → Keys tab → Add Key → JSON → download the file

**In FlutterCI Settings → Firebase & Play Store:**

1. Under **Firebase service account JSON**, click **Browse** and select the downloaded `.json` file
2. Click **Save to Keychain**
3. Set the **Firebase tester groups** field to the group aliases you want distributions sent to (comma-separated), e.g. `internal-qa, beta-testers`
4. Click **Save to YAML**

> Firebase CLI must still be installed (`brew install firebase-cli`). The service account is used via the `GOOGLE_APPLICATION_CREDENTIALS` environment variable, which Firebase CLI reads automatically.

---

### Play Store

FlutterCI uploads to the Play Store via Fastlane using a **Google Play service account JSON** key.

**How to create a service account:**

1. In [Google Play Console](https://play.google.com/console) → Setup → API access → Link to a Google Cloud project
2. In Google Cloud Console → IAM & Admin → Service Accounts → Create service account (e.g. `flutterci-playstore`)
3. Download the JSON key
4. Back in Play Console → Users and permissions → Invite new users → paste the service account email → grant **Release Manager** permission

**In FlutterCI Settings → Firebase & Play Store:**

1. Under **Play Store service account JSON**, click **Browse** and select the `.json` file
2. Click **Save to Keychain**

The path is passed to Fastlane as `PLAY_STORE_JSON_KEY`.

---

### Slack Notifications

1. In your Slack workspace: **Apps → Incoming Webhooks → Add New Webhook to Workspace** → choose a channel
2. Copy the Webhook URL
3. Go to **Settings → Slack Notifications**
4. Enable the toggle and paste the URL
5. Click **Send Test** to verify
6. Click **Save to Keychain**

After saving, FlutterCI posts a message to that channel after every build with the project name, environment, version, branch, platforms, and duration.

---

## 6. Running a Build

### Setup Screen walkthrough

1. **Select a project** from the left panel. If no projects appear, check that `~/.cicd/projects/` contains at least one valid `app.yaml`.

2. **Select an environment** (dev / staging / prod). The environment badge color changes to match the `color` set in the env YAML.

3. **Set the version name and build number**. The app automatically prefills the values from your last build for this project — increment them as needed.

4. **Select platforms**: Android, iOS, or both.

5. **Select distribution targets** based on your environment config:
   - **Firebase Android** — distribute the APK/AAB via Firebase App Distribution
   - **Firebase iOS** — distribute the IPA via Firebase App Distribution
   - **TestFlight** — upload to TestFlight via Fastlane
   - **Play Store** — upload to the Play Store via Fastlane

   > Only targets that are enabled in the environment YAML appear as selectable.

6. **Enter your git branch name**. This is the branch that will be checked out for the build.

7. Click **Start Pipeline**.

---

## 7. Execution Screen

Once a build starts you are taken to the **Execution Screen**.

```
┌─────────────────────────────────────────────────────────────┐
│ ← my-app › dev › 1.2.0+42          ● Running  2m 14s       │
├──────────────────┬──────────────────────────────────────────┤
│ STEPS            │ LIVE OUTPUT                              │
│                  │                                          │
│ ✓ Preflight 2s   │  ─── Flutter Build Android ──────────   │
│ ✓ Checkout  8s   │  [gradle] :app:assembleRelease           │
│ ✓ Version  <1s   │  ...                                     │
│ ✓ Deps     45s   │                                          │
│ ● Build Android  │                                          │
│   Build iOS      │                                          │
│   Archive iOS    │                                          │
│   Firebase       │                                          │
│──────────────────┤                                          │
│ [ABORT]          │                                          │
└──────────────────┴──────────────────────────────────────────┘
```

**Step statuses:**

| Icon | Meaning |
|---|---|
| Grey circle | Pending — not yet started |
| Blue spinner | Running |
| Green check | Succeeded (with duration) |
| Red X | Failed |
| Arrow | Skipped (condition not met, or resumed from prior success) |
| Orange stop | Aborted |

Steps that don't apply to your current platform/target selection are hidden entirely.

**Distribution ordering:** All distribution steps (Firebase, TestFlight, Play Store) run only after both Android and iOS artifacts are ready. If you selected only one platform, its distribution steps start immediately after its build; if you selected both, distribution waits for the slower of the two.

**Aborting a build:** Click **ABORT** in the bottom-left. The currently running process is terminated immediately and the run is marked as aborted.

### Completion Banner

When the pipeline finishes, a banner appears at the bottom:

- **Green** — all steps succeeded
- **Red** — one or more steps failed

If build artifacts were produced (APK, AAB, or IPA), the banner shows two buttons:

| Button | Action |
|---|---|
| **Show in Finder** | Opens the folder containing the artifact in Finder |
| **Copy Path** | Copies the full file path to the clipboard |

### Notifications

- **macOS notification** — appears in Notification Center after every build
- **Menu bar icon** — changes colour (blue while building, green on success, red on failure)
- **Slack message** — if configured, posts a detailed summary to your channel

---

## 8. Build History

Click **History** in the sidebar to see all past runs.

### Left panel

- **Run list** — sorted newest first. Each row shows project › env › version, timestamp, branch, and duration. A green circle indicates success; red indicates failure.
- **Stat chips** — total runs, number passed, and overall success rate.
- **Duration sparkline** — a mini chart of the last 20 runs. Green dots are successful runs, red dots are failures.
- **Delete** — the trash icon on each row permanently removes the run record and its log file.

### Right panel

Select any run to see:
- Full run metadata (Run ID, branch, platforms, targets)
- Step-by-step results with individual durations (`< 1s` for sub-second steps)
- Full log output with colour-coded levels — same colours as the live execution view

---

## 9. Retrying and Resuming Builds

Both buttons appear in the top-right of the run detail panel.

### Retry

**Retry** re-runs the entire pipeline from the beginning using the same project, environment, branch, version, platforms, and targets as the original run. Use this when a transient failure (network, flaky tool) caused the build to fail and you want to start fresh.

### Resume

**Resume** appears only for failed runs. It re-runs the pipeline but **skips every step that already succeeded** in the failed run. Only the failed step and any steps after it are executed.

Example: if your pipeline has 9 steps and step 8 (Firebase distribution) failed after steps 1–7 all succeeded, Resume will skip steps 1–7 and pick up from step 8. This saves the time of re-cloning, installing dependencies, and rebuilding.

> Resume is safe to use when the failure was in a distribution step. Avoid using it if the underlying code changed — use Retry for that.

---

## 10. Build Artifacts

FlutterCI automatically copies build outputs out of the temporary workspace before deleting it:

| Platform | Output |
|---|---|
| Android (APK) | `app-<flavor>-release.apk` |
| Android (AAB) | `app-<flavor>-release.aab` |
| iOS | `<Flavor>.app` or signed `.ipa` |

Artifacts are stored at:

```
~/.cicd/artifacts/<run-id>/<filename>
```

They are accessible from the **completion banner** on the Execution screen and remain on disk until you manually remove them. The 20 most recent run workspaces are kept; older ones are pruned automatically.

---

## 11. Menu Bar Status Icon

FlutterCI places a small coloured icon in the macOS menu bar.

| Color | Meaning |
|---|---|
| Grey | App is open, no active build |
| Blue | Build in progress |
| Green | Last build succeeded |
| Red | Last build failed |

Right-clicking the icon shows a context menu with a status line and a **Quit FlutterCI** option.

The icon stays visible even when the main FlutterCI window is hidden or minimised.

---

## 12. Pipeline Step Types Reference

### `preflight_check`

Verifies that required tools (Flutter, Git, Xcode, Fastlane, Firebase CLI) are available on PATH before any work begins. No `params`.

---

### `git_checkout`

Clones the repository (from `app.yaml → repository`) into a fresh workspace and checks out the specified branch. No `params`.

---

### `set_version`

Writes the version name and build number chosen in the Setup screen into `pubspec.yaml` inside the workspace. No `params`.

---

### `flutter_pub_get`

Runs `flutter pub get` to install dependencies, then automatically runs `dart run build_runner build --delete-conflicting-outputs` to regenerate any code-generated files (`.g.dart`, `.freezed.dart`, etc.). A retry policy can be applied:

```yaml
- id: install_deps
  type: flutter_pub_get
  name: "Install Dependencies"
  retry:
    max_attempts: 2
    delay_seconds: 5
```

---

### `flutter_build`

Runs `flutter build` for the given platform and artifact type.

```yaml
params:
  platform: android     # android | ios
  artifact: apk         # apk | appbundle | ipa
```

For iOS + `artifact: ipa`, the step compiles the framework only and delegates the signing and packaging to the `ios_archive` step. Both steps must be present in the pipeline for iOS IPA builds.

---

### `ios_archive`

Runs `xcodebuild archive` and `xcodebuild -exportArchive` to produce a signed `.ipa` using the provisioning profile and export method from the environment config. No `params`. All signing config comes from the environment YAML and the credentials stored in Keychain.

---

### `firebase_distribute`

Distributes the built artifact to Firebase App Distribution using the Firebase CLI.

```yaml
params:
  platform: android     # android | ios
```

Authentication uses the Google Service Account JSON file path stored in **Settings → Firebase & Play Store** (`GOOGLE_APPLICATION_CREDENTIALS`). Tester groups come from **Settings → Firebase & Play Store → Firebase tester groups** (or from the env YAML `distribution.firebase.tester_groups`).

---

### `fastlane_lane`

Runs a named Fastlane lane. If no `fastlane/Fastfile` exists in the project, FlutterCI scaffolds a default one with `upload_testflight` and `upload_playstore` lanes.

```yaml
params:
  lane: upload_testflight   # or: upload_playstore
```

**Environment variables available to Fastlane lanes:**

| Variable | Value |
|---|---|
| `ASC_KEY_ID` | App Store Connect Key ID |
| `ASC_ISSUER_ID` | App Store Connect Issuer ID |
| `ASC_KEY_CONTENT` | Base64-encoded `.p8` private key content |
| `PLAY_STORE_JSON_KEY` | Path to the Play Store service account JSON |
| `IPA_PATH` | Full path to the built `.ipa` |
| `AAB_PATH` | Full path to the built `.aab` |
| `APK_PATH` | Full path to the built `.apk` |
| `APPLE_TEAM_ID` | iOS team ID from env config |
| `BUNDLE_ID` | iOS bundle identifier |
| `ANDROID_PACKAGE_NAME` | Android package name |
| `PLAY_TRACK` | Play Store track (internal / alpha / beta / production) |
| `ROLLOUT_PERCENTAGE` | Play Store rollout percentage |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to the Firebase service account JSON |

---

## 13. Troubleshooting

### "app.yaml not found for project"
The project ID in the folder name does not match the `id` field in `app.yaml`, or the directory structure is wrong.
```
~/.cicd/projects/<id>/app.yaml   # <id> must equal app.yaml → id field
```

---

### Build fails with "Flutter SDK not found" or "git: not found"
FlutterCI inherits the PATH of the user who launched it. If launched from Finder, PATH may not include your tool directories.

Fix: Launch from a terminal:
```bash
open /Applications/FlutterCI.app
```
Or add your tool paths to `~/.zshenv` (sourced for all shells, including those started by GUI apps).

---

### iOS Archive fails with "no signing certificate"
1. The provisioning profile name in the env YAML must exactly match a profile installed in Xcode (Xcode → Settings → Accounts → Manage Certificates).
2. The Apple Team ID must be set correctly in Settings → App Identifiers → Apple Team ID.
3. The `export_method` must match the profile type.

---

### TestFlight upload fails with "Invalid credentials" or "Authentication error"
The old Apple ID + app-specific password approach no longer works reliably due to Apple's 2FA enforcement. FlutterCI now uses App Store Connect API Keys. If this error appears:
1. Go to **Settings → Apple / TestFlight**
2. Verify the Key ID, Issuer ID, and private key content are filled in
3. Ensure the API key has at least **App Manager** role in App Store Connect

---

### Firebase distribution fails with "Authentication Error" or "Permission denied"
1. Check that a service account JSON file path is saved in **Settings → Firebase & Play Store**
2. Verify the service account has the **Firebase App Distribution Admin** IAM role in Google Cloud Console
3. Confirm the Firebase App ID in the env YAML matches the app registered in Firebase console

---

### Play Store upload fails with "Google credentials not configured"
1. Check that a Play Store service account JSON file path is saved in **Settings → Firebase & Play Store**
2. Verify the service account has **Release Manager** permission in Google Play Console → Users and permissions
3. Confirm the Android package name in the env YAML matches the app in Play Console

---

### "Keychain item not found" for Android passwords
Keystore passwords are stored per project + environment. After switching to a different environment in Settings, re-enter and save the credentials in **Settings → Android Signing**.

---

### Build runs but produces no artifact buttons in the completion banner
The artifact was not found at the expected path. Check the live log output for the line beginning with `Artifact:` — if missing, path resolution failed. Common causes:
- A custom Gradle output directory in the project's `build.gradle`
- A flavor name that doesn't match what FlutterCI expects (set `flavor` explicitly in the env YAML rather than relying on the environment name)

---

### Slack test message returns an error
The webhook URL must start with `https://hooks.slack.com/services/`. Copy it directly from the Slack Webhooks settings page to avoid trailing spaces or encoding issues.

---

## Quick Reference — File Locations

| Path | Purpose |
|---|---|
| `~/.cicd/projects/<id>/app.yaml` | Project definition |
| `~/.cicd/projects/<id>/envs/<env>.yaml` | Per-environment config |
| `~/.cicd/projects/<id>/pipelines/mobile.yaml` | Pipeline step definitions |
| `~/.cicd/projects/<id>/files/` | Bundled files (keystores, dart-define JSON) |
| `~/.cicd/projects/<id>/last_run.json` | Last build config for this project (auto-prefill) |
| `~/.cicd/runs/<run-id>/run.log` | Full log for a completed run |
| `~/.cicd/artifacts/<run-id>/` | Build artifacts (APK / AAB / IPA) |
| `~/.cicd/flutter_cicd.db` | SQLite database of run history |

---

*For questions or issues, contact the person who set up FlutterCI for your team.*
