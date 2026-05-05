## 0.3.1

* Re-publish to retry pub.dev analysis. v0.3.0 was scored 70/160 because the
  pub.dev analyzer's dependency resolver hit a transient upstream outage
  (advisories endpoint failed), which cascaded into 0/50 static analysis,
  0/20 platform support, and 0/10 dartdoc coverage. No code changes — `pana`
  locally reports 160/160.

## 0.3.0

* New: WebView inspector support — capture XHR and `fetch` calls happening
  inside any WebView page (think Chrome DevTools' Network tab) by injecting
  `webViewInterceptorScript` and forwarding events to
  `samseer.recordWebViewEvent(...)`. Samseer itself does **not** depend on
  `flutter_inappwebview`; the host app wires the script + JavaScript handler
  to whichever WebView library it uses.
* New: public recording API on `Samseer` — `recordRequest`, `recordResponse`,
  `recordError` — so any custom transport (WebView, GraphQL, gRPC, …) can
  feed calls into the inspector.

## 0.2.2

* Fix: Dio interceptor now serializes custom request body objects (classes
  with `toJson()`) so the inspector shows the actual JSON sent on the wire
  instead of the Dart object's `toString()`

## 0.2.1

* Docs: new "Notifications (optional)" section in the README showing how to
  bridge `samseer.callsStream` into `flutter_local_notifications` (or any
  notification stack) — Samseer itself stays dependency-free
* Example: added `SamseerNotificationBridge` and wired it into the example
  app so users can copy a working reference end-to-end

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
