# Notebook's GitHub-hosted files

This is what Notebook.html expects to find at the root of this repo, on the
`main` branch (see `GITHUB_BRANCH`/`REPO_OWNER`/`REPO_NAME` near the top of
the HTML file if you ever rename the repo or use a different branch).

```
/
├── Notebook.html          the app itself — what people download/open
├── version.json           read by "Check for updates" in Preferences
└── oracle/
    ├── brain.json         what Oracle knows (topics, keywords, answers)
    └── logic/
        ├── greetings.json     shown when Oracle's chat is first opened
        ├── openers.json       "Sure, here's..." / "Of course —" lines
        ├── connectors.json    "Also, for your..." lines between topics
        ├── followups.json     "Want to set a new goal?" nudges per widget
        └── closers.json       (reserved — not wired into the UI yet)
```

## How Notebook uses these

- **version.json** — checked once per boot. If a changelog entry's version
  is newer than the running app's, it shows the update modal. A version
  string can end in `-dev`, `-beta`, etc. to mark its channel; no suffix
  means stable. Bump `"version"` at the top *and* add a matching entry to
  `"changelog"` for each release.

- **oracle/brain.json** — an array of entries under the `"entries"` key.
  Each one:
  ```json
  {
    "id": "unique-id",
    "title": "Shown on the topic chip",
    "keywords": ["words", "it", "should", "match"],
    "answer": "What Oracle says the first time this comes up.",
    "widget": "recap"   // optional — see below
  }
  ```
  `keywords` don't need to be exhaustive phrasing — Oracle does its own
  fuzzy word-overlap matching and typo tolerance on top of whatever's
  listed, so a handful of the obvious words per entry is enough.

  `"widget"` is optional and only means anything if it matches one Oracle
  already knows how to render live: currently `"recap"`, `"goal"`,
  `"tasks"`, `"toggle"`, or `"style"`. Leave it out for anything else — it
  just becomes a plain text answer with no live data attached. Adding
  *new* widget types isn't something a JSON file can do on its own; that
  needs a matching code change in Notebook.html.

  `"toggle"` is the one that needs two extra fields on the entry:
  ```json
  { "widget": "toggle", "toggle": "pomodoroEnabled", "toggleLabel": "Pomodoro" }
  ```
  `"toggle"` is the actual `state.settings` key being flipped — it has to
  already exist as a real boolean setting in the app; a JSON file can't
  invent a new one. `"toggleLabel"` is just the display name. Once an
  entry is set up this way, people can say "turn on pomodoro" /
  "disable pomodoro" as a direct command, and Oracle will also offer to
  flip it for them ("want to give it a try?") when they ask about it
  while it's off — replying "yes" to that offer works the same as typing
  the full command.

  For a widget-bearing entry, `"answer"` is only ever shown when the
  question was clearly conceptual ("how do rest days work", "what's a
  tag", "explain pomodoro"). A plain status check ("my tasks", "weekly
  goals and tiers") skips straight to the live widget with a short,
  freshly-computed data sentence instead — write `"answer"` as a real
  explanation, since it won't show up every time regardless.

- **oracle/logic/*.json** — each file is optional and independent. A
  missing or broken one just falls back to Notebook's own built-in default
  for that file only; it doesn't affect the others or stop Oracle from
  working. Exact shape each file needs:
  - `greetings.json` → `{ "greetings": ["...", "..."] }`
  - `openers.json` → `{ "single": ["...", "..."], "multi": ["...", "..."], "howto": ["...", "..."] }`
    (`howto` is used when the question is conceptual — "how do rest days
    work", "what's a tag" — as opposed to a plain status check like "my
    tasks", which uses `single` instead)
  - `connectors.json` → `{ "connectors": ["...", "..."] }`
  - `followups.json` → `{ "goal": ["...", "..."], "tasks": [...], "recap": [...], "default": [...] }`
    (add more keys here matching future widget names as they're added)
  - `closers.json` → `{ "closers": ["...", "..."] }`

## Updating Oracle without an app release

Edit `oracle/brain.json` (add entries, tweak answers, expand keywords) or
any `oracle/logic/*.json` file and push to `main`. Notebook re-checks once
a day automatically, and anyone can force it sooner from Preferences →
Feedback... no — from Oracle's own "Check for updates" button, next to the
knowledge status line at the bottom of the Oracle screen.

## Offline / manual updating

Oracle's "Import file…" button (next to "Check for updates") accepts one
combined JSON file instead of the folder above, shaped like:
```json
{
  "entries": [ /* same shape as brain.json's entries */ ],
  "logic": {
    "openers": { "single": [...], "multi": [...] },
    "connectors": { "connectors": [...] },
    "followups": { "goal": [...], "tasks": [...], "recap": [...], "default": [...] },
    "closers": { "closers": [...] },
    "greetings": { "greetings": [...] }
  }
}
```
Every key is optional — include only what you're actually changing.
