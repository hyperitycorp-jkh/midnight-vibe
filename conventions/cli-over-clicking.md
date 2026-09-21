---
name: cli-over-clicking
applies: any task that touches a console — App Store Connect, Play, Firebase, GCP, GitHub, hosting
---

# Don't send a person to a web console

**Never ask about this in the interview.** It is how the work is handed over.

## The rule

A click-path is not an instruction, it's an unfinished task. `appstoreconnect.apple.com → Apps → + →
New App` is something a command already does — writing it out as steps moves work onto the person and
loses it the moment they close the tab.

**Write the command.** If credentials are missing, say which env var is missing and how it's obtained
— that is still a command the person can run, not a tour of someone's UI.

## Where the line actually is

| Task | Command | |
|---|---|---|
| Create the App Store Connect record + bundle ID | `fastlane produce` | automated |
| Certificates and profiles | `fastlane match` | automated |
| Upload a build to TestFlight | `fastlane pilot` / `upload_to_testflight` | automated |
| Store text, screenshots | `fastlane deliver` / `upload_to_app_store` | automated |
| **Create the app on Google Play + its first upload** | — | **console, genuinely once** |
| Every Play release after the first | `fastlane supply` / `upload_to_play_store` | automated |
| Firebase project, apps, rules, indexes | `firebase` CLI | automated |
| GCP service accounts, APIs, secrets | `gcloud` | automated |
| Repos, releases, secrets, PRs | `gh` | automated |

Google Play is the one that isn't automatable: `supply` refuses to work until a version already
exists, and it cannot create the listing. Say that plainly when it comes up — it's a real limit, not
laziness.

## When a step really is manual

1. Say **why** it can't be automated, in one line. Without the reason, the next person assumes you
   didn't look.
2. Give the shortest path, not a tour.
3. Mark it **one-time** if it is, and write it into the project's `CLAUDE.md` so it isn't rediscovered
   every release.
4. Automate everything on both sides of it. A manual step in the middle is not a reason to hand over
   the whole sequence.

## Smell list

"Go to … → click … → then click …" for something with a documented API · a release checklist that is
all prose · asking the user to paste a key from a console when the CLI can mint it · the same manual
step explained twice in two sessions because nobody wrote it down.
