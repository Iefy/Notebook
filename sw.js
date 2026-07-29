// Notebook service worker — caches the app shell so it opens (and keeps
// working) offline. All real data lives in IndexedDB/localStorage in the
// page itself, not here; this only ever caches the code, never your notes.
//
// Bump CACHE_NAME whenever Notebook.html changes so clients pick up the new
// version instead of an old cached copy.
var CACHE_NAME = "notebook-shell-v1";
var SHELL_FILES = [
  "./Notebook.html",
  "./manifest.json",
  "./icons/icon-192.png",
  "./icons/icon-512.png",
  "./icons/icon-192-maskable.png",
  "./icons/icon-512-maskable.png"
];

self.addEventListener("install", function (event) {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(function (cache) { return cache.addAll(SHELL_FILES); })
      .then(function () { return self.skipWaiting(); })
  );
});

self.addEventListener("activate", function (event) {
  event.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(
        keys.filter(function (k) { return k !== CACHE_NAME; })
            .map(function (k) { return caches.delete(k); })
      );
    }).then(function () { return self.clients.claim(); })
  );
});

self.addEventListener("fetch", function (event) {
  if (event.request.method !== "GET") return;

  // Network-first for the app page itself, so anyone online always gets the
  // latest version; offline (or a flaky connection) falls back to whatever
  // shell is cached.
  var isShellNav = event.request.mode === "navigate" ||
    SHELL_FILES.some(function (f) { return event.request.url.indexOf(f.replace("./", "")) > -1; });

  if (isShellNav) {
    event.respondWith(
      fetch(event.request)
        .then(function (res) {
          var copy = res.clone();
          caches.open(CACHE_NAME).then(function (cache) { cache.put(event.request, copy); });
          return res;
        })
        .catch(function () { return caches.match(event.request).then(function (r) { return r || caches.match("./Notebook.html"); }); })
    );
    return;
  }

  // Everything else: cache-first, falling back to network.
  event.respondWith(
    caches.match(event.request).then(function (cached) { return cached || fetch(event.request); })
  );
});
