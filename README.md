# Samseer

> Beautiful HTTP inspector for Flutter — a modern, all-in-one alternative to Alice, in a single package.

[![Pub](https://img.shields.io/pub/v/samseer.svg)](https://pub.dev/packages/samseer)
[![Style](https://img.shields.io/badge/style-flutter__lints-blue.svg)](https://pub.dev/packages/flutter_lints)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-5B6BFF.svg)](#-contribute-with-us)
[![Sponsor](https://img.shields.io/badge/Sponsor-💜-EA4AAA.svg)](https://github.com/sponsors/samueljiwandono0310)

Samseer captures every HTTP request your Flutter app makes — from **Dio**, the **`http`** package, and **`dart:io` HttpClient** — and presents it in a polished Material 3 inspector you can open with a shake, a tap on a floating bubble, or a single line of code.

If you've used [Alice](https://pub.dev/packages/alice) or [Chuck](https://github.com/jhomlala/chucker_flutter), Samseer is the spiritual successor: **same idea, modern UI, single dependency, no separate adapter packages**.

<p align="center">
  <img src="assets/screenshots/inspector.png" width="220" alt="Call list" />
  <img src="assets/screenshots/detail_overview.png" width="220" alt="Call detail — overview" />
  <img src="assets/screenshots/stat.png" width="220" alt="Stats" />
</p>

<p align="center">
  <img src="assets/screenshots/response.png" width="220" alt="Response tab with syntax-highlighted JSON" />
  <img src="assets/screenshots/cURL.png" width="220" alt="cURL tab" />
</p>

---

## ✨ Features

- 🎨 **Material 3 UI** with light & dark themes that follow the host app
- 🔌 **Three HTTP clients out of the box** — Dio, `http`, `dart:io HttpClient` — no extra packages
- 🔍 **Powerful call list** with live search, status & method filters
- 📑 **Tabbed call detail** — Overview · Request · Response · cURL
- 🌈 **Syntax-highlighted JSON viewer** built in
- 📊 **Stats screen** — totals, success rate, avg duration, status distribution
- 📱 **Shake-to-open** the inspector from anywhere in your app
- 💬 **Floating bubble overlay** with live call count (draggable)
- 📤 **Export & share** all calls as JSON, or copy any request as cURL
- 🪶 **Single dependency** — `samseer` and you're done. No `samseer_dio`, `samseer_http` etc.

---

## 🚀 Quick start

```yaml
# pubspec.yaml
dependencies:
  samseer: ^0.1.0
```

```dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:samseer/samseer.dart';

final samseer = Samseer();

void main() {
  // Dio
  final dio = Dio()..interceptors.add(samseer.dioInterceptor);

  // http package
  final httpClient = samseer.httpClient();

  // dart:io HttpClient (intercepts every HttpClient created globally)
  HttpOverrides.global = samseer.httpOverrides;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: samseer.navigatorKey, // required for shake & bubble
      home: const HomeScreen(),
    );
  }
}
```

That's it. Shake your phone or call `samseer.showInspector()` to open the inspector.

---

## 🧩 Integrations

### Dio

```dart
final dio = Dio();
dio.interceptors.add(samseer.dioInterceptor);
```

### `http` package

`samseer.httpClient()` returns a drop-in `http.Client` replacement. Pass an existing client to wrap it:

```dart
final client = samseer.httpClient();
// or wrap an existing one
final wrapped = samseer.httpClient(myExistingClient);

final response = await client.get(Uri.parse('https://api.example.com/me'));
```

### `dart:io` HttpClient

Install `HttpOverrides` once at app startup. Every `HttpClient` created anywhere in your app — including those used by `package:http`, Firebase, image libraries, etc. — will be recorded:

```dart
HttpOverrides.global = samseer.httpOverrides;
```

> 💡 If you set `HttpOverrides.global` you typically don't need `samseer.httpClient()` separately, since the `http` package uses `dart:io` HttpClient under the hood.

### Multiple clients at once

You can use all three integrations simultaneously. Samseer assigns a fresh ID per call so nothing is duplicated.

---

## 🎯 Opening the inspector

| Trigger | How |
|---|---|
| Shake the device | enabled by default; configure with `SamseerConfiguration(showInspectorOnShake: false)` to disable |
| Floating bubble | wrap your app: `MaterialApp(builder: (_, child) => samseer.overlay(child: child!))` |
| Programmatic | `samseer.showInspector()` (needs `navigatorKey`) or `samseer.showInspectorFromContext(context)` |
| From a debug button | wire `onPressed: samseer.showInspector` to any button or FAB |

---

## ⚙️ Configuration

```dart
final samseer = Samseer(
  configuration: const SamseerConfiguration(
    maxCallsCount: 500,
    showInspectorOnShake: true,
    showFloatingBubble: false,
    themeMode: ThemeMode.system,
    shakeThreshold: 20,
  ),
);
```

| Option | Default | Description |
|---|---|---|
| `maxCallsCount` | `1000` | Older calls are evicted FIFO once the limit is hit |
| `showInspectorOnShake` | `true` | Shake the device to open the inspector |
| `showFloatingBubble` | `false` | Set to `true` and wrap with `samseer.overlay(...)` |
| `themeMode` | `ThemeMode.system` | Forces light/dark theme of the inspector |
| `shakeThreshold` | `20` (m/s²) | Higher value = harder shake required |
| `directionality` | `null` | Force RTL/LTR inside the inspector |

---

## 🔄 Migrating from Alice

| Alice | Samseer |
|---|---|
| `Alice` | `Samseer` |
| `alice.getNavigatorKey()` | `samseer.navigatorKey` |
| `dio.interceptors.add(AliceDioAdapter(...))` | `dio.interceptors.add(samseer.dioInterceptor)` |
| `AliceHttpAdapter` | `samseer.httpClient()` (drop-in `http.Client`) |
| `AliceHttpClientAdapter` | `samseer.httpOverrides` (global HttpOverrides) |
| `alice.showInspector()` | `samseer.showInspector()` |
| Multiple packages (`alice_dio`, `alice_http`, ...) | One package — `samseer` |

Why switch?

- 🪄 **Single dependency** instead of 3-5 separate adapter packages.
- 🎨 **Modern Material 3 UI** with proper light/dark mode and Google Fonts typography.
- 📑 **Tabbed call detail** with built-in JSON syntax highlighting and one-tap cURL copy.
- 💬 **Floating bubble** as a more ergonomic alternative to system notifications.

---

## 🧪 Example

A complete example is in [`example/`](example/lib/main.dart). Run it:

```sh
cd example
flutter run
```

Tap any of the buttons to fire requests — they'll appear in the inspector live.

---

## 📦 What's included vs not (yet)

✅ **Included in 0.1.x**

- Dio + `http` + `HttpClient` interception
- Material 3 inspector UI (list, detail, stats)
- JSON viewer, cURL export, file export
- Shake detection, floating bubble
- In-memory storage with FIFO eviction

🛣️ **Roadmap**

- Persistent storage (Hive/Isar) so calls survive app restart
- Chopper, GraphQL, Cronet integrations
- Mock-and-replay (intercept and override responses for testing)
- Web + Desktop platform polish (currently mobile-first)
- Built-in Sentry/Crashlytics breadcrumb hooks

---

## 🤝 Contribute with us

Samseer is open and growing — and I'd love your help to make it the best HTTP inspector in the Flutter ecosystem. Whether you're squashing bugs, adding a new HTTP client integration, polishing the UI, or improving docs — your contribution is welcome.

**Ways to contribute**

- 🐛 **Bug reports & feature requests** — open an issue on [GitHub](https://github.com/samueljiwandono0310/samseer/issues)
- 🚀 **Code contributions** — fork, branch, send a PR. Make sure these still pass:
   ```sh
   flutter analyze
   flutter test
   ```
- 🎨 **Design feedback** — share screenshots, mockups, or UX ideas. The bar is "fancier than Alice" 😉
- 🌐 **HTTP client integrations** — Chopper, GraphQL, Cronet, etc. are on the roadmap
- 📣 **Spread the word** — star the repo, share with your team, write a blog post

**First-time contributors are very welcome.** Pick anything from the [roadmap](#-whats-included-vs-not-yet), open an issue first to discuss your approach, and let's build it together.

---

## ☕ Support this project

Samseer is built and maintained on personal time. If it saves you debugging hours, treat me to a coffee — every bit of support helps me keep building, polishing, and shipping new features.

<p align="center">
  <a href="https://github.com/sponsors/samueljiwandono0310">
    <img src="https://img.shields.io/badge/Sponsor%20on%20GitHub-💜-EA4AAA?style=for-the-badge&logo=github" alt="Sponsor on GitHub" />
  </a>
</p>

Sponsors get a special thank-you in the next release notes. 🙏

---

Made with 💙 by [Samuel Jiwandono](https://github.com/samueljiwandono0310) — and hopefully you next.
