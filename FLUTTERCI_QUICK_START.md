# FlutterCI — Quick Start Guide

This guide walks you through using the FlutterCI app day-to-day. No configuration or setup knowledge required — just how to navigate the app, kick off a build, and understand what you're looking at.

> **Why this app exists:** We don't have a stable CI/CD pipeline for mobile in the org right now. FlutterCI fills that gap by running builds directly on your Mac using your locally installed tools (Flutter, Xcode, Fastlane, etc.). It is meant to be a practical stopgap until a proper CI infrastructure is in place.
>
> **Prerequisites:** Before using FlutterCI, make sure Flutter, Xcode, Android SDK, Fastlane, Firebase CLI, and Git are all installed and correctly configured on the Mac you're running it on.

---

## The App at a Glance

When you open FlutterCI you'll see a two-panel layout:

- **Left side** — navigation sidebar with four sections
- **Right side** — the active screen

The sidebar sections are:

| Section | What it does |
|---|---|
| **Setup & Run** | Choose a project, pick a branch, and start a build |
| **Execution** | Watch a build run in real time |
| **Run History** | Browse past builds, view logs, retry or resume |
| **Settings** | Credentials, notifications, and signing config |

The small coloured dot next to **Execution** lights up blue while a build is actively running.

---

## Running a Build

Everything starts from **Setup & Run**.

### Step 1 — Pick a project

Open the **Project** dropdown at the top. Select the project you want to build. If no projects are listed, ask your team lead to add one — projects are set up once and reused.

### Step 2 — Pick a branch

The **Branch** field loads your repository's branches automatically (give it a few seconds after selecting a project). Click the dropdown and select the branch you want to build from, or type the name directly.

### Step 3 — Set the version

Fill in:
- **Version Name** — the marketing version, e.g. `1.4.0`
- **Build Number** — the numeric build ID, e.g. `42`

These values are stamped into the app before it's compiled.

> The app remembers the last build config you used for each project and prefills these fields automatically when you select a project. You only need to change them if they've moved on.

### Step 4 — Choose an environment

Use the **Environment** selector to pick `dev`, `staging`, or `prod`. Each environment has its own signing certificates, distribution targets, and Firebase project pre-configured.

> If you select **prod**, you'll be asked to type a confirmation phrase before the build starts.

### Step 5 — Select platforms and targets

Toggle the platforms you want to build (**Android**, **iOS**) and the distribution targets (**Firebase**, **TestFlight**, **Play Store**). Only the ones that make sense for the selected environment will be active.

### Step 6 — Start the build

Click **Start Pipeline**. The app switches automatically to the **Execution** screen.

---

## Watching a Build (Execution Screen)

The Execution screen shows you exactly what's happening in real time.

### Step list (left panel)

Each pipeline step appears as a row. The icon on the left shows its status:

| Icon / colour | Meaning |
|---|---|
| Grey circle | Waiting — hasn't started yet |
| Blue spinner | Currently running |
| Green check | Completed successfully |
| Red X | Failed |
| Grey dash | Skipped (not applicable for this run) |
| Orange stop | Aborted |

Each completed step shows how long it took. Very fast steps (under 1 second) show `< 1s`.

Steps run top-to-bottom. If a step fails, subsequent steps that depend on it are skipped automatically.

**Distribution steps always wait for all build artifacts** — if you're building both Android and iOS, Firebase/TestFlight/Play Store steps won't start until both the APK and the IPA are ready.

### Log viewer (right panel)

Logs stream live while the step is running. Log lines are colour-coded:
- **White/grey** — informational output
- **Green** — success messages
- **Yellow** — warnings
- **Red** — errors

You can scroll back through the entire output, or click the copy icon to copy all logs to the clipboard.

### Aborting a build

Click the **Abort** button at the bottom of the step list. The currently running process is terminated immediately — you won't have to wait for the current step to finish.

### When it finishes

A banner appears at the bottom of the screen:

- **Green banner** — all steps passed. You'll see buttons to open the build artifact in Finder or copy its file path.
- **Red banner** — something failed. The step that caused the failure is highlighted in the step list. Click it to read the logs and find out why.

---

## Build History

The **Run History** screen keeps a record of every build.

### Browsing runs

The left panel lists all past runs, newest first. Each row shows:
- Project name and branch
- Date and time
- How long it took
- Whether it succeeded or failed

The sparkline chart at the top shows the duration trend across your recent runs — useful for spotting if builds are getting slower over time.

### Viewing a run's details

Click any run in the list to see its details on the right:
- Every step and its result, with duration per step
- Full logs for the run — with the same colour coding as the live view

### Retry

Found on the right panel of any run. **Retry** starts a completely fresh run from scratch using the exact same settings (branch, version, environment, platforms).

### Resume

Also available on failed runs. **Resume** re-runs only the steps that failed — it skips any step that already succeeded in that run. This is useful when a build fails late (e.g., during distribution) and you don't want to wait through a full rebuild.

> Use **Retry** when you've made a code change or suspect an intermittent failure.
> Use **Resume** when nothing changed and you just want to pick up where it left off.

---

## Build Artifacts

After a successful build, FlutterCI saves the output files (`.apk`, `.ipa`, `.aab`) to a permanent location on your Mac so they're available even after the build workspace has been cleaned up.

You can access them two ways:

- From the **green completion banner** on the Execution screen — click **Show in Finder** to open the folder, or **Copy Path** to copy the file path to your clipboard.
- Files are stored at `~/.cicd/artifacts/<run-id>/` if you need to find them manually.

---

## Menu Bar Icon

FlutterCI lives in your Mac's menu bar (top-right corner, near the clock). The icon colour tells you the current build state at a glance without switching to the app:

| Colour | State |
|---|---|
| Grey | Idle — no build running |
| Blue | Building |
| Green | Last build succeeded |
| Red | Last build failed |

Click the icon for a quick status summary, or to quit the app.

---

## Notifications

A macOS notification appears when each build finishes, showing the project, environment, version, and duration. If Slack is configured in Settings, a message is also posted to the configured channel.

---

## Tips

- You can navigate away from **Execution** mid-build (e.g. to check history) without interrupting it. The build keeps running in the background.
- The menu bar icon always reflects the current state even when the app window is hidden.
- If a build fails on a distribution step (Firebase, TestFlight) but the app compiled fine, use **Resume** — it skips the compile and goes straight to distribution.
- Build numbers must be higher than the last submitted build for TestFlight and Play Store. FlutterCI does not auto-increment — you set it manually each run.
- The `Install Dependencies` step runs `build_runner` automatically after `pub get`, so generated files (`.g.dart`, `.freezed.dart`) are always up to date before the build.
