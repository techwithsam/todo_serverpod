# Todo (Serverpod + Flutter) ~ { Samuel A. } FlutterByte's Conference '25

[![Serverpod](https://img.shields.io/badge/Serverpod-Backend-blue)](https://docs.serverpod.dev) [![Flutter](https://img.shields.io/badge/Flutter-Client-02569B)](https://flutter.dev) [![License](https://img.shields.io/badge/License-MIT-lightgrey)]

A minimal, full‑stack Todo app demonstrating Serverpod (Dart) backend + Flutter client with a generated client package.

<!-- Visual / Screenshots -->
<p align="center">
  <a href = "https://docs.google.com/presentation/d/155jfYUI2EHk207CNKTTjIHgO18svoSnG-6dgxdfzUTg/edit?usp=sharing"> <img src="./screenshots/presentation.png" alt="App screenshot" width="1000" /></a>
</p>

---

## Contents

- [Features](#features)  
- [Project layout](#project-layout)  
- [Quick start (macOS)](#quick-start-macos)  
- [Development tips](#development-tips)  
- [Deployment](#deployment)  
- [Contributing](#contributing)  
- [License](#license)

---

## Features

- REST + WebSocket API with Serverpod
- Flutter client (mobile & web)
- PostgreSQL + Redis support
- Dockerfile and guides for Railway / Heroku
- Migrations and generated protocol client

---

## Project layout

- todo_server/ — Serverpod server
  - bin/main.dart — server entrypoint
  - Dockerfile — for containerized deploys
  - migrations/ — DB migrations
  - lib/src/generated/ — generated protocol & endpoints
- todo_flutter/ — Flutter client
  - lib/main.dart — app entrypoint
- todo_client/ — generated client package

---

## Quick start (macOS)

Prereqs: Docker, Flutter, Dart SDK (for server).

1. Clone:

   ```bash
   git clone https://github.com/techwithsam/todo_serverpod
   cd todo
   ```

2. Start local DB & Redis (example using docker-compose):

   ```bash
   cd todo_server && docker compose up -d
   ```

3. Run the server:

   ```bash
   # from todo_server/
   dart pub get
   dart run bin/main.dart
   # (or run with migrations)
   dart run bin/main.dart --apply-migrations
   ```

4. Run the Flutter app:

   ```bash
   cd ../todo_flutter
   flutter pub get
   flutter run
   ```

5. Access localhp:

   ```bash
   curl http://localhost:8080/
   ```

<p align="center">
  <img src="./screenshots/presentation-2.png" alt="App screenshot" width="1000" />
</p>

---

## Development tips

- Regenerate client after changing server models/endpoints:

  ```bash
  # from todo_server/
  serverpod generate
  ```

- Set SERVER_URL in Flutter (web / build):

  ```bash
  flutter build web --dart-define=SERVER_URL=https://your-app.example
  ```

---

## Deployment

See DEPLOYMENT.md for step‑by‑step Railway and Heroku instructions, Dockerfile, env vars, and common fixes.

Quick notes:

- Use production config: `config/production.yaml`
- Apply migrations on first deploy
- Ensure port 8080 exposed and publicHost set to your domain

---

## Contributing

- Fork, branch, and open PRs
- Add tests under respective `test/` directories
- Keep UI screenshots in `todo_flutter/assets/screenshots/`

---

<p align="center">
  <a href="https://www.youtube.com/playlist?list=PLMfrNHAjWCoBLkkknD1iBOD-rUsejTWlj"> <img src="./screenshots/presentation-1.png" alt="App screenshot" width="1000" /></a>
</p>

## License

MIT — see LICENSE file.

<!-- end -->
