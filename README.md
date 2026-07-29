![Notebook](icons/banner.png)
- **Pages** — rich-text notes grouped into notebooks, with in-line topic links and a back-bar to trace where you came from.
- **Entries** — your world bible: characters, places, factions, concepts, and any custom type you define, each with attributes, sections, tags, and links to other entries.
- **Timelines** — epochs and eras with dated events, a visual chart view, and a force-directed relationship **graph/map** of every entry sized by how connected it is.
- **Work** — a session timer, a weekly hour goal, and a full medal/streak/prestige system for the hours you put in.
- **Oracle** — draws two entries together and asks what connects them, for when you're stuck.
- **Global search** — `Ctrl/Cmd + K` searches page titles/bodies, entry names/attributes/sections, and timeline/era/event text all at once.
- **Snapshots & export** — automatic local restore points, plus one-click JSON export/import (including reading old Suitebook exports).
- **Installable** — works as a PWA: install to your desktop/dock/home screen.

## Getting started

### Just want to use it

Download `Notebook.html` and open it in any modern browser — everything runs client-side, no build step, no dependencies. Some browsers are stricter about local storage APIs when the file is opened directly from disk rather than served; if you notice data not persisting, try the local hosting option below instead.
<br>
<sub>*[see browser support](#browser-support)*</sub>

### Hosting it (for PWA install, or access from anywhere)

To install Notebook as an app (rather than just opening the file), it needs to be served from a real web origin — `https://` or `localhost`. Plain `file://` won't support the service worker.

Keep these together in one folder:

```
Notebook.html
manifest.json
sw.js
icons/
  icon-192.png
  icon-512.png
  icon-192-maskable.png
  icon-512-maskable.png
```

**Free hosting options:**
<!-- - **GitHub Pages** — push this repo, then enable it under *Settings → Pages* (source: deploy from branch, `main`, root). Your app will be at `https://iefy.github.io/<repo>/Notebook.html`. -->
- **Netlify / Cloudflare Pages** — drag-and-drop the folder onto their dashboard.
- **Local testing** — run `python3 -m http.server 8000` in the folder and open `http://localhost:8000/Notebook.html`. Localhost counts as secure, so install/offline both work here too.

### Installing it as an app

Once it's loading from an `https://` or `localhost` URL:
- **Desktop Chrome/Edge** — look for the install icon in the address bar, or "Install app" in the browser menu.
- **Android Chrome** — "Add to Home Screen" / install banner.
- **iOS Safari** — Share → "Add to Home Screen" (iOS doesn't support the automatic prompt, but the icon and name still apply).

### Download for Mac

Notebook also ships as a native standalone Mac app — a real app window (not a browser tab), built with a small Swift/WKWebView wrapper around `Notebook.html`.

**To build it yourself** (currently the only way to get it — no pre-built download has been published yet):

1. Make sure you have Xcode Command Line Tools installed: `xcode-select --install`
2. From the repo root, run:
   ```
   ./build-mac-app.sh
   ```
3. This produces `dist/Notebook.app` and `dist/Notebook-mac.zip`. Drag `Notebook.app` to your Applications folder.

If a maintainer has since published a build, check the [Releases](../../releases) page first for a ready-made `Notebook-mac.zip` — that saves you the build step.

**Important — leave the app where you first put it.** Notebook.app stores its data (via the browser engine it embeds) tied to its own file path. As long as it stays in `/Applications` (or wherever you first ran it from), your data persists normally across launches, same as any other Mac app. If you move or rename the `.app` later, it will appear to start empty — the old data isn't deleted, it's just no longer reachable from the new location.

If you do need to move or rename it, **export your data first**: `Preferences → Data → Export JSON` in the app, before you move anything. Once relocated, open the app from its new location and use `Preferences → Data → Import JSON` to bring everything back. This is the same export/import feature described in [Data & privacy](#data--privacy) below — it works just as well as a "carry my data across the move" step as it does for backups.

Since the app isn't signed by an Apple developer account, macOS Gatekeeper will flag it as from an "unidentified developer" the first time you open it — right-click the app → **Open** (or **System Settings → Privacy & Security → Open Anyway**) to get past that one-time warning.

<sub>Maintainers: run `./build-mac-app.sh` on macOS to regenerate `dist/Notebook.app` and `dist/Notebook-mac.zip`, then attach the zip to a new Release so users don't have to build it themselves.</sub>

## Data & privacy

Everything you write — pages, entries, timelines, sessions — is stored **only in your browser**, primarily in IndexedDB (with a localStorage fallback for older browsers). Nothing is sent to a server, because there is no server. That also means:

- Clearing your browser's site data, switching browsers/devices, or using a private window all start you over from nothing.
- The only copy that leaves the browser is a **JSON export** (`Preferences → Data → Export JSON`). Get in the habit of exporting after anything you'd hate to lose.
- Automatic **snapshots** (`Preferences → Snapshots`) protect against in-app mistakes (accidental deletes, bad edits) but live in the same browser storage — they are not a substitute for exporting.
- The Mac app has its own version of this caveat too — see [Download for Mac](#download-for-mac) above regarding moving the `.app`.

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| `Ctrl/Cmd + K` | Search everything (pages, entries, timelines) |
| `Ctrl/Cmd + N` | New page or entry |
| `Ctrl/Cmd + S` | Save immediately |
| `Ctrl/Cmd + B` | Bold (in the page editor) |
| `Tab` / `Shift+Tab` | Indent / outdent a list item (in the page editor) |
| `Esc` | Close the current modal/overlay |

## Project structure

| File | Purpose |
|---|---|
| `Notebook.html` | The entire app — markup, styles, and logic in one file |
| `manifest.json` | PWA metadata (name, icons, colors) for installability |
| `sw.js` | Service worker — caches the app shell for offline use |
| `icons/` | App icons (regular + maskable, 192px/512px) |
| `main.swift` | Native window/WKWebView wrapper used by the Mac app |
| `build-mac-app.sh` | Compiles `main.swift` and packages everything into `Notebook.app` (see [Download for Mac](#download-for-mac)) |

## Browser support

Needs a modern browser with IndexedDB support (all current Chrome, Firefox, Safari, Edge). PWA install/offline support additionally requires the app be served over `https://` or `localhost`, not opened directly as a local file.

## License

_No license has been chosen yet — add a `LICENSE` file if you want to make this open source (MIT is a common, permissive default for personal projects like this)._
