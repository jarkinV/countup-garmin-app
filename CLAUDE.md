# Countup (Garmin Connect IQ)

Countup for the user's **fēnix 9 Pro Solar 47mm** (`fenix9prosolar47mm`: 260x260, MIP, 64 colors, API 6.0.3): the mirror of the built-in Countdown. Events with a past date, the app shows how many days have passed. `watch-app` with a glance view, personal sideload only.

`PLAN.md` holds the decisions, the screen design and the stages (in Ukrainian). The user writes in Ukrainian; answer in Ukrainian.

Sibling project `../spd-garmin-app` (GPS speedometer) is the reference for structure, scripts and conventions; it has skills `spd-build-run`, `spd-test`, `spd-release` whose workflow applies here too (same scripts, different app name).

## Commands

```bash
scripts/build.sh         # debug compile
scripts/run.sh           # sim + compile + push (long-lived, run in background)
scripts/push.sh          # push debug build to running sim (long-lived)
scripts/stop.sh          # stop the simulator
scripts/test.sh [name]   # unit tests in the simulator
scripts/release.sh       # bin/countup-garmin-app-release.prg
scripts/run-release.sh   # release build in the sim (long-lived)
scripts/run-screenshots.sh        # demo build (screenshots.jungle) in the sim (long-lived)
python3 -I scripts/capture-readme.py  # regenerate docs/*.png, docs/browse.gif for the README
```

They wrap the `garmin-dev` plugin (`.claude/settings.json` enables it) and force JDK 17. Do not call `monkeyc`/`monkeydo` directly. For Connect IQ API questions use the `garmin-dev` skill and its cached docs.

## Layout

| File | Role |
|---|---|
| `source/CountupApp.mc` | AppBase: `getInitialView`, `getGlanceView` |
| `source/CountupGlanceView.mc` | Glance row (`:glance` scope) |
| `source/EventView.mc` | Event screen, page dots, empty state; `turnPage`, `showEvent`, `currentEvent` |
| `source/EventDelegate.mc` | UP/DOWN/swipe pages; START (`onKey` KEY_ENTER, not `onSelect`) and MENU open the menu, or Add with no events |
| `source/EventMenu.mc` | `EventFlows`: menu, Add (date -> name), Edit submenu, Delete confirmation, Show in glance; `MenuDelegate`, `DeleteDelegate` |
| `source/DatePicker.mc` | `RangeFactory`, `DatePicker` (day/month/year), `DatePickerDelegate`, `NameDelegate` (TextPicker) |
| `source/Format.mc` | Display text: day counts, `3y 4m 17d`, `12 Jun 2023`, milestone labels (English, in code so the glance can use it) |
| `source/DateMath.mc` | Pure calendar math on `[y, m, d]` arrays: `daysBetween`, `ymdBetween`, milestones; `today()` is the only clock access |
| `source/EventStore.mc` | `CountupEvent` + `EventStore`: up to 10 events sorted newest first, glance event choice, `Application.Storage` keys `events` / `glanceId` / `nextId` |
| `source/DemoData.mc` | Fixed sample events, reset on every start; real only in the screenshot build (`screenshots.jungle` excludes `nodemo`, `monkey.jungle` excludes `demo`) |
| `test/*Test.mc` | Unit tests; `EventStore(false)` keeps them off real storage |
| `resources/` | strings, launcher icon (40x40, copied from spd as a placeholder) |

Planned files are listed in `PLAN.md` → "Структура".

## Glance scope

- The glance runs with ~32 KB. Everything it uses needs `(:glance)`: classes, and strings via `scope="glance"` in `strings.xml`. Keep `EventStore` and `DateMath` glance-scoped and small; views, menus and pickers stay out of it.
- The entry class `CountupApp` is in glance scope implicitly, so `getInitialView` referencing the non-glance UI classes gives `not available in all function scopes` warnings at `CountupApp.mc` `getInitialView` (currently five). They are expected and the only warnings allowed; any other warning, or one at another location, must be fixed.

## View stack

- `Picker` does not pop itself: the accept callback pops it (Edit) or replaces it with `switchToView` (Add -> name). `TextPicker` and `Confirmation` pop themselves.
- Add and Delete pop the menu before pushing their first view, so they always end on the event screen; Delete -> No therefore returns to the event screen, not the menu.

## Rules

- Never commit, print or regenerate `developer_key` / `developer_key.pem` (same key as spd).
- After any change: `scripts/build.sh` with no warnings beyond the `getInitialView` ones above, `scripts/test.sh` all passing, then check in the simulator with the user.

## Seeing and driving the simulator

The embedded Claude Code process (`~/Library/Application Support/Claude/claude-code/<version>/.../claude.app`) has Screen Recording and Accessibility, so Claude can:
- capture only the simulator window: find its id with `CGWindowListCopyWindowInfo` via `osascript -l JavaScript` (window name starts with `CIQ Simulator`), then `screencapture -x -o -l <id>`. Never capture the whole screen: it shows the user's other work.
- press buttons: focus `process "simulator"` with System Events, then `key code` 125 Down = DOWN, 126 Up = UP, 36 Return = START, 53 Escape = BACK. Mouse clicks on the bezel do nothing. The simulator sometimes swallows a key, so compare frames and retry.
- switch Settings > Glance Launch Mode, then relaunch the app to see the glance.
The permission is tied to the Claude Code version path; after an update it may need granting again. `scripts/capture-readme.py` has working code for all of this.
- After `scripts/test.sh` the simulator will not start the normal app until restarted: `scripts/stop.sh`, then `scripts/run.sh`.
- Keep testable logic (`DateMath`, `EventStore`) out of views and delegates, cover it in `test/`.
- Keep `PLAN.md` in sync when a decision changes.
