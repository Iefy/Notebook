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

That `render` function is usually calling the exact same `buildToggleGroup`/`buildBoolToggleGroup` used in regular Preferences, just with a final `true` argument (`onboardingMode`). That flag filters out any individual item marked `onboarding: false` — so an item can be fully visible in Preferences but skipped during first-run if it's too niche to bother a new user with.

Two levels of opt-out:
- **Whole category doesn't apply to a blank workspace** (e.g. "Library", "Data management") → set `onboarding: false` on the *category* object, no `render` needed.
- **One setting within a category is too obscure for first-run** → set `onboarding: false` on that *item* inside its `*_ITEMS` array. It still shows in Preferences; onboarding just skips it.

If you add a brand-new `*_ITEMS` array for a new feature area, you get onboarding for free by adding one category entry that calls `buildToggleGroup`/`buildBoolToggleGroup` on it with `onboardingMode: true`. Nothing else in the wizard needs to change — it iterates `SETTINGS_CATEGORIES` and renders whatever isn't opted out.

---

## 4. Adding a new "room" (rail tab / page)

This is the one most people will actually want. Notebook has two kinds of top-level views:

- **Master-detail rooms** — Pages, Entries, Timelines. These share the `#panel` split-view layout and have their own dedicated wiring (list on the left, detail on the right). If what you're building genuinely needs that shape, look at how one of these three is wired as a reference; it's not a one-object registration, it's a structural pattern.
- **Simple full-view rooms** — Work, Calendar, Oracle. One view, no split panel. **This is almost certainly what you want**, and it's fully registry-driven.

To add a simple full-view room, find the `PAGES` array (search `PAGE REGISTRY`) and add one object:

```js
{
  key: "journal", label: "Journal", beta: true, recommended: false,
  railIcon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">...</svg>',
  railTip: "Journal — a plain SVG string, not HTML-escaped, keep it simple",
  railDesc: "What this does, shown next to the sidebar toggle in Preferences.",
  tileGlyph: "☾",                 // single glyph shown on the Home tile
  tileDesc: "What this tile does, shown next to the Home-tile toggle in Preferences.",
  stat: function () {
    // Called every time Home re-renders. Return the tile's live numbers.
    return { desc: "Live description line", num: "3", unit: "entries today", nudge: false };
  },
  render: function () { renderJournalTab(); }   // your existing render function
}
```

That's it. This one object automatically:
- Adds a rail nav button (icon, label, tooltip) — generated at load, no HTML edit needed
- Becomes a valid tab (`boot()`'s validity check reads `PAGES`)
- Gets a "hide from sidebar" toggle in Preferences *and* onboarding's "What's in your sidebar?" step (both read `RAIL_TOGGLE_ITEMS`, which is `PAGES` mapped over)
- Gets a Home tile with your live stat line, and a "hide from Home" toggle — unless you set `homeTile: false`
- Gets its `#view-journal` / `#panel` show-hide CSS auto-injected — you still need to build the `<section id="view-journal">` markup itself and a `renderJournalTab()` function, but you never write `body[data-tab="journal"] #view-journal { display: flex }` by hand
- Gets called by `renderAll()` when its tab is active

Opt-outs, all explicit:
- `tab: false` — metadata only, no rail button / no route (rare; almost nothing needs this)
- `homeTile: false` — has its own richer Home presence instead of a plain tile (this is what Calendar does — see §5)
- Omit `beta`/`recommended` — no tag shown

You still have to build the actual view: a `<section id="view-KEY">` in the HTML body, and whatever `render()` calls. The registry only handles the *plumbing* around that view, not the view's contents.

---

## 5. Home tiles vs. Home sections

Two different ways a room can show up on Home, and they're not interchangeable:

- **A tile** (`HOME_TILE_ITEMS`, or `homeTile` on a `PAGES` entry) is a small shortcut card: glyph, label, one stat number, click to jump to the room. Good default for most things.
- **A section** (`HOME_SECTION_ITEMS`) is a full custom block below the tiles — like the Calendar week strip, or the Activity heat-grid. Use this when a single number-and-glyph card can't represent what the feature actually offers. It needs its own `<div id="home-sect-KEY">` markup and its own render call inside `renderHub()` — a section is *not* auto-generated the way a tile is, it's a bespoke block that's just hideable the same generic way.

If your feature has both — a rail room *and* a richer Home presence — do what Calendar does: register it in `PAGES` with `homeTile: false`, and separately add it to `HOME_SECTION_ITEMS` with its own hand-built section. Don't show the same feature as both a tile and a section; it reads as clutter.

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
Add one object to `PAGES` (§4). Build the `<section id="view-KEY">` and its render function. Don't touch CSS, don't touch the rail HTML, don't touch `VALID_TABS`.

**"I want it to skip onboarding but stay in Preferences."**
Add `onboarding: false` to the item (not the whole category, unless the whole category should be skipped).

**"I want a double-click interaction to be discoverable."**
Add the `dbl-clickable` class. Nothing else.

**"I'm adding a field to `state`."**
Default in blank-state, sanitize in `normalizeState`, default in the legacy-fallback object, and hook into export/import if it should survive a backup (§7).

---

If a pattern here doesn't fit what you're building, that's a real signal — not everything should be forced through a registry. Master-detail rooms, one-off bespoke UI, anything genuinely unique: just build it, and don't feel obligated to bolt it onto one of these systems if it doesn't actually share behavior with what the system was built for. The point of all this is less hand-wiring for things that *are* repeated shapes, not architecture for its own sake.
