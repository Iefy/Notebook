# Extending Notebook

Notebook is one big HTML file — one `<style>` block, one `<body>`, one `<script>`. There's no build step, no framework, no bundler. That's deliberate: you should be able to open `Notebook.html`, search for something, change it, and refresh.

This doc is about the handful of patterns that make it possible to *add* things — a new preference, a new room, a new tag — without hand-wiring them into six different places. If you're fixing a bug or editing one feature in isolation, you probably don't need this file. If you're adding something new and want it to behave like it belongs, read on.

The short version: **most things register themselves from a list of plain objects.** Add an object to the right list, and the app finds it — in Preferences, in onboarding, in the sidebar, wherever it's supposed to show up. You very rarely need to touch a `render` function to make a new *setting* appear.

---

## 1. Tags: Beta and Recommended

Any settings item — a sidebar room, a Home tile, a checkbox — can carry two flags:

```js
{ key: "oracle", label: "Oracle", desc: "...", beta: true }
{ key: "autoLinkUrls", label: "Turn typed web addresses into links", desc: "...", recommended: true }
```

`beta: true` renders a purple "Beta" pill next to the label. `recommended: true` renders a sage "Recommended" pill. Both are handled by one function, `toggleLabelEl(it)`, which every settings-list renderer calls. You never draw the tag yourself — you just set the flag on the object, and it shows up everywhere that object is rendered (Preferences *and* onboarding, since they usually share the same list — see §3).

