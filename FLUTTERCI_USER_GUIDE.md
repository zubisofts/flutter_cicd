# FlutterCI — User Guide

FlutterCI is a macOS desktop app that builds and distributes your Flutter mobile apps without any external CI server. Everything runs on your Mac — signing, artifact generation, and distribution to Firebase, TestFlight, or the Play Store.

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
   - [Apple / TestFlight](#apple--testflight)
   - [Firebase](#firebase)
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

All project configuration lives in `~/.cicd/projects/<project-id>/`. FlutterCI reads these YAML files, clones your repository, runs the pipeline steps sequentially, and saves results to a local SQLite database.

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
- Apple ID and app-specific password
- Firebase CI token
- Slack webhook URL (optional)

### Step 4 — Run your first build

Select your project and environment from the **Setup** screen, choose platforms and distribution targets, then click **Start Build**.

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

Defines the ordered list of steps that run during a build.

```yaml
name: Mobile Pipeline
description: Build and distribute iOS and Android

steps:
  - id: preflight
    type: preflight_check
    name: Preflight Check
    abort_on_failure: true

  - id: checkout
    type: git_checkout
    name: Git Checkout
    abort_on_failure: true

  - id: set_version
    type: set_version
    name: Set Version
    abort_on_failure: true

  - id: pub_get
    type: flutter_pub_get
    name: Flutter Pub Get
    abort_on_failure: true
    depends_on: [checkout]

  - id: build_android
    type: flutter_build
    name: Build Android
    condition: android
    abort_on_failure: true
    depends_on: [pub_get]
    params:
      platform: android
      artifact: apk       # or: appbundle

  - id: build_ios
    type: flutter_build
    name: Build iOS
    condition: ios
    abort_on_failure: true
    depends_on: [pub_get]
    params:
      platform: ios
      artifact: ipa

  - id: archive_ios
    type: ios_archive
    name: iOS Archive & Sign
    condition: ios
    abort_on_failure: true
    depends_on: [build_ios]

  - id: firebase_android
    type: firebase_distribute
    name: Firebase (Android)
    condition: firebase_android
    abort_on_failure: false
    depends_on: [build_android]
    params:
      platform: android

  - id: firebase_ios
    type: firebase_distribute
    name: Firebase (iOS)
    condition: firebase_ios
    abort_on_failure: false
    depends_on: [archive_ios]
    params:
      platform: ios

  - id: testflight
    type: fastlane_lane
    name: Upload to TestFlight
    condition: testflight
    abort_on_failure: false
    depends_on: [archive_ios]
    params:
      lane: beta

  - id: playstore
    type: fastlane_lane
    name: Upload to Play Store
    condition: playstore
    abort_on_failure: false
    depends_on: [build_android]
    params:
      lane: deploy
```

#### Step fields

| Field | Required | Description |
|---|---|---|
| `id` | Yes | Unique identifier within the pipeline. Used in `depends_on`. |
| `type` | Yes | Step type — see [Section 12](#12-pipeline-step-types-reference). |
| `name` | No | Display name shown in the UI step list. |
| `condition` | No | If set, step is skipped when the condition isn't met. See below. |
| `abort_on_failure` | No | Default `true`. If `false`, failure is logged but the pipeline continues. |
| `depends_on` | No | List of step IDs that must succeed before this step runs. |
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

All credentials are stored in **macOS Keychain**, never written to disk as plain text.

### Android Signing

1. Go to **Settings → Android Signing**
2. Click **Browse** to select your `.keystore` or `.jks` file
3. Enter the key alias and both passwords
4. Click **Save to Keychain**

The keystore file is copied into `~/.cicd/projects/<id>/bundled/` so the pipeline can find it even when building in a temporary workspace.

### Apple / TestFlight

1. Go to **Settings → Apple / TestFlight**
2. Enter your Apple ID (email)
3. Generate an **App-Specific Password** at [appleid.apple.com](https://appleid.apple.com) → Security → App-Specific Passwords
4. Click **Save to Keychain**

> Your regular Apple ID password is never accepted here. You must use an App-Specific Password.

### Firebase

1. Run `firebase login:ci` in your terminal and copy the token printed
2. Go to **Settings → Firebase**
3. Paste the token and click **Save to Keychain**
4. Set the **Tester Groups** field to the Firebase group aliases you want distributions sent to (comma-separated), e.g. `internal-qa, beta-testers`

### Slack Notifications

1. In your Slack workspace: **Apps → Incoming Webhooks → Add New Webhook to Workspace** → choose a channel
2. Copy the Webhook URL
3. Go to **Settings → Slack Notifications**
4. Enable the toggle and paste the URL
5. Click **Send Test** to verify — you should see a message appear in your Slack channel
6. Click **Save to Keychain**

After saving, FlutterCI will post a message to that channel after every build with the project name, environment, version, branch, platforms, and duration.

---

## 6. Running a Build

### Setup Screen walkthrough

1. **Select a project** from the left panel. If no projects appear, check that `~/.cicd/projects/` contains at least one valid `app.yaml`.

2. **Select an environment** (dev / staging / prod). The environment badge color changes to match the `color` set in the env YAML.

3. **Set the version name and build number**. The version name is pre-populated from the last run; increment it as needed.

4. **Select platforms**: Android, iOS, or both.

5. **Select distribution targets** based on your environment config:
   - **Firebase Android** — distribute the APK/AAB via Firebase App Distribution
   - **Firebase iOS** — distribute the IPA via Firebase App Distribution
   - **TestFlight** — upload to TestFlight via Fastlane
   - **Play Store** — upload to the Play Store via Fastlane

   > Only targets that are enabled in the environment YAML appear as selectable.

6. **Enter your git branch name**. This is the branch that will be checked out for the build.

7. Click **Start Build**.

---

## 7. Execution Screen

Once a build starts you are taken to the **Execution Screen**.

```
┌─────────────────────────────────────────────────────────────┐
│ ← my-app › dev › 1.2.0+42          ● Running  2m 14s       │
├──────────────────┬──────────────────────────────────────────┤
│ STEPS            │ LIVE OUTPUT                              │
│                  │                                          │
│ ✓ Preflight      │  ─── Flutter Build Android ──────────   │
│ ✓ Git Checkout   │  [gradle] :app:assembleRelease           │
│ ✓ Set Version    │  ...                                     │
│ ● Flutter Build  │                                          │
│   iOS Archive    │                                          │
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
| Green check | Succeeded |
| Red X | Failed |
| Arrow | Skipped (condition not met, or resumed from prior success) |

**Steps that don't apply to your current platform/target selection are hidden entirely** — they won't clutter the step list.

**Aborting a build:** Click **ABORT** in the bottom-left. In-progress processes are terminated and the run is marked as aborted.

### Completion Banner

When the pipeline finishes, a banner appears at the bottom:

- **Green** — all steps succeeded
- **Red** — one or more steps failed

If build artifacts were produced (APK, AAB, or IPA), the banner shows the platform name alongside two buttons:

| Button | Action |
|---|---|
| **Show in Finder** | Opens the folder containing the artifact in Finder |
| **Copy Path** | Copies the full file path to the clipboard |

Artifacts are saved to `~/.cicd/artifacts/<run-id>/` so they persist after the build workspace is cleaned up.

### Notifications

- **macOS system notification** — appears in Notification Center after every build, showing project, environment, version, and duration.
- **Menu bar icon** — changes color (blue while building, green on success, red on failure). See [Section 11](#11-menu-bar-status-icon).
- **Slack message** — if configured, posts a detailed summary to your channel.

---

## 8. Build History

Click **History** in the sidebar to see all past runs.

### Left panel

- **Run list** — sorted newest first. Each row shows project › env › version, timestamp, branch, and duration. A green circle indicates success; red indicates failure.
- **Stat chips** — total runs, number passed, and overall success rate.
- **Duration sparkline** — a mini line chart of the last 20 runs. Green dots are successful runs, red dots are failures. The Y-axis scales to the longest run in that window, so spikes are easy to spot.
- **Delete** — the trash icon on each row permanently removes the run record and its log file.

### Right panel

Select any run to see:
- Full run metadata (Run ID, branch, platforms, targets)
- Step-by-step results with individual durations
- Full log output (scrollable, same format as live logs during a build)

---

## 9. Retrying and Resuming Builds

Both buttons appear in the top-right of the run detail panel.

### Retry

**Retry** re-runs the entire pipeline from the beginning using the same project, environment, branch, version, platforms, and targets as the original run. Use this when a transient failure (network, flaky tool) caused the build to fail and you want to start fresh.

### Resume

**Resume** appears only for failed runs. It re-runs the pipeline but **skips every step that already succeeded** in the failed run. Only the failed step and any steps after it are executed.

Example: if your pipeline has 8 steps and step 6 (Firebase distribution) failed after steps 1–5 all succeeded, Resume will skip steps 1–5 and pick up from step 6. This saves the time of re-cloning, pub-getting, and rebuilding.

> Resume is safe to use when the failure was in a distribution step. Avoid using it if the underlying code changed, since it won't re-checkout or re-build — use Retry for that.

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

They are accessible from the **completion banner** on the Execution screen (Show in Finder / Copy Path buttons) and remain on disk until you manually remove them.

---

## 11. Menu Bar Status Icon

FlutterCI places a small colored dot in the macOS menu bar while running.

| Color | Meaning |
|---|---|
| Grey | App is open, no active build |
| Blue | Build in progress |
| Green | Last build succeeded |
| Red | Last build failed |

Right-clicking the icon shows a context menu with a status line ("Building: my-app · prod" or "Succeeded: my-app · dev") and a **Quit FlutterCI** option.

The icon stays visible even when the main FlutterCI window is hidden or minimised, so you can monitor long builds without keeping the window in focus.

---

## 12. Pipeline Step Types Reference

### `preflight_check`

Verifies that required tools (Flutter, Git, Xcode, etc.) are available on PATH before any work begins.

```yaml
- id: preflight
  type: preflight_check
  name: Preflight Check
  abort_on_failure: true
```

No `params`.

---

### `git_checkout`

Clones the repository (from `app.yaml → repository`) into a fresh workspace directory and checks out the specified branch.

```yaml
- id: checkout
  type: git_checkout
  name: Git Checkout
  abort_on_failure: true
```

No `params`. The branch is taken from the value entered in the Setup screen.

---

### `set_version`

Writes the version name and build number chosen in the Setup screen into `pubspec.yaml` inside the workspace.

```yaml
- id: set_version
  type: set_version
  name: Set Version
  abort_on_failure: true
```

No `params`.

---

### `flutter_pub_get`

Runs `flutter pub get` in the workspace.

```yaml
- id: pub_get
  type: flutter_pub_get
  name: Flutter Pub Get
  abort_on_failure: true
  depends_on: [checkout]
```

No `params`.

---

### `flutter_build`

Runs `flutter build` for the given platform and artifact type.

```yaml
- id: build_android
  type: flutter_build
  name: Build Android
  condition: android
  abort_on_failure: true
  depends_on: [pub_get]
  params:
    platform: android     # android | ios
    artifact: apk         # apk | appbundle | ipa
```

| Param | Values | Description |
|---|---|---|
| `platform` | `android`, `ios` | Target platform |
| `artifact` | `apk`, `appbundle`, `ipa` | Output format |

For iOS, `artifact: ipa` delegates to the `ios_archive` step — the `flutter_build` step only compiles the framework. Set them both.

---

### `ios_archive`

Runs `xcodebuild archive` and `xcodebuild -exportArchive` to produce a signed `.ipa` using the provisioning profile and export method from the environment config.

```yaml
- id: archive_ios
  type: ios_archive
  name: iOS Archive & Sign
  condition: ios
  abort_on_failure: true
  depends_on: [build_ios]
```

No additional `params`. All signing config comes from the environment YAML and the credentials stored in Keychain.

---

### `firebase_distribute`

Distributes the built artifact to Firebase App Distribution using the Firebase CLI.

```yaml
- id: firebase_android
  type: firebase_distribute
  name: Firebase (Android)
  condition: firebase_android
  abort_on_failure: false
  depends_on: [build_android]
  params:
    platform: android     # android | ios
```

Tester groups are read from **Settings → Firebase → Tester groups** (or from the env YAML `distribution.firebase.tester_groups`).

---

### `fastlane_lane`

Runs a named Fastlane lane from the project's `fastlane/Fastfile`.

```yaml
- id: testflight
  type: fastlane_lane
  name: Upload to TestFlight
  condition: testflight
  abort_on_failure: false
  depends_on: [archive_ios]
  params:
    lane: beta            # must match a lane name in your Fastfile
```

```yaml
- id: playstore
  type: fastlane_lane
  name: Upload to Play Store
  condition: playstore
  abort_on_failure: false
  depends_on: [build_android]
  params:
    lane: deploy
```

Your `Fastfile` must be committed to the repository (at the standard `fastlane/Fastfile` path) and the lane must accept the environment variables set by FlutterCI (e.g. `APPLE_ID`, `APP_SPECIFIC_PASSWORD` for TestFlight lanes).

---

## 13. Troubleshooting

### "app.yaml not found for project"
The project ID in the folder name does not match the `id` field in `app.yaml`, or the directory structure is wrong. Double-check:
```
~/.cicd/projects/<id>/app.yaml   # <id> must equal app.yaml → id field
```

### Build fails with "Flutter SDK not found" or "git: not found"
FlutterCI inherits the PATH of the user who launched it. If you launched it from Finder (not a terminal), PATH may not include your tool directories.

Fix: Launch FlutterCI from a terminal:
```bash
open /Applications/FlutterCI.app
```
Or add your tool paths to `~/.zshenv` (which is sourced for all shells, including those started by apps).

### iOS Archive fails with "no signing certificate"
Ensure:
1. The provisioning profile name in the env YAML exactly matches a profile installed in Xcode (Xcode → Settings → Accounts → Manage Certificates).
2. The Apple Team ID is set correctly in Settings.
3. The `export_method` matches the profile type.

### Firebase distribution fails with "Authentication Error"
The Firebase CI token has expired. Run `firebase login:ci` again and update the token in **Settings → Firebase**.

### "Keychain item not found" for Android passwords
The keystore passwords are scoped per project and environment. After selecting a different environment, re-enter and save the credentials in **Settings → Android Signing**.

### Build runs but produces no artifact buttons in the completion banner
The artifact was not found at the expected path. This can happen if:
- A custom Gradle output directory is configured in the project
- The build used a flavor name that doesn't match what FlutterCI expects

Check the live log output for the line beginning with `Artifact:` — if missing, the build output path resolution failed.

### Slack test message returns an error
The webhook URL must be the full URL starting with `https://hooks.slack.com/services/`. If it contains special characters, make sure you copied it without any trailing spaces.

---

## Quick Reference — File Locations

| Path | Purpose |
|---|---|
| `~/.cicd/projects/<id>/app.yaml` | Project definition |
| `~/.cicd/projects/<id>/envs/<env>.yaml` | Per-environment config |
| `~/.cicd/projects/<id>/pipelines/mobile.yaml` | Pipeline step definitions |
| `~/.cicd/projects/<id>/bundled/` | Bundled files (keystores, dart-define JSON) |
| `~/.cicd/runs/<run-id>/run.log` | Full log for a completed run |
| `~/.cicd/artifacts/<run-id>/` | Build artifacts (APK / AAB / IPA) |
| `~/.cicd/flutter_cicd.db` | SQLite database of run history |

---

*For questions or issues, contact the person who set up FlutterCI for your team.*
