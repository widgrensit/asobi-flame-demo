# Asobi Arena Demo (Flame)

Top-down arena shooter demo for the [Asobi](https://github.com/widgrensit/asobi) game backend, built with [Flame](https://flame-engine.org/) (Flutter 2D engine) and the [flame_asobi](https://github.com/widgrensit/flame_asobi) bridge package.

## Game Flow

1. **Login** — Register or login with username/password (Flutter UI)
2. **Lobby** — Connect via WebSocket, find match through matchmaker (Flutter UI)
3. **Arena** — WASD movement, mouse aim + click/space to shoot, 90-second rounds (Flame game)
4. **Results** — Match standings, leaderboard submission, play again or quit (Flutter UI)

## Setup

### Prerequisites

- [Flutter](https://flutter.dev/) 3.x+
- An [`asobi_arena_lua`](https://github.com/widgrensit/asobi_arena_lua) backend running locally:

   ```bash
   git clone https://github.com/widgrensit/asobi_arena_lua
   cd asobi_arena_lua && docker compose up -d
   ```

   Server listens on `http://localhost:8085`. (This demo plays the *full* arena game — boons, modifiers, voting, bots — so it needs the arena Lua, not the minimal [`sdk_demo_backend`](https://github.com/widgrensit/sdk_demo_backend).)

#### Linux

```bash
sudo apt install cmake ninja-build clang pkg-config libgtk-3-dev
```

#### macOS

```bash
xcode-select --install
```

#### Windows

Install [Visual Studio](https://visualstudio.microsoft.com/) with the "Desktop development with C++" workload.

### Run

```bash
flutter pub get

flutter run -d linux     # or -d macos / -d windows / -d chrome
```

### Two clients

Matchmaking needs 2 players. Run the app twice, register two different usernames, click **FIND MATCH** in both:

```bash
# Terminal 1
flutter run -d linux

# Terminal 2
flutter run -d linux
```

## Architecture

Flutter screens handle UI (login, lobby, results). The arena is a Flame `FlameGame` using the [flame_asobi](https://github.com/widgrensit/flame_asobi) mixins (`HasAsobi`, `HasAsobiMatchmaker`, `HasAsobiInput`, `AsobiNetworkSync`). Server-authoritative — the client only renders state received from the backend at 10 Hz.

```
┌─────────────────────────────────────┐
│           Flutter App               │
│                                     │
│  LoginScreen ──► LobbyScreen ──►    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │     Flame FlameGame         │    │
│  │  Canvas at 60 fps           │    │
│  │  Server state at 10 Hz      │    │
│  └─────────────────────────────┘    │
│                                     │
│  ◄── ResultsScreen ◄───────────     │
│                                     │
│  flame_asobi (mixins) → asobi-dart  │
└─────────────────────────────────────┘
```

## Controls

| Key | Action |
|-----|--------|
| W/A/S/D | Move |
| Mouse | Aim |
| Left Click / Space | Shoot |
