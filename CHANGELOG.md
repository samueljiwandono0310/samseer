## 0.2.0

* New: top-of-screen `SamseerToast` notification with slide-down animation,
  variants (neutral/success/warning/error), and auto-dismiss
* Removed `share_plus` and `path_provider` dependencies — copy-to-clipboard
  is now used everywhere, with size-aware feedback (warns above 1 MB)
* "Copy as JSON" replaces the old "Export & Share" action in the inspector menu
* Removed share IconButton and Share button on the cURL tab — Copy buttons cover
  the workflow and the UI is leaner
* `Exporter` API: removed `shareAsJson`, `shareCurl`, `shareCallDump`,
  `originFor`. Added `buildJsonExport` and `formatSize`
* Flat chip styling — filter row no longer shows tonal shadow under chips
* Bumped major versions: `google_fonts ^8.1.0`, `intl ^0.20.2`,
  `sensors_plus ^7.0.0`
* Pub.dev score: 160/160

## 0.1.0

Initial release.

* Multi HTTP client support: Dio, http (package), HttpClient (dart:io)
* Material 3 inspector UI with light & dark themes
* Call list with search, status & method filters
* Tabbed call detail: Overview, Request, Response, cURL
* JSON viewer with syntax highlighting
* Stats screen with success rate, average duration, totals
* Shake-to-open inspector
* Floating inspector bubble (draggable, live call count)
* Export calls to JSON file & share
* In-memory storage with configurable max calls
* Single dependency — no separate adapter packages required