Want a third tag someday ("New", "Experimental", whatever)? Add the flag check to `toggleLabelEl` and the matching CSS class (copy `.beta-tag` / `.recommended-tag`, they're right next to each other in the stylesheet). Every existing and future settings item picks it up automatically — you don't revisit each list.

---

## 2. The settings-item pattern

Almost every toggle in Preferences is one of two shapes, rendered by one of two shared functions.

**A hideable thing** (a sidebar room, a Home tile, an optional section) — rendered with `buildToggleGroup`:

```js
var WORK_SECTION_ITEMS = [
  { key: "history", label: "History", desc: "...", recommended: true },
  { key: "byLabel", label: "By label", desc: "..." }
];
buildToggleGroup(container, WORK_SECTION_ITEMS, "workSections");
```

The third argument (`"workSections"`) is the *bucket* — it maps to `state.settings.hidden.workSections`, an array of keys the user turned off. If you invent a new hideable bucket, you need to:
1. Add it to the `hidden: {...}` object in both places state gets initialized (search `railTabs: [], homeTiles: []` — there are two spots, blank-state and the legacy-migration fallback).
2. Add its list of valid keys to the `cleanList(...)` call inside `normalizeState` (this is what prunes stale keys if you rename/remove an item later — don't skip it, or a removed feature's hidden-flag lingers in storage forever).

**A plain on/off setting** (not a list of hideable things, just one boolean) — rendered with `buildBoolToggleGroup`:

```js
var STYLE_BOOL_ITEMS = [
  { key: "dblClickCursor", label: "Double-click cursor hint", desc: "...", recommended: true,
    onChange: function (v) { applyDblClickCursor(v); } }
];
buildBoolToggleGroup(container, STYLE_BOOL_ITEMS);
```

This one reads/writes `state.settings[it.key]` directly — no bucket, no cleanList. Simpler, but only fits a single yes/no flag, not "which of these N things are visible." Give it a sensible default in the same three places blank-state/normalizeState/legacy-fallback settings objects live (search `dblClickCursor` for a template — three edits, same pattern every time).

Either way: **you write the list once.** The checkbox, its label, its description, its tag, its click handling — all shared code. Don't hand-build a settings row from scratch; find the nearest existing `*_ITEMS` array and add to it, or start a new one if it's a genuinely new category.

---

## 3. Onboarding registers itself too

`SETTINGS_CATEGORIES` is the list that drives the first-run wizard. Each entry is a category with a `render(container)` function:

```js
{
  key: "work", title: "What should Work show?",
  lede: "Work is a session timer with a weekly goal. These sections are optional extras on top of it.",
  render: function (c) { buildToggleGroup(c.appendChild(el("div")), WORK_SECTION_ITEMS, "workSections", null, true); }
}
```

That `render` function is usually calling the exact same `buildToggleGroup`/`buildBoolToggleGroup` used in regular Preferences — every category's `render` in `SETTINGS_CATEGORIES` does exactly this (see `rail`, `home`, `work`, etc.). **Every item in the list you pass in shows up during onboarding, with no filtering** — `buildToggleGroup(container, items, bucket, onAnyChange)` and `buildBoolToggleGroup(container, items)` only take the arguments in that signature; there's no extra flag that skips individual items for first-run. If you want a specific item hidden from onboarding but still visible in regular Preferences, that per-item filter doesn't exist yet — you'd build it yourself (e.g. `items.filter(function (it) { return !it.onboarding; })` before handing the array to `buildToggleGroup`, and add the corresponding check inside the function if you want it centralized rather than repeated per category).

One level of opt-out that *does* exist today:
- **Whole category doesn't apply to a blank workspace** (e.g. "Library", "Data management") → set `onboarding: false` on the *category* object in `SETTINGS_CATEGORIES`, no `render` needed. This is real and in active use — see the `library`/`data`/`popouts` entries.

If you add a brand-new `*_ITEMS` array for a new feature area, you get onboarding for free by adding one category entry that calls `buildToggleGroup`/`buildBoolToggleGroup` on it. Nothing else in the wizard needs to change — it iterates `SETTINGS_CATEGORIES` and renders whatever isn't opted out at the category level.

---

## 4. Adding a new "room" (rail tab / page)

This is the one most people will actually want, and it's the one worth being most careful about: **there is no registry for this.** Despite what you might expect from §§1–3, adding a room is not a one-object registration — it's five separate hardcoded spots you edit by hand. (If you came here after searching for a `PAGES` array or a "PAGE REGISTRY" comment and found nothing, that's not you missing something — it doesn't exist.)

Notebook has two kinds of top-level views:

- **Master-detail rooms** — Pages, Entries, Timelines. These share the `#panel` split-view layout and have their own dedicated wiring (list on the left, detail on the right). If what you're building genuinely needs that shape, look at how one of these three is wired as a reference; it's a structural pattern, not something you register.
- **Simple full-view rooms** — Productivity, Oracle, and Home itself. One view, no split panel. This is almost certainly what you want, but it's still five manual edits, not one.

To add a simple full-view room, called `journal` here as an example:

1. **`RAIL_ITEMS`** — add one object: `{ key: "journal", label: "Journal", tip: "Journal", scope: "project", icon: '<svg ...>' }` (copy an existing entry's shape). This is what actually generates the sidebar button — `renderRailRooms()` builds `#rail-rooms` from this array at load. It's also what feeds `RAIL_TOGGLE_ITEMS` (a plain alias: `var RAIL_TOGGLE_ITEMS = RAIL_ITEMS;`), so adding it here automatically gets you the "hide from sidebar" toggle in Preferences → Display → Sidebar, and in onboarding's "What's in your sidebar?" step, for free — that part genuinely is shared, same as §§1–3.

2. **`VALID_TABS`** — a plain array declared inline inside `boot()` (search `var VALID_TABS = [`). Add `"journal"` to it. If you skip this, `boot()`'s validity check silently kicks anyone who lands on that tab (e.g. from a stale URL or an old save) back to `"hub"`.

3. **`renderAll()`** — a hardcoded `if/else` chain, not a lookup. Add a branch: `else if (tab === "journal") renderJournalTab();`. This is the dispatcher that actually calls your render function when the tab is active; nothing calls it automatically.

4. **CSS show/hide** — also hand-written, scattered near the top of the stylesheet as `body[data-tab="journal"] #view-journal { display: flex; }` (and `#panel { display: none; }` alongside it, following the pattern used for `oracle`/`productivity`/`hub`). Nothing generates this for you.

5. **A Home presence** — add to `HOME_TILE_ITEMS` (a plain `{ key, label, desc }` toggle entry, same shape as any other settings item — see §2) if a simple shortcut card is enough, or build a full `HOME_SECTION_ITEMS` entry plus hand-written markup if it needs more (see §5). Either way this is optional, but skipping it means the room is only reachable from the sidebar.

You still build, as always: a `<section id="view-journal">` in the HTML body, and a `renderJournalTab()` function that fills it in.

**None of this is auto-generated.** If you're adding several rooms and this friction bothers you, that's a legitimate thing to fix — pulling steps 1–4 into one shared registration function (even without the full imagined shape from an earlier draft of this doc) is a reasonable follow-up, just not something that exists today.

---

## 5. Home tiles vs. Home sections

Two different ways a room can show up on Home, and they're not interchangeable:

- **A tile** (`HOME_TILE_ITEMS`) is a small shortcut card: glyph, label, one stat number, click to jump to the room. Good default for most things.
- **A section** (`HOME_SECTION_ITEMS`) is a full custom block below the tiles — like the Calendar week strip, or the Activity heat-grid. Use this when a single number-and-glyph card can't represent what the feature actually offers. It needs its own `<div id="home-sect-KEY">` markup and its own render call inside `renderHub()` — a section is *not* auto-generated the way a tile toggle is, it's a bespoke block that's just hideable the same generic way (§2).

If your feature has both — a rail room *and* a richer Home presence — do what Calendar does: give it its own `HOME_SECTION_ITEMS` entry with hand-built markup instead of also adding a plain tile for the same thing. Don't show the same feature as both a tile and a section; it reads as clutter.

---

## 6. The double-click cursor hint

Any element the user double-clicks to do something (not single-click) should say so with the cursor, not just rely on people discovering it. Add the class:

```html
<button class="... dbl-clickable">
```

or in JS: `cls += " dbl-clickable"`. That's the whole API — it swaps the cursor to a small double-click icon on hover, and falls back to a plain pointer if the browser can't render custom cursors. It's toggleable app-wide via **Preferences → Style → "Double-click cursor hint"** (`state.settings.dblClickCursor`), so you don't need to check that setting yourself — just add the class and the global toggle handles the rest.

For canvas-based elements (nothing in the DOM to attach a class to — see the timeline graph), you toggle the class on the canvas element itself based on hover-hit-testing; search `dbl-clickable` in the graph's `pointermove` handler for the pattern.

---

## 7. State: what you must do for any new data

Every new field you add to `state` needs to survive a save/reload and a hostile/old import file. Three touch points, always:

1. **Blank state** — the shape a brand-new workspace gets. Give every field a real default, not `undefined`.
2. **`normalizeState(s)`** — runs on *every* load, including imported files from god-knows-what version of the app. Never trust `state` to already have the right shape; always sanitize with explicit type/range checks (see how `state.plans` is sanitized — array check, per-field type coercion, a `.filter()` at the end to drop anything that didn't come out valid). If you skip this, a corrupted or hand-edited save file can crash the whole app on load.
3. **The legacy-fallback default object** (the giant one-liner near the top of `normalizeState` used when `state.settings` doesn't exist at all yet) — easy to forget since it's not near the other two. Search for an existing key you know is in all three (e.g. `dblClickCursor`) to find all three spots at once.

If the data should be included in exports/backups, add it to:
- The JSON export object (search where `restDays`/`restTokens` get written out)
- The JSON import merge (same search, the `data.` reading side)
- A snapshot bucket in the export-picker UI, if it's substantial enough to warrant its own checkbox (see `{ key: "calendar", label: "Calendar plans", fields: ["plans"] }` as a template)

---

## 8. Recurrence / multi-day patterns (case study)

If you're building something date-based that might repeat or span multiple days, don't reinvent this — the Calendar feature (`state.plans`) already solved it generically:

- Every occurrence resolves to a canonical **start date key**, even for multi-day spans — `occurrenceStartForDay(plan, k)` walks backward from any day in a span to find where the instance actually began. Anything stateful about an instance (done/not-done, skip-this-one) is keyed by that start date, never by "whichever day the user happened to be looking at." This is the detail that's easy to get wrong: if you key state by the viewed day instead of the occurrence's start, marking a 3-day event "done" from its middle day silently creates a duplicate, disconnected state entry.
- Recurrence is *computed*, not pre-generated — there's no stored list of future occurrences to keep in sync. `isValidOccurrenceStart` answers "does this rule produce an occurrence starting on day k" for weekly/monthly/every-N-days, and callers ask it fresh for whatever date range they're currently rendering. Cheap, and it can never drift out of sync with an edited rule.
- Skipping one occurrence vs. deleting the whole series are different operations on purpose (`exceptions[dateKey] = "skip"` vs. removing the plan object entirely) — if your feature has anything repeating, users will want both, so build the distinction in from the start rather than retrofitting it.

---

## Quick recipes

**"I want a new checkbox in Preferences."**
Find the nearest matching `*_ITEMS` array, add `{ key, label, desc, beta/recommended }` to it. If it's a single on/off flag, that array feeds `buildBoolToggleGroup` and you write an `applyX()`/`onChange` if it needs to do something live. Give it a default in all three state-shape spots (§7).

**"I want a new room in the sidebar."**
No registry for this one — five manual edits (§4): add to `RAIL_ITEMS`, add to `VALID_TABS` inside `boot()`, add a branch to `renderAll()`'s if/else chain, hand-write the `body[data-tab="..."]` show/hide CSS, and build the `<section id="view-KEY">` plus its render function. Optionally add a `HOME_TILE_ITEMS`/`HOME_SECTION_ITEMS` entry too.

**"I want it to skip onboarding but stay in Preferences."**
Only works at the whole-category level today — add `onboarding: false` to the category object in `SETTINGS_CATEGORIES`. There's no built-in way to skip a single item within a category while keeping the rest of that category in onboarding (§3) — you'd need to add that filtering yourself.

**"I want a double-click interaction to be discoverable."**
Add the `dbl-clickable` class. Nothing else.

**"I'm adding a field to `state`."**
Default in blank-state, sanitize in `normalizeState`, default in the legacy-fallback object, and hook into export/import if it should survive a backup (§7).

---

If a pattern here doesn't fit what you're building, that's a real signal — not everything should be forced through a registry. Master-detail rooms, one-off bespoke UI, anything genuinely unique: just build it, and don't feel obligated to bolt it onto one of these systems if it doesn't actually share behavior with what the system was built for. The point of all this is less hand-wiring for things that *are* repeated shapes, not architecture for its own sake.
