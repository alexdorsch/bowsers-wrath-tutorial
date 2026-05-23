# Infinite Parkour

A procedurally generated parkour climber for Roblox. Tower-of-Hell aesthetic with a daily seed (everyone climbs the same tower today), powered by Rojo for file-based development.

This README walks you from a **completely fresh machine** to a playable tower. Allow ~30 minutes for first-time setup; subsequent dev sessions are `rojo serve` + Studio Play (~10 seconds).

---

## Phase 1 scope (this commit)

- ✅ Procedural tower with 3 obstacle types (Jump, WideJump, Beam)
- ✅ Daily seed — every player joining today gets the same tower
- ✅ Tower streams ahead of climbers and culls behind
- ✅ Height-counter HUD with pop animation
- ✅ Falling below the void respawns you
- ⏳ Coins, persistence, shop — Phase 2
- ⏳ Skip Stage, Double Coins, daily leaderboard — Phase 3

---

## First-time setup (you only do this once)

### 1. Install Roblox Studio

1. Sign up for a Roblox account at <https://www.roblox.com/> if you don't have one.
2. Download Studio: <https://create.roblox.com/> → "Start Creating" → installer.
3. Sign in.

### 2. Install Aftman (the Roblox toolchain manager)

Aftman fetches versioned dev tools (`rojo`, `selene`, `stylua`) per-project. macOS install:

```sh
brew install aftman
# or, if you don't use Homebrew:
curl -L https://github.com/LPGhatguy/aftman/releases/latest/download/aftman-macos.zip -o /tmp/aftman.zip \
  && unzip -o /tmp/aftman.zip -d ~/.aftman/bin \
  && chmod +x ~/.aftman/bin/aftman \
  && echo 'export PATH="$HOME/.aftman/bin:$PATH"' >> ~/.zshrc \
  && source ~/.zshrc
```

Verify:

```sh
aftman --version
```

### 3. Install the project's pinned tools

From this directory:

```sh
cd ~/dev/roblox/infinite-parkour
aftman install
```

That installs `rojo`, `selene`, `stylua` at the exact versions in `aftman.toml`. Verify:

```sh
rojo --version    # expect 7.4.x
selene --version  # expect 0.27.x
stylua --version  # expect 0.20.x
```

If `rojo: command not found`, your `~/.aftman/bin` isn't on PATH. Re-run the `echo 'export PATH=...'` step from §2.

### 4. Install the Rojo Roblox Studio plugin

1. Open Studio.
2. **Toolbox** → **Marketplace** → search "Rojo".
3. Click the plugin by `LPGhatguy / rojo-rbx` (icon is a red diamond).
4. **Get** → it auto-installs.

### 5. Optional but recommended: VS Code Luau tooling

If you're editing files outside Studio (which you should be — that's the whole point of Rojo):

