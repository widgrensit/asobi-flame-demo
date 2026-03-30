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
- [asobi](https://github.com/widgrensit/asobi) backend running on `localhost:8084`
- [asobi_arena](https://github.com/widgrensit/asobi_arena) game mode registered

#### Linux

```bash
sudo apt install cmake ninja-build clang pkg-config libgtk-3-dev
```

#### macOS

```bash
# Xcode command line tools (if not already installed)
xcode-select --install
```

#### Windows

Install [Visual Studio](https://visualstudio.microsoft.com/) with the "Desktop development with C++" workload.

### Run

```bash
# Install dependencies
flutter pub get

# Run on Linux
flutter run -d linux

# Run on macOS
flutter run -d macos

# Run on Windows
flutter run -d windows

# Run on Chrome (web)
flutter run -d chrome
```

### Start the Backend

In a separate terminal, start the asobi_arena backend:

```bash
cd /path/to/asobi_arena
docker compose up -d    # Start PostgreSQL
rebar3 shell            # Start the backend on port 8084
```

### Run Two Clients

Matchmaking requires at least 2 players. Open two terminals:

```bash
# Terminal 1
flutter run -d linux

# Terminal 2
flutter run -d linux
```

Register with different usernames in each window, then click "FIND MATCH" in both.

## Architecture

Flutter screens handle UI (login, lobby, results). The arena is a Flame `FlameGame` that receives server state at 10Hz via WebSocket and renders players, projectiles, and HUD. Server-authoritative — the client only renders state received from the backend.

```
┌─────────────────────────────────────┐
│           Flutter App               │
│                                     │
│  LoginScreen ──► LobbyScreen ──►    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │     Flame FlameGame         │    │
│  │  Canvas rendering at 60fps  │    │
│  │  Server state sync at 10Hz  │    │
│  └─────────────────────────────┘    │
│                                     │
│  ◄── ResultsScreen ◄───────────    │
│                                     │
│  asobi-dart SDK (pure Dart)         │
│  ├── HTTP (auth, leaderboards)      │
│  └── WebSocket (matchmaker, game)   │
└─────────────────────────────────────┘
```

## Controls

| Key | Action |
|-----|--------|
| W/A/S/D | Move |
| Mouse | Aim |
| Left Click / Space | Shoot |
