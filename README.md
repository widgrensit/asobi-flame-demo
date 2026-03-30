# Asobi Arena Demo (Flame)

Top-down arena shooter demo for the [Asobi](https://github.com/widgrensit/asobi) game backend, built with [Flame](https://flame-engine.org/) (Flutter 2D game engine) and the [asobi-dart](https://github.com/widgrensit/asobi-dart) SDK.

## Game Flow

1. **Login** — Register or login with username/password (Flutter UI)
2. **Lobby** — Connect via WebSocket, find match through matchmaker (Flutter UI)
3. **Arena** — WASD movement, mouse aim + space to shoot, 90-second rounds (Flame game)
4. **Results** — Match standings, leaderboard submission, play again or quit (Flutter UI)

## Setup

### Prerequisites

- [Flutter](https://flutter.dev/) 3.x+
- Linux desktop build tools: `sudo apt install cmake ninja-build clang pkg-config libgtk-3-dev`
- [asobi](https://github.com/widgrensit/asobi) backend running on `localhost:8084`
- [asobi_arena](https://github.com/widgrensit/asobi_arena) game mode registered

### Run

```bash
flutter pub get
flutter run -d linux
```

## Architecture

Flutter screens handle UI (login, lobby, results). The arena is a Flame `FlameGame` that receives server state at 10Hz via WebSocket and renders players, projectiles, and HUD. Server-authoritative — the client only renders state received from the backend.

## Controls

| Key | Action |
|-----|--------|
| W/A/S/D | Move |
| Mouse | Aim |
| Space | Shoot |