1. Install [VS Code](https://code.visualstudio.com/) if you don't have it.
2. Install these extensions from the VS Code marketplace:
   - **Luau Language Server** by JohnnyMorganz (autocomplete, type checking)
   - **Rojo** by Rojo (project tree + sync controls)
   - **Selene** by Kampfkarren (linter)
   - **StyLua** by JohnnyMorganz (formatter)

---

## Run the game (every dev session)

### Option A — Live sync (the good workflow)

In one terminal:

```sh
cd ~/dev/roblox/infinite-parkour
rojo serve
```

You should see:

```
Rojo server listening:
  Address: localhost
  Port:    34872
```

Now in Studio:

1. Open Studio. **File → New** to create a fresh baseplate place.
2. In the toolbar's **Plugins** tab you'll see a Rojo widget. Click it.
3. In the Rojo widget click **Connect**. The status should go green.
4. Click **▶ Play** (or press F5) to start a local play session.

Any change you save to a file on disk now hot-reloads into Studio in <1 second.

### Option B — Build once (quick smoke test)

If you just want to see it run without setting up live sync:

```sh
rojo build -o build/place.rbxlx default.project.json
```

Then **File → Open** the generated `build/place.rbxlx` in Studio and press Play.

You won't get live reload this way — edits to source files require a rebuild + reopen.

---

## What you should see

When you press Play:

1. You spawn on a white pad floating in a dark navy void.
2. A vertical "tower" of bright neon platforms (hot pink, cyan, lime, yellow, magenta, orange) extends upward.
3. Top-center HUD shows your current height climbing toward your personal best.
4. If you fall below the spawn pad far enough, the void kills you and you respawn at zero.
5. Every day the tower layout changes (deterministic by UTC date).

Console output (View → Output in Studio) should print:
```
[Server] Booting Infinite Parkour…
[TowerService] Started. Daily seed = 20231...
[PlayerService] Started.
[Server] Boot complete.
[Client] Booting HUD…
[Client] Boot complete.
```

---

## Project layout

```
infinite-parkour/
├── default.project.json     # Rojo: maps files → Roblox services + sets baseplate, lighting, sky
├── aftman.toml              # Pinned versions of rojo/selene/stylua
├── selene.toml              # Linter config
├── stylua.toml              # Formatter config
└── src/
    ├── shared/              # → ReplicatedStorage.Shared (visible to server + client)
    │   ├── Constants.luau       # Tuning numbers, neon palette, remote names, asset IDs
    │   ├── Types.luau           # Luau type definitions
    │   ├── Remotes.luau         # Lazy registry of all RemoteEvents/Functions
    │   └── ObstacleConfig.luau  # Obstacle metadata & spawn weights
    ├── server/              # → ServerScriptService.Server
    │   ├── init.server.luau         # Boot: starts TowerService then PlayerService
    │   ├── TowerService.luau        # Spawn pad + streamed tower lifecycle
    │   ├── PlayerService.luau       # Height tracking, run state, death/respawn
    │   └── ObstacleGenerator/
    │       ├── init.luau            # Public API: generate(seed, floorIndex, prevXZ)
    │       ├── ObstacleTypes.luau   # The 3 Phase-1 builders
    │       └── DifficultyCurve.luau # Floor → difficulty + weighted kind picker
    └── client/              # → StarterPlayer.StarterPlayerScripts.Client
        ├── init.client.luau         # Boot: mounts HUD
        └── UI/
            └── HUD.luau             # Height + personal-best label, animated
```

### Where to tweak common things

| Want to change | File | What |
|---|---|---|
| Obstacle spacing | `src/shared/Constants.luau` | `FLOOR_SPACING_STUDS` |
| Difficulty ramp | `src/shared/Constants.luau` | `SOFT_MAX_FLOOR` |
| Neon palette | `src/shared/Constants.luau` | `NEON_PALETTE` |
| Streaming distance | `src/shared/Constants.luau` | `STREAM_AHEAD_DISTANCE`, `STREAM_BEHIND_DISTANCE` |
| Add a new obstacle | `src/server/ObstacleGenerator/ObstacleTypes.luau` + register in `ObstacleConfig.luau` |
| Visual atmosphere | `default.project.json` → `Lighting` properties |

---

## Lint + format

```sh
selene src/             # Lints all Luau files
stylua src/             # Formats them in place
stylua --check src/     # Check-only (CI-friendly)
```

These run against the configs in `selene.toml` / `stylua.toml`.

---

## Common gotchas

- **"Rojo plugin says 'connection refused'"** — `rojo serve` is not running. Start it in a terminal first.
- **"Workspace.Baseplate already exists"** — Rojo found a hand-placed Baseplate in your place. Delete it from the Explorer; Rojo will spawn its own from `default.project.json`.
- **HUD doesn't appear** — check the Output window for client errors. Usually missing remote folder.
- **Player falls straight through the spawn pad** — Studio sometimes preserves an old Baseplate that overlaps. Delete `Workspace.Baseplate` and reconnect Rojo.
- **Daily seed never changes** — that's correct; the tower is meant to refresh once per UTC day. To force a refresh during testing, change `computeDailySeed()` in `TowerService.luau` to use a manual seed value.

---

## What's next

When you're ready for Phase 2 (coin economy + DataStore persistence + cosmetic shop + 3 more obstacle types), tell me and I'll layer it on.
