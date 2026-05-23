<p align="center">
  <img src="assets/icon/app_icon.png" alt="GK HTTP Client" width="80" />
</p>

<h3 align="center">GK HTTP Client</h3>
<p align="center">Open source HTTP client. No Electron. No Node. No browser.</p>

<p align="center">
  <a href="https://github.com/GkIgor/gk_http_client/actions/workflows/release.yml">
    <img src="https://img.shields.io/github/actions/workflow/status/GkIgor/gk_http_client/release.yml?branch=main&label=build&style=flat-square" alt="Build Status" />
  </a>
  <a href="./test">
    <img src="https://img.shields.io/badge/tests-10%20suites-brightgreen?style=flat-square" alt="Tests" />
  </a>
  <a href="https://github.com/GkIgor/gk_http_client/releases">
    <img src="https://img.shields.io/badge/version-1.0.0-8b5cf6?style=flat-square" alt="Version" />
  </a>
  <a href="./LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-gray?style=flat-square" alt="License" />
  </a>
</p>

---

Most HTTP clients today ship a full Chromium instance to render their UI. GK HTTP Client does not. It is built with [Flutter](https://flutter.dev) and rendered by [Impeller](https://docs.flutter.dev/perf/impeller) — a native GPU renderer — which means the binary is under 50 MB and RAM usage sits around 360 MB at steady state, without a browser process in sight.

The goal is an HTTP client that is fast, auditable, and maintenance-friendly — free of the Node.js / Electron / Tauri dependency chain. Collections are stored on disk with [Hive](https://pub.dev/packages/hive). There is no telemetry, no tracking, and no required account.

![GK HTTP Client screenshot](docs/screenshot.png)

## Why not Electron

Electron apps embed Chromium (~150 MB compressed) and a Node.js runtime on top of your application code. This trades a familiar tech stack for significant overhead: slow startup, high memory usage, large installers, and an attack surface that grows with every Chromium release.

GK HTTP Client draws its own pixels via a compiled Dart binary and the Impeller renderer. The result is a sub-50 MB archive that starts in under a second and uses roughly the same RAM as a native desktop app.

## Installation

Download the latest binary for your platform from the [Releases](https://github.com/GkIgor/gk_http_client/releases) page.

| Platform | Archive |
|---|---|
| Linux (x64) | `gk_http_client-linux.tar.gz` |
| Windows (x64) | `gk_http_client-windows.zip` |

## Building from source

**Requirements:** Flutter `>=3.10.0` · Dart `^3.10.4`

On Linux, install the native build dependencies first:

```sh
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
```

Then:

```sh
git clone https://github.com/GkIgor/gk_http_client.git
cd gk_http_client
flutter pub get
flutter run -d linux       # or -d windows
```

Production build:

```sh
flutter build linux --release
# output: build/linux/x64/release/bundle/
```

## Features

**HTTP**
- All standard methods: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, `OPTIONS`
- Body types: JSON, XML, plain text, form-data, binary file upload
- Query parameters and headers with per-entry enable/disable toggles
- `{{variable}}` interpolation in URLs, headers, and body fields
- Syntax-highlighted response viewer — auto-detects JSON, XML, and HTML
- Status code, response time (ms), and body size (bytes) shown inline

**Collections**
- Multi-level nested folders with custom icons and colors
- Live filter across all requests in the sidebar
- Resizable sidebar panel
- Expand / collapse all folders with a single click

**Import & Export**
- Postman Collection v2.1 (JSON)
- Insomnia (JSON and YAML)
- Native format with per-file integrity signatures

**Workspace Runner**
- Run all requests in a folder or across the entire workspace sequentially
- Configurable inter-request delay
- Live dashboard: pass/fail count, cumulative time, per-request response inspector
- Stop / resume at any point

## Project structure

```
lib/
├── models/           # HttpRequest, RequestCollection, Workspace
├── providers/        # State management (Provider)
├── services/         # HTTP execution (Dio)
├── views/            # Sidebar, RunnerView, WorkspaceScreen
├── widgets/          # Reusable UI components
├── utils/converters/ # Postman, Insomnia, and native format converters
└── theme/            # Color tokens and typography
```

## Tests

```sh
flutter test
```

| Suite | Coverage |
|---|---|
| `http_service_test` | HTTP execution, timeouts, error handling |
| `request_provider_test` | Collection CRUD, search filter, state management |
| `runner_test` | Sequential execution, stop/resume, metrics accumulation |
| `import_export_test` | Postman, Insomnia, and native format round-trips |
| `workspace_provider_test` | Workspace creation, switching, and persistence |
| `highlight_test` | Response body auto-detection and syntax highlighting |
| `interpolated_text_controller_test` | `{{variable}}` highlight and cursor behavior |
| `code_input_formatter_test` | Auto-indent and bracket completion in the body editor |

## Roadmap

The items below are planned in rough priority order.

- [ ] **Cookie manager and redirect handling** — store, inspect, and replay cookies; follow or block redirects on demand
- [ ] **Request history** — browse past requests and their responses without re-sending
- [ ] **WebSocket, gRPC, and GraphQL support**
- [ ] **Pre- and post-request scripts** — run code before a request is sent or after a response arrives, for auth flows, chaining, and assertions
- [ ] **Git integration** — version your collections in a local repository and optionally sync to GitHub, which provides free cloud backup and full history without a proprietary backend
- [ ] **Automated API generation** — generate a working API scaffold from a collection
- [ ] **Optional self-hosted backend** — a Go API that teams can deploy internally to get shared workspaces, encrypted at-rest storage, and private cloud sync without sending data to third parties; the client binary can be built against a custom server URL

## Contributing

Pull requests are welcome. For significant changes, open an issue first.

Before submitting a PR:

```sh
flutter analyze   # no issues
flutter test      # all tests pass
```

## License

MIT — see [LICENSE](./LICENSE).
