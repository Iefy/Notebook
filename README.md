![Notebook](icons/banner.png)

Notebook is a single-file, local-first world-building and writing tool — pages, a world bible, timelines, a work timer, and a few things to help when you're stuck. No account, no server, no install.

## Getting started

Download `Notebook.html` and open it in any modern browser. That's the whole install — everything runs client-side in that one file, with no build step, no dependencies, and no account.

The first time it opens, a short setup walks you through a few starting preferences (sidebar layout, accent color, and so on). You can change any of it later, or re-run it, from **Preferences → Redo setup**.

## Staying up to date

Notebook checks once per launch for a newer version and, if one exists, shows what's changed. You can also check on demand any time from **Preferences → Check for updates**. If you dismiss a notice, it won't ask again until a further update ships — a manual check always shows the latest, even for a version you'd previously dismissed.

## Data & privacy

Everything you write — pages, entries, timelines, sessions — is stored **only in your browser**, primarily in IndexedDB (with a localStorage fallback for older browsers). Nothing is sent to a server, because there is no server. That also means:

- Clearing your browser's site data, switching browsers/devices, or using a private window all start you over from nothing.
- The only copy that leaves the browser is a **JSON export** (`Preferences → Data → Export JSON`). Get in the habit of exporting after anything you'd hate to lose.
- Automatic **snapshots** (`Preferences → Snapshots`) protect against in-app mistakes (accidental deletes, bad edits) but live in the same browser storage — they are not a substitute for exporting.
- Moving `Notebook.html` to a new folder or computer doesn't carry your data with it. Export first, then import into the copy at the new location.

## Browser support

Needs a modern browser with IndexedDB support — current Chrome, Firefox, Safari, or Edge all work. If you notice data isn't persisting, it's usually a private/incognito window (some browsers wipe IndexedDB when it closes) — try a normal window instead.

## License

This project is licensed under the GNU GENERAL PUBLIC LICENSE Version 3 — see [LICENSE](LICENSE) for details.
