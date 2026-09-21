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

And when there is no command, the console is still not the person's job. Work down this ladder and
stop at the first rung that works:

1. **CLI** — `fastlane`, `firebase`, `gcloud`, `gh`.
2. **API** — a documented endpoint with a token, called from a script.
3. **Drive the browser yourself.** A console with no API is still a page: open it, fill the form,
   submit. "It has to be done by hand" means by *a* hand, not by *theirs*.
4. **Only then, the person** — and only for the three things below.

## Where the line actually is

| Task | Command | |
|---|---|---|
| Create the App Store Connect record + bundle ID | `fastlane produce` | automated |
| Certificates and profiles | `fastlane match` | automated |
| Upload a build to TestFlight | `fastlane pilot` / `upload_to_testflight` | automated |
| Store text, screenshots | `fastlane deliver` / `upload_to_app_store` | automated |
| **Create the app on Google Play + its first upload** | no API — drive the console in a browser | agent, once |
| Every Play release after the first | `fastlane supply` / `upload_to_play_store` | automated |
| Firebase project, apps, rules, indexes | `firebase` CLI | automated |
| GCP service accounts, APIs, secrets | `gcloud` | automated |
| Repos, releases, secrets, PRs | `gh` | automated |

Google Play is the one with no CLI path: `supply` refuses to run until a version already exists and
cannot create the listing. That makes it rung 3, not rung 4 — open the console in a browser and fill
the form. Say plainly that there is no API for it; that's a real limit, not laziness.

## The three things that stay with the person

Everything else is yours. These are not.

- **Signing in.** Never type someone's password, 2FA code, or API key into a page. Ask them to sign
  in first, then take over the tab that is already authenticated.
- **Agreeing to something.** Developer agreements, tax and banking forms, privacy declarations,
  anything binding in their name. Show them what's on the screen and let them click it.
- **Paying.** Registration fees, plan changes, anything that moves money.

When you hand one of these over: say **why** in one line (without the reason, they assume you didn't
look), give the shortest path rather than a tour, mark it **one-time** if it is and write it into the
project's `CLAUDE.md` so it isn't rediscovered every release, and automate both sides of it. A manual
step in the middle is not a reason to hand over the whole sequence.

## Smell list

"Go to … → click … → then click …" for something with a documented API · handing over a form you could
have filled in the browser yourself · a release checklist that is all prose · asking the user to paste
a key from a console when the CLI can mint it · the same manual step explained twice in two sessions
because nobody wrote it down.
